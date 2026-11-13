import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../history/domain/entities/usage_history.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../practice/domain/entities/practice_session.dart';
import '../../../practice/domain/repositories/practice_repository.dart';
import '../../../recordings/domain/entities/imported_recording.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/repositories/recordings_repository.dart';
import '../../../song/domain/entities/cover.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/entities/sync_state.dart';
import '../../domain/entities/sync_summary.dart';
import '../../domain/repositories/sync_repository.dart';
import '../data_sources/sync_client_data_source.dart';
import '../data_sources/sync_server_data_source.dart';
import '../models/sync_counts_model.dart';
import '../models/sync_offer_model.dart';
import '../models/sync_snapshot_model.dart';

/// [SyncRepository] over HTTP on the local network.
///
/// The device that scans the code drives the exchange: it takes the snapshot of the host,
/// downloads the covers it misses and merges, then uploads the covers the host misses and sends
/// its own snapshot, which the host merges. Merging never deletes: songs are matched by artist
/// and name, covers and practice sessions by their ids, the later history time wins.
final class SyncRepositoryImpl implements SyncRepository, SyncHostHandler, DisposableResource {
  static const String _noNetworkError = 'Немає підключення до мережі. Під’єднайтеся до Wi‑Fi.';
  static const String _hostError = 'Не вдалося почати синхронізацію';
  static const String _syncError = 'Синхронізація перервалася';
  static const String _busyError = 'Синхронізація вже йде';
  static const String _connectingStep = 'Підключаюся…';
  static const String _readingStep = 'Отримую список пісень і каверів…';
  static const String _downloadingStep = 'Завантажую кавери';
  static const String _uploadingStep = 'Надсилаю кавери';
  static const String _mergingStep = 'Об’єдную дані…';
  static const String _peerStep = 'Пристрій підключився, обмінюємося даними…';
  static const String _stepSeparator = ' ';
  static const String _portSeparator = ':';
  static const String _countSeparator = '/';
  static const String _of = ' з ';
  static const String _tempPrefix = 'hitwave_sync_';
  static const String _separator = '/';
  static const String _keySeparator = '\u0000';
  static const String _rawSuffix = '_raw.wav';
  static const String _enhancedSuffix = '_enhanced.wav';
  static const String _newSongId = '';
  static const String _hostLog = 'SyncHost: ';
  static const String _clientLog = 'SyncWith: ';
  static const String _successLog = 'success — ';
  static const String _failureLog = 'failure — ';
  static const Duration _closeDelay = Duration(seconds: 1);

  static const Uuid _uuid = Uuid();

  final SongRepository _songs;
  final RecordingsRepository _recordings;
  final PracticeRepository _practice;
  final HistoryRepository _history;
  final SyncServerDataSource _server;
  final SyncClientDataSource _client;
  final Logger _logger;
  final String _deviceName;

  final ValueNotifier<SyncState> _state = ValueNotifier<SyncState>(SyncState.idle);

  /// Folder of the files the other device uploaded to this host.
  Directory? _received;

  /// Creates a [SyncRepositoryImpl]; [deviceName] is shown on the other device.
  SyncRepositoryImpl({
    required this._songs,
    required this._recordings,
    required this._practice,
    required this._history,
    required this._server,
    required this._client,
    required this._logger,
    required this._deviceName,
  });

  /// Stops the server and releases the state.
  @override
  Future<void> dispose() async {
    await _server.stop();
    await _deleteReceived();
    _state.dispose();
  }

  @override
  ValueListenable<SyncState> watchSyncState() => _state;

  @override
  bool isSupported() => !kIsWeb;

  @override
  Future<Result<void>> startHosting() async {
    if (_state.value is SyncingSyncState) return const Result.failure(_busyError);
    try {
      final List<String> addresses = await _server.localAddresses();
      if (addresses.isEmpty) return _fail(_noNetworkError);
      final String token = _uuid.v4();
      final int port = await _server.start(token: token, handler: this);
      final String code = SyncOfferModel(
        addresses: addresses,
        port: port,
        token: token,
        deviceName: _deviceName,
      ).encode();
      _state.value = HostingSyncState(code);
      _logger.i('$_hostLog$_successLog${addresses.join(_stepSeparator)}$_portSeparator$port');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_hostLog$_failureLog$e');
      return _fail(_hostError);
    }
  }

  @override
  Future<Result<void>> stopSync() async {
    await _server.stop();
    await _deleteReceived();
    _state.value = SyncState.idle;
    return Result.ok;
  }

