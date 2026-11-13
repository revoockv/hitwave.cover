import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../song/domain/entities/song_id_change.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../../vocal_enhance/domain/entities/enhance_preset.dart';
import '../../../vocal_enhance/domain/entities/enhance_report.dart';
import '../../../vocal_enhance/domain/repositories/vocal_enhance_repository.dart';
import '../../domain/entities/imported_recording.dart';
import '../../domain/entities/microphone.dart';
import '../../domain/entities/recorder_state.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../../domain/repositories/recordings_repository.dart';
import '../data_sources/hive_recording_service.dart';
import '../data_sources/mp3_encoder_service.dart';
import '../data_sources/recorder_data_source.dart';
import '../models/recording_model.dart';
import '../../../vocal_enhance/domain/entities/vocal_enhance_failure.dart';
import '../../domain/entities/enhance_failure.dart';
import '../../domain/entities/recordings_failure.dart';

/// [RecordingsRepository] on the microphone, the Hive library and the audio engine.
///
/// Enhancements run one after another in the background; a take whose enhancement was cut off
/// by closing the app is marked as failed at the next start, so the user can enhance it again.
final class RecordingsRepositoryImpl implements RecordingsRepository, DisposableResource {
  static const Duration _tick = Duration(milliseconds: 200);
  static const int _millisecondsPerSecond = 1000;

  /// Highest input level that still counts as no sound at all.
  static const double _silentLevel = 0.01;

  static const String _startLog = 'StartRecording: ';
  static const String _stopLog = 'StopRecording: ';
  static const String _enhanceLog = 'EnhanceRecording: ';
  static const String _mp3Log = 'MakeMp3: ';
  static const String _deleteLog = 'DeleteRecording: ';
  static const String _importLog = 'ImportRecordings: ';
  static const String _songIdLog = 'SongIdChange: ';
  static const String _successLog = 'success — ';
  static const String _failureLog = 'failure — ';
  static const String _arrowLog = ' → ';
  static const String _dashLog = ' — ';
  static const String _commaLog = ', ';
  static const String _secondsLog = 's';

  static const Uuid _uuid = Uuid();

  final HiveRecordingService _store;
  final RecorderDataSource _recorder;
  final VocalEnhanceRepository _engine;
  final Mp3EncoderService _mp3;
  final SongRepository _songs;
  final Logger _logger;

  final ValueNotifier<List<Recording>> _recordings = ValueNotifier<List<Recording>>(const <Recording>[]);
  final ValueNotifier<RecorderState> _recorderState = ValueNotifier<RecorderState>(RecorderState.idle);
  final Map<String, RecordingModel> _models = <String, RecordingModel>{};

  StreamSubscription<SongIdChange>? _songIdChanges;
  final StreamController<String> _deletions = StreamController<String>.broadcast();
  Timer? _ticker;
  Stopwatch? _stopwatch;
  String? _activeId;
  DateTime? _activeStartedAt;
  double _peakLevel = 0;
  Future<void> _enhanceQueue = Future<void>.value();

  /// Creates a [RecordingsRepositoryImpl].
  RecordingsRepositoryImpl({
    required this._store,
    required this._recorder,
    required this._engine,
    required this._mp3,
    required this._songs,
    required this._logger,
  });

  /// Loads the library and follows the song ids; returns this for `registerSingletonAsync`.
  Future<RecordingsRepositoryImpl> init() async {
    for (final RecordingModel model in _store.readAll()) {
      _models[model.id] = model.status == RecordingStatus.enhancing
          ? model.copyWith(status: RecordingStatus.enhanceFailed, enhanceFailure: EnhanceFailure.interrupted.name)
          : model;
    }
    await Future.wait(_models.values.where(_wasInterrupted).map(_store.put));
    _publish();
    _songIdChanges = _songs.watchSongIdChanges().listen(_onSongIdChanged);
    for (final RecordingModel model in _models.values) {
      _enqueueMp3(model.id);
    }
    return this;
  }

