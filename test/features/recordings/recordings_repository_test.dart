import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/backup/data/data_sources/backup_archive_data_source.dart';
import 'package:hitwave.cover/features/recordings/data/data_sources/hive_recording_service.dart';
import 'package:hitwave.cover/features/recordings/data/data_sources/mp3_encoder_service.dart';
import 'package:hitwave.cover/features/recordings/data/data_sources/recorder_data_source.dart';
import 'package:hitwave.cover/features/recordings/data/models/recording_model.dart';
import 'package:hitwave.cover/features/recordings/data/repositories/recordings_repository_impl.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/imported_recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/microphone.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recorder_state.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_id_change.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/enhance_preset.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/enhance_progress.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/enhance_report.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/recording_analysis.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/repositories/vocal_enhance_repository.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/vocal_enhance_failure.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/enhance_failure.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recordings_failure.dart';

/// A microphone that writes a few bytes when stopped.
final class FakeRecorder implements RecorderDataSource {
  bool allowed = true;
  String? path;
  String? microphoneId;
  double inputLevel = 0.5;

  @override
  Future<List<Microphone>> microphones() async => const <Microphone>[Microphone(id: 'usb', label: 'USB mic')];

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<void> start(String path, {String? microphoneId}) async {
    this.path = path;
    this.microphoneId = microphoneId;
  }

  @override
  Future<String?> stop() async {
    final String? recorded = path;
    if (recorded != null) await File(recorded).writeAsBytes(<int>[1, 2, 3]);
    return recorded;
  }

  @override
  Future<double> level() async => inputLevel;

  @override
  Future<void> dispose() async {}
}

const RecordingAnalysis analysis = RecordingAnalysis(
  durationSeconds: 12.5,
  sampleRate: 48000,
  channels: 1,
  integratedLufs: -14,
  truePeakDb: -1,
  clippedPercent: 0,
  noiseFloorDb: -60,
  signalToNoiseDb: 40,
  isClipped: false,
  isTooQuiet: false,
  isNoisy: false,
);

/// An audio engine that copies the take, or fails while [failing].
final class FakeEngine implements VocalEnhanceRepository {
  bool failing = false;
  final List<bool> trims = <bool>[];

  @override
  ValueListenable<EnhanceProgress?> watchProgress() => throw UnimplementedError();

  @override
  Future<Result<RecordingAnalysis, VocalEnhanceFailure>> analyzeRecording(String path) async =>
      const Result.success(analysis);

  @override
  Future<Result<EnhanceReport, VocalEnhanceFailure>> enhanceRecording({
    required String inputPath,
    required String outputPath,
    required EnhancePreset preset,
    required double? roomToneSeconds,
    required bool trimSilence,
    required Map<String, double> settings,
  }) async {
    trims.add(trimSilence);
    if (failing) return const Result.failure(VocalEnhanceFailure.enhance);
    await File(inputPath).copy(outputPath);
    return Result.success(
      EnhanceReport(
        inputPath: inputPath,
        outputPath: outputPath,
        settings: const <String, double>{},
        before: analysis,
        after: analysis,
        secondsSpent: 0.1,
        keptFromSeconds: 1.5,
        keptToSeconds: 11,
      ),
    );
  }
}

/// An MP3 encoder that writes a marker file.
final class FakeMp3 extends Mp3EncoderService {
  final List<String> made = <String>[];

  @override
  Future<void> encode({required String wavPath, required String mp3Path}) async {
    made.add(mp3Path);
    await File(mp3Path).writeAsBytes(<int>[0xFF, 0xFB]);
  }
}

/// Only the song id changes of the song repository.
final class FakeSongs implements SongRepository {
  final StreamController<SongIdChange> changes = StreamController<SongIdChange>.broadcast();

  @override
  Stream<SongIdChange> watchSongIdChanges() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Waits until [done] holds (the background queue got there), at most 5 s.
Future<void> waitFor(bool Function() done) async {
  final Stopwatch waited = Stopwatch()..start();
  while (!done() && waited.elapsed < const Duration(seconds: 5)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Lets Hive writes and the background enhancement finish.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late Directory directory;
  late HiveRecordingService store;
  late FakeRecorder recorder;
  late FakeEngine engine;
  late FakeMp3 mp3;
  late FakeSongs songs;
  late RecordingsRepositoryImpl repository;

  Future<RecordingsRepositoryImpl> open() => RecordingsRepositoryImpl(
    store: store,
    recorder: recorder,
    engine: engine,
    mp3: mp3,
    songs: songs,
    logger: Logger(level: Level.off),
  ).init();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hitwave_recordings_test');
    Hive.init(directory.path);
    store = await HiveRecordingService(storage: LocalStorageService(), documentsFolder: () async => directory).init();
    recorder = FakeRecorder();
    engine = FakeEngine();
    mp3 = FakeMp3();
    songs = FakeSongs();
    repository = await open();
  });