  @override
  Future<Result<void>> syncWith(String code) async {
    if (_state.value is SyncingSyncState) return const Result.failure(_busyError);
    final SyncOfferModel offer;
    try {
      offer = SyncOfferModel.decode(code);
    } on FormatException catch (e) {
      return _fail(e.message);
    }
    await _server.stop();
    Directory? folder;
    try {
      _step(_connectingStep, null);
      final Uri base = await _client.connect(addresses: offer.addresses, port: offer.port, token: offer.token);

      _step(_readingStep, null);
      final SyncSnapshotModel remote = SyncSnapshotModel.fromJsonText(await _client.snapshot(base, offer.token));
      final Set<String> localIds = _recordings.watchRecordings().value.map(_recordingId).toSet();
      final List<SyncRecordingModel> missing = remote.recordings
          .where((SyncRecordingModel recording) => !localIds.contains(recording.id))
          .toList();

      folder = await Directory.systemTemp.createTemp(_tempPrefix);
      for (int index = 0; index < missing.length; index++) {
        _step(_counted(_downloadingStep, index, missing.length), index / missing.length);
        final SyncRecordingModel recording = missing[index];
        await _client.download(
          base: base,
          token: offer.token,
          name: recording.rawFile,
          to: _fileIn(folder, recording.rawFile),
        );
        if (recording.hasEnhanced) {
          await _client.download(
            base: base,
            token: offer.token,
            name: recording.enhancedFile,
            to: _fileIn(folder, recording.enhancedFile),
          );
        }
      }

      _step(_mergingStep, null);
      final SyncCountsModel received = await _merge(remote, folder);

      final Set<String> remoteIds = remote.recordings.map(_syncRecordingId).toSet();
      final List<Recording> toSend = _recordings
          .watchRecordings()
          .value
          .where((Recording recording) => !remoteIds.contains(recording.id))
          .toList();
      for (int index = 0; index < toSend.length; index++) {
        _step(_counted(_uploadingStep, index, toSend.length), index / toSend.length);
        final SyncRecordingModel model = SyncRecordingModel.fromEntity(toSend[index]);
        await _client.upload(base: base, token: offer.token, name: model.rawFile, from: File(toSend[index].rawPath));
        final String? enhanced = toSend[index].enhancedPath;
        if (model.hasEnhanced && enhanced != null) {
          await _client.upload(base: base, token: offer.token, name: model.enhancedFile, from: File(enhanced));
        }
      }

      _step(_mergingStep, null);
      final SyncCountsModel sent = SyncCountsModel.fromJsonText(
        await _client.sendSnapshot(
          base: base,
          token: offer.token,
          json: _snapshot().toJsonText(),
          receivedJson: received.toJsonText(),
        ),
      );
      _state.value = DoneSyncState(_summary(received: received, sent: sent));
      _logger.i('$_clientLog$_successLog${offer.deviceName}');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_clientLog$_failureLog$e');
      return _fail(e is SocketException ? e.message : _syncError);
    } finally {
      if (folder != null) await _deleteFolder(folder);
    }
  }

  @override
  void onConnected() {
    _step(_peerStep, null);
  }

  @override
  Future<String> snapshot() async => _snapshot().toJsonText();

  @override
  String? filePath(String name) {
    for (final Recording recording in _recordings.watchRecordings().value) {
      if (name == '${recording.id}$_rawSuffix') return recording.rawPath;
      if (name == '${recording.id}$_enhancedSuffix') return recording.enhancedPath;
    }
    return null;
  }

  @override
  Future<void> receiveFile(String name, Stream<List<int>> data) async {
    final Directory folder = _received ??= await Directory.systemTemp.createTemp(_tempPrefix);
    final IOSink sink = _fileIn(folder, name).openWrite();
    try {
      await sink.addStream(data);
    } finally {
      await sink.close();
    }
  }

  @override
  Future<String> receiveSnapshot({required String json, required String receivedJson}) async {
    try {
      final SyncCountsModel received = await _merge(SyncSnapshotModel.fromJsonText(json), _received);
      final SyncCountsModel sent = SyncCountsModel.fromJsonText(receivedJson);
      _state.value = DoneSyncState(_summary(received: received, sent: sent));
      _logger.i(
        '$_hostLog$_successLog${received.songs}$_countSeparator${received.covers}$_countSeparator${received.sessions}',
      );
      return received.toJsonText();
    } on Exception catch (e) {
      _logger.e('$_hostLog$_failureLog$e');
      _state.value = const FailedSyncState(_syncError);
      rethrow;
    } finally {
      await _deleteReceived();
      unawaited(Future<void>.delayed(_closeDelay, _server.stop));
    }
  }

  /// Everything of this device to send.
  SyncSnapshotModel _snapshot() => SyncSnapshotModel(
    songs: _songs.watchSongs().value,
    recordings: _recordings.watchRecordings().value.map(SyncRecordingModel.fromEntity).toList(),
    sessions: _practice.watchSessions().value,
    history: _history.watchHistory().value,
  );