  /// Stops the recorder and the subscriptions and releases the state.
  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    await _songIdChanges?.cancel();
    await _recorder.dispose();
    await _deletions.close();
    _recordings.dispose();
    _recorderState.dispose();
  }

  @override
  ValueListenable<List<Recording>> watchRecordings() => _recordings;

  @override
  ValueListenable<RecorderState> watchRecorder() => _recorderState;

  @override
  Future<Result<List<Microphone>, RecordingsFailure>> listMicrophones() async {
    try {
      return Result.success(await _recorder.microphones());
    } on Exception catch (e) {
      _logger.e('$_startLog$_failureLog$e');
      return const Result.failure(RecordingsFailure.listMicrophones);
    }
  }

  @override
  Future<Result<void, RecordingsFailure>> startRecording(String songId, {String? microphoneId}) async {
    if (_activeId != null) return const Result.failure(RecordingsFailure.busy);
    try {
      if (!await _recorder.hasPermission()) {
        _logger.w('$_startLog$_failureLog${RecordingsFailure.microphonePermission.name}');
        return const Result.failure(RecordingsFailure.microphonePermission);
      }
      final String id = _uuid.v4();
      await _recorder.start(_store.rawPathOf(id), microphoneId: microphoneId);
      _peakLevel = 0;
      _activeId = id;
      _activeStartedAt = DateTime.now();
      _stopwatch = Stopwatch()..start();
      _recorderState.value = RecordingRecorderState(songId: songId, elapsed: Duration.zero, level: 0);
      _ticker = Timer.periodic(_tick, (_) => unawaited(_onTick(songId)));
      _logger.i('$_startLog$_successLog$songId');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_startLog$_failureLog$e');
      return const Result.failure(RecordingsFailure.start);
    }
  }

  @override
  Future<Result<Recording, RecordingsFailure>> stopRecording({required bool trimSilence}) async {
    final String? id = _activeId;
    final RecorderState state = _recorderState.value;
    if (id == null || state is! RecordingRecorderState) return const Result.failure(RecordingsFailure.notRecording);
    _ticker?.cancel();
    _ticker = null;
    final double seconds = (_stopwatch?.elapsedMilliseconds ?? 0) / _millisecondsPerSecond;
    _activeId = null;
    _recorderState.value = RecorderState.idle;
    try {
      final String? path = await _recorder.stop();
      if (path == null) return const Result.failure(RecordingsFailure.save);
      final RecordingModel model = RecordingModel(
        id: id,
        songId: state.songId,
        recordedAt: _activeStartedAt ?? DateTime.now(),
        durationSeconds: seconds,
        rawFile: _store.rawFileOf(id),
        enhancedFile: null,
        keptFromSeconds: 0,
        keptToSeconds: null,
        status: RecordingStatus.enhancing,
        enhanceFailure: null,
        trimSilence: trimSilence,
        isSilent: _peakLevel <= _silentLevel,
      );
      await _save(model);
      _enqueueEnhancement(id);
      _logger.i('$_stopLog$_successLog$id$_commaLog$seconds$_secondsLog');
      return Result.success(_entity(model));
    } on Exception catch (e) {
      _logger.e('$_stopLog$_failureLog$e');
      return const Result.failure(RecordingsFailure.save);
    }
  }

  @override
  Future<Result<void, RecordingsFailure>> enhanceAgain({required String recordingId, required bool trimSilence}) async {
    final RecordingModel? model = _models[recordingId];
    if (model == null) return const Result.failure(RecordingsFailure.notFound);
    await _save(model.copyWith(status: RecordingStatus.enhancing, clearEnhanceFailure: true, trimSilence: trimSilence));
    _enqueueEnhancement(recordingId);
    return Result.ok;
  }

  @override
  Stream<String> watchRecordingDeletions() => _deletions.stream;

  @override
  Future<Result<void, RecordingsFailure>> deleteRecording(String recordingId) async {
    try {
      await _store.delete(recordingId);
      _models.remove(recordingId);
      _publish();
      _deletions.add(recordingId);
      _logger.i('$_deleteLog$_successLog$recordingId');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_deleteLog$_failureLog$e');
      return const Result.failure(RecordingsFailure.delete);
    }
  }

  @override
  Future<Result<void, RecordingsFailure>> importRecordings(List<ImportedRecording> recordings) async {
    try {
      for (final ImportedRecording imported in recordings) {
        if (_models.containsKey(imported.id)) continue;
        final String id = imported.id ?? _uuid.v4();
        await _store.moveFile(from: imported.rawFilePath, to: _store.rawPathOf(id));
        final String? enhancedFile = imported.enhancedFilePath;
        if (enhancedFile != null) {
          await _store.moveFile(from: enhancedFile, to: _store.enhancedPathOf(id));
        }
        final Recording recording = Recording(
          id: id,
          songId: imported.songId,
          recordedAt: imported.recordedAt,
          durationSeconds: imported.durationSeconds,
          rawPath: _store.rawPathOf(id),
          enhancedPath: enhancedFile == null ? null : _store.enhancedPathOf(id),
          keptFromSeconds: imported.keptFromSeconds,
          keptToSeconds: imported.keptToSeconds,
          status: enhancedFile == null ? RecordingStatus.enhancing : RecordingStatus.enhanced,
          enhanceFailure: null,
        );
        await _save(RecordingModel.fromEntity(recording, trimSilence: false));
        if (enhancedFile == null) {
          _enqueueEnhancement(id);
        } else {
          _enqueueMp3(id);
        }
      }
      _logger.i('$_importLog$_successLog${recordings.length}');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_importLog$_failureLog$e');
      return const Result.failure(RecordingsFailure.importRecordings);
    }
  }

  Future<void> _onTick(String songId) async {
    if (_activeId == null) return;
    double level = 0;
    try {
      level = await _recorder.level();
    } on Exception {
      level = 0;
    }
    if (_activeId == null) return;
    if (level > _peakLevel) _peakLevel = level;
    _recorderState.value = RecordingRecorderState(
      songId: songId,
      elapsed: _stopwatch?.elapsed ?? Duration.zero,
      level: level,
    );
  }

  void _enqueueEnhancement(String id) {
    _enhanceQueue = _enhanceQueue.then((_) => _enhance(id));
  }

  /// Makes the MP3s of [id] for sharing, after the enhancements waiting before it.
  void _enqueueMp3(String id, {bool replaceEnhanced = false}) {
    _enhanceQueue = _enhanceQueue.then((_) => _makeMp3s(id, replaceEnhanced: replaceEnhanced));
  }

  /// Makes the MP3 of the enhanced take (again, when [replaceEnhanced]) and of the raw one, unless
  /// they exist. A failure is only logged: sharing makes a missing MP3 itself.
  Future<void> _makeMp3s(String id, {required bool replaceEnhanced}) async {
    final RecordingModel? model = _models[id];
    if (model == null) return;
    final List<String> wavs = <String>[
      if (model.status == RecordingStatus.enhanced && model.enhancedFile != null) _store.enhancedPathOf(id),
      _store.rawPathOf(id),
    ];
    for (final String wav in wavs) {
      final File mp3 = File(Mp3EncoderService.mp3PathOf(wav));
      try {
        final bool replace = replaceEnhanced && wav == _store.enhancedPathOf(id);
        if ((!replace && await mp3.exists()) || !await File(wav).exists()) continue;
        await _mp3.encode(wavPath: wav, mp3Path: mp3.path);
        _logger.i('$_mp3Log$_successLog${mp3.path}');
      } on Exception catch (e) {
        _logger.w('$_mp3Log$_failureLog$e');
      }
    }
  }

  Future<void> _enhance(String id) async {
    final RecordingModel? model = _models[id];
    if (model == null) return;
    final File oldMp3 = File(Mp3EncoderService.mp3PathOf(_store.enhancedPathOf(id)));
    if (await oldMp3.exists()) await oldMp3.delete();
    final Result<EnhanceReport, VocalEnhanceFailure> result = await _engine.enhanceRecording(
      inputPath: _store.rawPathOf(id),
      outputPath: _store.enhancedPathOf(id),
      preset: EnhancePreset.natural,
      roomToneSeconds: null,
      trimSilence: model.trimSilence,
      settings: const <String, double>{},
    );
    final RecordingModel? current = _models[id];
    if (current == null) return; // deleted meanwhile
    final RecordingModel updated = switch (result) {
      SuccessResult<EnhanceReport, VocalEnhanceFailure>(:final EnhanceReport value) => current.copyWith(
        durationSeconds: value.before.durationSeconds,
        enhancedFile: _store.enhancedFileOf(id),
        keptFromSeconds: value.keptFromSeconds,
        keptToSeconds: value.keptToSeconds,
        status: RecordingStatus.enhanced,
        clearEnhanceFailure: true,
      ),
      FailureResult<EnhanceReport, VocalEnhanceFailure>(:final VocalEnhanceFailure failure) => current.copyWith(
        status: RecordingStatus.enhanceFailed,
        enhanceFailure:
            (failure == VocalEnhanceFailure.unavailable ? EnhanceFailure.unavailable : EnhanceFailure.failed).name,
      ),
    };
    try {
      await _save(updated);
      _logger.i('$_enhanceLog${updated.status.name}$_dashLog$id');
      if (updated.status == RecordingStatus.enhanced) _enqueueMp3(id, replaceEnhanced: true);
    } on Exception catch (e) {
      _logger.e('$_enhanceLog$_failureLog$e');
    }
  }

  Future<void> _onSongIdChanged(SongIdChange change) async {
    try {
      switch (change) {
        case SongMovedIdChange(:final String fromId, :final String toId):
          for (final RecordingModel model in _models.values.where((RecordingModel m) => m.songId == fromId).toList()) {
            await _save(model.copyWith(songId: toId));
          }
          _logger.i('$_songIdLog$fromId$_arrowLog$toId');
        case SongDeletedIdChange(:final String songId):
          for (final RecordingModel model in _models.values.where((RecordingModel m) => m.songId == songId).toList()) {
            await _store.delete(model.id);
            _models.remove(model.id);
          }
          _publish();
          _logger.i('$_songIdLog$_deleteLog$songId');
      }
    } on Exception catch (e) {
      _logger.e('$_songIdLog$_failureLog$e');
    }
  }

  Future<void> _save(RecordingModel model) async {
    await _store.put(model);
    _models[model.id] = model;
    _publish();
  }

  void _publish() {
    final List<Recording> recordings = _models.values.map(_entity).toList()
      ..sort((Recording a, Recording b) => b.recordedAt.compareTo(a.recordedAt));
    _recordings.value = recordings;
  }

  Recording _entity(RecordingModel model) => model.toEntity(folder: _store.folder);

  bool _wasInterrupted(RecordingModel model) => model.enhanceFailure == EnhanceFailure.interrupted.name;
}