  tearDown(() async {
    await settle(); // the MP3s made in the background
    await settle();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<Recording> record(String songId, {bool trimSilence = true}) async {
    expect((await repository.startRecording(songId)).isSuccess, isTrue);
    final Result<Recording, RecordingsFailure> stopped = await repository.stopRecording(trimSilence: trimSilence);
    await settle();
    return (stopped as SuccessResult<Recording, RecordingsFailure>).value;
  }

  test('a take is kept on the device and enhanced automatically', () async {
    expect((await repository.startRecording('song-1')).isSuccess, isTrue);
    expect(repository.watchRecorder().value, isA<RecordingRecorderState>());
    expect((await repository.startRecording('song-1')).isFailure, isTrue);

    final Result<Recording, RecordingsFailure> stopped = await repository.stopRecording(trimSilence: true);
    expect(repository.watchRecorder().value, isA<IdleRecorderState>());
    expect((stopped as SuccessResult<Recording, RecordingsFailure>).value.status, RecordingStatus.enhancing);
    await settle();

    final Recording recording = repository.watchRecordings().value.single;
    expect(recording.songId, 'song-1');
    expect(recording.status, RecordingStatus.enhanced);
    expect(recording.durationSeconds, 12.5);
    expect(recording.keptFromSeconds, 1.5);
    expect(recording.keptToSeconds, 11);
    expect(File(recording.rawPath).existsSync(), isTrue);
    expect(File(recording.enhancedPath!).existsSync(), isTrue);
    expect(engine.trims, <bool>[true]);
    // The MP3s for sharing are made right away, beside the WAVs.
    await waitFor(() => mp3.made.length == 2);
    expect(File(Mp3EncoderService.mp3PathOf(recording.enhancedPath!)).existsSync(), isTrue);
    expect(File(Mp3EncoderService.mp3PathOf(recording.rawPath)).existsSync(), isTrue);
    expect(mp3.made.length, 2);

    // A restart does not make them again.
    repository = await open();
    await settle();
    expect(mp3.made.length, 2);
  });

  test('a take is recorded from the chosen microphone; one without any sound is marked', () async {
    expect(
      (await repository.listMicrophones() as SuccessResult<List<Microphone>, RecordingsFailure>).value.single.label,
      'USB mic',
    );

    expect((await repository.startRecording('song-1', microphoneId: 'usb')).isSuccess, isTrue);
    expect(recorder.microphoneId, 'usb');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final Recording heard =
        (await repository.stopRecording(trimSilence: true) as SuccessResult<Recording, RecordingsFailure>).value;
    expect(heard.isSilent, isFalse);

    recorder.inputLevel = 0;
    await repository.startRecording('song-1');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final Recording silent =
        (await repository.stopRecording(trimSilence: true) as SuccessResult<Recording, RecordingsFailure>).value;
    expect(silent.isSilent, isTrue);
    await settle();
    expect(repository.watchRecordings().value.firstWhere((Recording r) => r.id == silent.id).isSilent, isTrue);
  });

  test('a failed enhancement can be run again', () async {
    engine.failing = true;
    final Recording recording = await record('song-1', trimSilence: false);
    expect(repository.watchRecordings().value.single.status, RecordingStatus.enhanceFailed);
    expect(repository.watchRecordings().value.single.enhanceFailure, EnhanceFailure.failed);

    engine.failing = false;
    expect((await repository.enhanceAgain(recordingId: recording.id, trimSilence: true)).isSuccess, isTrue);
    await settle();

    expect(repository.watchRecordings().value.single.status, RecordingStatus.enhanced);
    expect(engine.trims, <bool>[false, true]);
  });

  test('without the microphone permission nothing is recorded', () async {
    recorder.allowed = false;

    expect((await repository.startRecording('song-1')).isFailure, isTrue);
    expect(repository.watchRecorder().value, isA<IdleRecorderState>());
  });

  test('recordings follow a song moved into the account and go with a deleted one', () async {
    final Recording moved = await record('local-1');
    final Recording deleted = await record('local-2');

    songs.changes.add(const SongMovedIdChange(fromId: 'local-1', toId: 'account-1'));
    songs.changes.add(const SongDeletedIdChange('local-2'));
    await settle();

    expect(repository.watchRecordings().value.single.id, moved.id);
    expect(repository.watchRecordings().value.single.songId, 'account-1');
    expect(File(deleted.rawPath).existsSync(), isFalse);
  });

  test('the library survives a restart; an interrupted enhancement becomes a failure', () async {
    final Recording recording = await record('song-1');
    await store.put(
      RecordingModel.fromMap(<String, dynamic>{
        ...RecordingModel.fromEntity(recording, trimSilence: true).toMap(),
        'status': RecordingStatus.enhancing.name,
      }),
    );

    repository = await open();

    expect(repository.watchRecordings().value.single.status, RecordingStatus.enhanceFailed);
  });

  test('imported recordings are moved into the library', () async {
    final File raw = File('${directory.path}/in_raw.wav')..writeAsBytesSync(<int>[1]);
    final File enhanced = File('${directory.path}/in_enhanced.wav')..writeAsBytesSync(<int>[2]);

    final Result<void, RecordingsFailure> result = await repository.importRecordings(<ImportedRecording>[
      ImportedRecording(
        songId: 'song-9',
        recordedAt: DateTime(2026, 11, 12),
        durationSeconds: 30,
        rawFilePath: raw.path,
        enhancedFilePath: enhanced.path,
        keptFromSeconds: 2,
        keptToSeconds: 28,
      ),
    ]);

    expect(result.isSuccess, isTrue);
    final Recording recording = repository.watchRecordings().value.single;
    expect(recording.status, RecordingStatus.enhanced);
    expect(File(recording.enhancedPath!).readAsBytesSync(), <int>[2]);
    expect(raw.existsSync(), isFalse);
  });

  test('a ZIP backup keeps its JSON and the recording files', () async {
    final BackupArchiveDataSource archive = BackupArchiveDataSource();
    final File take = File('${directory.path}/take.wav')
      ..writeAsBytesSync(List<int>.generate(4096, (int i) => i % 256));
    final String zip = '${directory.path}/backup.zip';

    await archive.writeZip(path: zip, json: '{"songs":[]}', files: <String, String>{'recordings/a_raw.wav': take.path});
    final OpenedBackup opened = await archive.openFile(zip);

    expect(opened.json, '{"songs":[]}');
    expect(File('${opened.extractedFolder}/recordings/a_raw.wav').readAsBytesSync(), take.readAsBytesSync());
    await archive.deleteFolder(opened.extractedFolder!);
  });
}