  /// Adds what [remote] has and this device misses; the files of its covers are in [folder].
  Future<SyncCountsModel> _merge(SyncSnapshotModel remote, Directory? folder) async {
    final Map<String, String> localByKey = <String, String>{
      for (final Song song in _songs.watchSongs().value) _key(song): song.id,
    };
    final Map<String, String> songIds = <String, String>{};
    final Map<String, int> newByKey = <String, int>{};
    final List<Song> newSongs = <Song>[];
    final Map<String, int> newIndexOfRemote = <String, int>{};
    for (final Song song in remote.songs) {
      final String key = _key(song);
      final String? local = localByKey[key];
      if (local != null) {
        songIds[song.id] = local;
        continue;
      }
      final int index = newByKey.putIfAbsent(key, () {
        newSongs.add(
          Song(
            id: _newSongId,
            author: song.author,
            name: song.name,
            album: song.album,
            lyrics: song.lyrics,
            covers: const <Cover>[],
            scrollSpeed: song.scrollSpeed,
            leadIn: song.leadIn,
          ),
        );
        return newSongs.length - 1;
      });
      newIndexOfRemote[song.id] = index;
    }
    if (newSongs.isNotEmpty) {
      final Result<List<String>> added = await _songs.addSongs(newSongs);
      final List<String> ids = switch (added) {
        SuccessResult<List<String>>(:final List<String> value) => value,
        FailureResult<List<String>>(:final String error) => throw HttpException(error),
      };
      for (final MapEntry<String, int> entry in newIndexOfRemote.entries) {
        if (entry.value < ids.length) songIds[entry.key] = ids[entry.value];
      }
    }

    final Set<String> localRecordings = _recordings.watchRecordings().value.map(_recordingId).toSet();
    final List<ImportedRecording> covers = <ImportedRecording>[];
    for (final SyncRecordingModel recording in remote.recordings) {
      final String? songId = songIds[recording.songId];
      if (folder == null || songId == null || localRecordings.contains(recording.id)) continue;
      final File raw = _fileIn(folder, recording.rawFile);
      if (!await raw.exists()) continue;
      final File enhanced = _fileIn(folder, recording.enhancedFile);
      covers.add(
        ImportedRecording(
          id: recording.id,
          songId: songId,
          recordedAt: recording.recordedAt,
          durationSeconds: recording.durationSeconds,
          rawFilePath: raw.path,
          enhancedFilePath: recording.hasEnhanced && await enhanced.exists() ? enhanced.path : null,
          keptFromSeconds: recording.keptFromSeconds,
          keptToSeconds: recording.keptToSeconds,
        ),
      );
    }
    if (covers.isNotEmpty) _throwOnFailure(await _recordings.importRecordings(covers));

    final Set<String> localSessions = _practice.watchSessions().value.map(_sessionId).toSet();
    final List<PracticeSession> sessions = <PracticeSession>[
      for (final PracticeSession session in remote.sessions)
        if (!localSessions.contains(session.id) && songIds[session.songId] != null)
          PracticeSession(
            id: session.id,
            songId: songIds[session.songId]!,
            startedAt: session.startedAt,
            duration: session.duration,
          ),
    ];
    if (sessions.isNotEmpty) _throwOnFailure(await _practice.importSessions(sessions));

    _throwOnFailure(
      await _history.importHistory(
        UsageHistory(
          songsOpenedAt: <String, DateTime>{
            for (final MapEntry<String, DateTime> entry in remote.history.songsOpenedAt.entries)
              if (songIds[entry.key] != null) songIds[entry.key]!: entry.value,
          },
          coversPlayedAt: remote.history.coversPlayedAt,
        ),
      ),
    );

    return SyncCountsModel(songs: newSongs.length, covers: covers.length, sessions: sessions.length);
  }

  void _step(String step, double? fraction) {
    _state.value = SyncingSyncState(step: step, fraction: fraction);
  }

  Result<void> _fail(String message) {
    _state.value = FailedSyncState(message);
    return Result.failure(message);
  }

  Future<void> _deleteReceived() async {
    final Directory? folder = _received;
    _received = null;
    if (folder != null) await _deleteFolder(folder);
  }

  static Future<void> _deleteFolder(Directory folder) async {
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } on FileSystemException {
      // A temporary folder the system cleans up anyway.
    }
  }

  static void _throwOnFailure(Result<void> result) {
    if (result case FailureResult<void>(:final String error)) throw HttpException(error);
  }

  static SyncSummary _summary({required SyncCountsModel received, required SyncCountsModel sent}) => SyncSummary(
    songsReceived: received.songs,
    coversReceived: received.covers,
    sessionsReceived: received.sessions,
    songsSent: sent.songs,
    coversSent: sent.covers,
    sessionsSent: sent.sessions,
  );

  static String _counted(String step, int index, int count) => '$step$_stepSeparator${index + 1}$_of$count';

  static File _fileIn(Directory folder, String name) => File('${folder.path}$_separator$name');

  static String _key(Song song) => '${song.author.trim().toLowerCase()}$_keySeparator${song.name.trim().toLowerCase()}';

  static String _recordingId(Recording recording) => recording.id;

  static String _syncRecordingId(SyncRecordingModel recording) => recording.id;

  static String _sessionId(PracticeSession session) => session.id;
}
