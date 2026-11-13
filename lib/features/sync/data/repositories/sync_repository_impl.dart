import 'dart:async';
import 'dart:convert';
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
import '../../../song/domain/entities/song_id_change.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/entities/sync_conflict.dart';
import '../../domain/entities/sync_state.dart';
import '../../domain/entities/sync_summary.dart';
import '../../domain/repositories/sync_repository.dart';
import '../data_sources/hive_sync_tombstone_service.dart';
import '../data_sources/sync_client_data_source.dart';
import '../data_sources/sync_server_data_source.dart';
import '../models/sync_counts_model.dart';
import '../models/sync_offer_model.dart';
import '../models/sync_plan_model.dart';
import '../models/sync_snapshot_model.dart';
import '../models/sync_song_key_model.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../domain/entities/sync_failure.dart';
import '../../domain/entities/song_difference.dart';
import '../../domain/entities/sync_step.dart';
import '../models/sync_step_model.dart';

/// [SyncRepository] over HTTP on the local network.
///
/// The device that scans the code drives the exchange: it takes the snapshot of the host and
/// finds the conflicts (deleted on one side and still on the other, songs that differ). When
/// there are any, it waits for the user's choices. Then it applies its own side of them,
/// downloads the covers it misses and merges, uploads the covers the host misses and sends its
/// snapshot with a plan of what the host must delete, update and bring back; the host applies the
/// plan and merges. Songs are matched by artist and name, covers and practice sessions by ids.
/// Deletions made on this device are remembered (tombstones) from [init] on.
final class SyncRepositoryImpl implements SyncRepository, SyncHostHandler, DisposableResource {
  static const String _quoteOpen = '«';
  static const String _quoteClose = '»';
  static const int _downloadAttempts = 2;
  static const String _stepSeparator = ' ';
  static const String _portSeparator = ':';
  static const String _countSeparator = '/';
  static const String _tempPrefix = 'hitwave_sync_';
  static const String _separator = '/';
  static const String _rawSuffix = '_raw.wav';
  static const String _enhancedSuffix = '_enhanced.wav';
  static const String _newSongId = '';
  static const String _snapshotField = 'snapshot';
  static const String _planField = 'plan';
  static const String _songConflictPrefix = 'song:';
  static const String _changedConflictPrefix = 'changed:';
  static const String _coverConflictPrefix = 'cover:';
  static const String _titleSeparator = ' — ';
  static final RegExp _lineEnd = RegExp(r'\r\n?');
  static const String _newLine = '\n';
  static const String _hostLog = 'SyncHost: ';
  static const String _clientLog = 'SyncWith: ';
  static const String _tombstoneLog = 'SyncTombstone: ';
  static const String _successLog = 'success — ';
  static const String _failureLog = 'failure — ';
  static const String _conflictsLog = ' conflicts';
  static const Duration _closeDelay = Duration(seconds: 1);

  static const Uuid _uuid = Uuid();

  final SongRepository _songs;
  final RecordingsRepository _recordings;
  final PracticeRepository _practice;
  final HistoryRepository _history;
  final HiveSyncTombstoneService _tombstones;
  final SyncServerDataSource _server;
  final SyncClientDataSource _client;
  final Logger _logger;
  final String _deviceName;

  final ValueNotifier<SyncState> _state = ValueNotifier<SyncState>(SyncState.idle);

  StreamSubscription<SongIdChange>? _songIdChanges;
  StreamSubscription<String>? _coverDeletions;

  /// Folder of the files the other device uploaded to this host.
  Directory? _received;

  /// The exchange that waits for the user's choices.
  _PendingSync? _pending;

  /// Name of the device that connected to this host.
  String? _peerName;

  /// Creates a [SyncRepositoryImpl]; [deviceName] is shown on the other device.
  SyncRepositoryImpl({
    required this._songs,
    required this._recordings,
    required this._practice,
    required this._history,
    required this._tombstones,
    required this._server,
    required this._client,
    required this._logger,
    required this._deviceName,
  });

  /// Starts remembering the deletions of songs and covers; returns this for the DI.
  SyncRepositoryImpl init() {
    _songIdChanges = _songs.watchSongIdChanges().listen(_onSongIdChanged);
    _coverDeletions = _recordings.watchRecordingDeletions().listen(_onCoverDeleted);
    return this;
  }

  /// Stops the server and the subscriptions and releases the state.
  @override
  Future<void> dispose() async {
    await _songIdChanges?.cancel();
    await _coverDeletions?.cancel();
    await _server.stop();
    await _deleteReceived();
    _state.dispose();
  }

  @override
  ValueListenable<SyncState> watchSyncState() => _state;

  @override
  bool isSupported() => !kIsWeb;

  @override
  Future<Result<void, SyncFailure>> startHosting() async {
    if (_isBusy) return const Result.failure(SyncFailure.busy);
    try {
      final List<String> addresses = await _server.localAddresses();
      if (addresses.isEmpty) return _fail(SyncFailure.noNetwork);
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
      return _fail(SyncFailure.host);
    }
  }

  @override
  Future<Result<void, SyncFailure>> stopSync() async {
    final _PendingSync? pending = _pending;
    _pending = null;
    if (pending != null) await _client.abort(pending.base, pending.offer.token, SyncFailure.cancelled.name);
    await _server.stop();
    await _deleteReceived();
    _state.value = SyncState.idle;
    return Result.ok;
  }

  @override
  Future<Result<void, SyncFailure>> syncWith(String code) async {
    if (_isBusy) return const Result.failure(SyncFailure.busy);
    final SyncOfferModel offer;
    try {
      offer = SyncOfferModel.decode(code);
    } on FormatException catch (e) {
      _logger.w('$_clientLog$_failureLog$e');
      return _fail(SyncFailure.notACode);
    }
    await _server.stop();
    Uri? connected;
    try {
      _step(const SyncStepModel(SyncStep.connecting), null);
      final Uri base = await _client.connect(addresses: offer.addresses, port: offer.port, token: offer.token);
      connected = base;
      _report(base, offer.token, const SyncStepModel(SyncStep.reading), null);
      final SyncSnapshotModel remote = SyncSnapshotModel.fromJsonText(await _client.snapshot(base, offer.token));
      final _PendingSync pending = _PendingSync(
        base: base,
        offer: offer,
        remote: remote,
        conflicts: _findConflicts(_snapshot(), remote),
      );
      if (pending.conflicts.isEmpty) return await _finish(pending, const <String, SyncChoice>{});
      _pending = pending;
      _state.value = ConflictsSyncState(<SyncConflict>[for (final _Conflict c in pending.conflicts) c.conflict]);
      unawaited(_client.progress(base, offer.token, const SyncStepModel(SyncStep.choosing).encode()));
      _logger.i('$_clientLog${pending.conflicts.length}$_conflictsLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_clientLog$_failureLog$e');
      final SyncFailure failure = e is SocketException ? SyncFailure.connect : SyncFailure.interrupted;
      if (connected != null) await _client.abort(connected, offer.token, failure.name);
      return _fail(failure);
    }
  }

  @override
  Future<Result<void, SyncFailure>> resolveConflicts(Map<String, SyncChoice> choices) async {
    final _PendingSync? pending = _pending;
    _pending = null;
    if (pending == null) return const Result.failure(SyncFailure.nothingWaits);
    return _finish(pending, choices);
  }

  @override
  void onConnected(String deviceName) {
    _peerName = deviceName.isEmpty ? null : '$_quoteOpen$deviceName$_quoteClose';
    _state.value = SyncingSyncState(step: SyncStep.joined, fraction: null, isPeer: true, peerName: _peerName);
  }

  @override
  void onPeerProgress(String step) {
    if (_state.value is DoneSyncState) return;
    final SyncStepModel? model = SyncStepModel.decode(step);
    if (model == null) return;
    _state.value = SyncingSyncState(
      step: model.step,
      done: model.done,
      total: model.total,
      fraction: null,
      isPeer: true,
      peerName: _peerName,
    );
  }

  @override
  void onPeerFailed(String message) {
    _state.value = FailedSyncState(
      SyncFailure.peerStopped,
      peerName: _peerName,
      peerFailure: SyncFailure.values.asNameMap()[message] ?? SyncFailure.interrupted,
    );
    unawaited(_deleteReceived());
    unawaited(Future<void>.delayed(_closeDelay, _server.stop));
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
      final Map<String, dynamic> envelope = jsonDecode(json) as Map<String, dynamic>;
      final SyncPlanModel plan = SyncPlanModel.fromJson(envelope[_planField] as Map<String, dynamic>);
      final _Applied applied = await _applyPlan(plan);
      final SyncCountsModel merged = await _merge(
        SyncSnapshotModel.fromJson(envelope[_snapshotField] as Map<String, dynamic>),
        _received,
      );
      final SyncCountsModel received = merged.plus(deleted: applied.deleted, updated: applied.updated);
      final SyncCountsModel sent = SyncCountsModel.fromJsonText(receivedJson);
      _state.value = DoneSyncState(_summary(here: received, there: sent));
      _logger.i(
        '$_hostLog$_successLog${received.songs}$_countSeparator${received.covers}$_countSeparator'
        '${received.sessions}$_countSeparator${received.deleted}$_countSeparator${received.updated}',
      );
      return received.toJsonText();
    } on Exception catch (e) {
      _logger.e('$_hostLog$_failureLog$e');
      _state.value = const FailedSyncState(SyncFailure.interrupted);
      rethrow;
    } finally {
      await _deleteReceived();
      unawaited(Future<void>.delayed(_closeDelay, _server.stop));
    }
  }

  bool get _isBusy => _state.value is SyncingSyncState || _pending != null;

  /// Applies the choices on this device, exchanges the covers and sends the snapshot and the
  /// plan for the other device.
  Future<Result<void, SyncFailure>> _finish(_PendingSync pending, Map<String, SyncChoice> choices) async {
    Directory? folder;
    try {
      final String token = pending.offer.token;
      final Uri base = pending.base;
      _report(base, token, const SyncStepModel(SyncStep.applying), null);
      final _Decisions decisions = await _decide(pending, choices);
      final SyncSnapshotModel remote = pending.remote;

      final Set<String> localIds = _recordings.watchRecordings().value.map(_recordingId).toSet();
      final Map<String, String> remoteSongKeys = <String, String>{
        for (final Song song in remote.songs) song.id: _keyOf(song),
      };
      final List<SyncRecordingModel> missing = remote.recordings
          .where(
            (SyncRecordingModel recording) =>
                !localIds.contains(recording.id) &&
                !decisions.skipCovers.contains(recording.id) &&
                !decisions.skipSongs.contains(remoteSongKeys[recording.songId]),
          )
          .toList();
      folder = await Directory.systemTemp.createTemp(_tempPrefix);
      for (int index = 0; index < missing.length; index++) {
        _report(
          base,
          token,
          SyncStepModel(SyncStep.downloading, done: index + 1, total: missing.length),
          index / missing.length,
        );
        final SyncRecordingModel recording = missing[index];
        await _download(base, token, recording.rawFile, folder);
        if (recording.hasEnhanced) await _download(base, token, recording.enhancedFile, folder);
      }

      _report(base, token, const SyncStepModel(SyncStep.merging), null);
      final SyncCountsModel received = (await _merge(
        remote,
        folder,
        skipSongs: decisions.skipSongs,
        skipCovers: decisions.skipCovers,
      )).plus(deleted: decisions.deletedHere, updated: decisions.updatedHere);

      final SyncSnapshotModel local = _snapshot();
      final Set<String> remoteIds = remote.recordings.map(_syncRecordingId).toSet();
      final List<Recording> toSend = _recordings
          .watchRecordings()
          .value
          .where(
            (Recording recording) =>
                !remoteIds.contains(recording.id) &&
                local.recordings.any((SyncRecordingModel r) => r.id == recording.id),
          )
          .toList();
      for (int index = 0; index < toSend.length; index++) {
        _report(
          base,
          token,
          SyncStepModel(SyncStep.uploading, done: index + 1, total: toSend.length),
          index / toSend.length,
        );
        final SyncRecordingModel model = SyncRecordingModel.fromEntity(toSend[index]);
        await _client.upload(base: base, token: token, name: model.rawFile, from: File(toSend[index].rawPath));
        final String? enhanced = toSend[index].enhancedPath;
        if (model.hasEnhanced && enhanced != null) {
          await _client.upload(base: base, token: token, name: model.enhancedFile, from: File(enhanced));
        }
      }

      _report(base, token, const SyncStepModel(SyncStep.merging), null);
      final SyncCountsModel sent = SyncCountsModel.fromJsonText(
        await _client.sendSnapshot(
          base: base,
          token: token,
          json: jsonEncode(<String, dynamic>{_snapshotField: local.toJson(), _planField: decisions.plan.toJson()}),
          receivedJson: received.toJsonText(),
        ),
      );
      _state.value = DoneSyncState(_summary(here: received, there: sent));
      _logger.i('$_clientLog$_successLog${pending.offer.deviceName}');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_clientLog$_failureLog$e');
      final SyncFailure failure = e is SocketException ? SyncFailure.connect : SyncFailure.interrupted;
      await _client.abort(pending.base, pending.offer.token, failure.name);
      return _fail(failure);
    } finally {
      if (folder != null) await _deleteFolder(folder);
    }
  }

  /// The conflicts between [local] and [remote]; covers of a song in a deletion conflict follow
  /// the song and are no conflicts of their own.
  List<_Conflict> _findConflicts(SyncSnapshotModel local, SyncSnapshotModel remote) {
    final Map<String, Song> localSongs = <String, Song>{for (final Song song in local.songs) _keyOf(song): song};
    final Map<String, Song> remoteSongs = <String, Song>{for (final Song song in remote.songs) _keyOf(song): song};
    final Map<String, DateTime?> localDeleted = <String, DateTime?>{
      for (final SyncSongKeyModel song in local.deletedSongs) song.key: song.deletedAt,
    };
    final Map<String, DateTime?> remoteDeleted = <String, DateTime?>{
      for (final SyncSongKeyModel song in remote.deletedSongs) song.key: song.deletedAt,
    };
    final List<_Conflict> conflicts = <_Conflict>[];
    final Set<String> songsInConflict = <String>{};

    for (final MapEntry<String, Song> entry in remoteSongs.entries) {
      final Song? here = localSongs[entry.key];
      if (here == null && localDeleted.containsKey(entry.key)) {
        songsInConflict.add(entry.key);
        conflicts.add(
          _Conflict(
            conflict: SyncConflict(
              id: '$_songConflictPrefix${entry.key}',
              kind: SyncConflictKind.songDeletedHere,
              songTitle: _songTitle(entry.value),
              deletedAt: localDeleted[entry.key],
            ),
            song: entry.value,
          ),
        );
      } else if (here != null) {
        final Set<SongDifference> differences = _differences(here, entry.value);
        if (differences.isNotEmpty) {
          conflicts.add(
            _Conflict(
              conflict: SyncConflict(
                id: '$_changedConflictPrefix${entry.key}',
                kind: SyncConflictKind.songChanged,
                songTitle: _songTitle(here),
                differences: differences,
              ),
              song: here,
              otherSong: entry.value,
            ),
          );
        }
      }
    }
    for (final MapEntry<String, Song> entry in localSongs.entries) {
      if (!remoteSongs.containsKey(entry.key) && remoteDeleted.containsKey(entry.key)) {
        songsInConflict.add(entry.key);
        conflicts.add(
          _Conflict(
            conflict: SyncConflict(
              id: '$_songConflictPrefix${entry.key}',
              kind: SyncConflictKind.songDeletedThere,
              songTitle: _songTitle(entry.value),
              deletedAt: remoteDeleted[entry.key],
            ),
            song: entry.value,
          ),
        );
      }
    }

    final Map<String, Song> localById = <String, Song>{for (final Song song in local.songs) song.id: song};
    final Map<String, Song> remoteById = <String, Song>{for (final Song song in remote.songs) song.id: song};
    final Set<String> localCovers = local.recordings.map(_syncRecordingId).toSet();
    final Set<String> remoteCovers = remote.recordings.map(_syncRecordingId).toSet();
    for (final SyncRecordingModel cover in remote.recordings) {
      final Song? song = remoteById[cover.songId];
      if (localCovers.contains(cover.id) || !local.deletedCovers.containsKey(cover.id)) continue;
      if (song != null && songsInConflict.contains(_keyOf(song))) continue;
      conflicts.add(_coverConflict(cover, song, SyncConflictKind.coverDeletedHere, local.deletedCovers[cover.id]));
    }
    for (final SyncRecordingModel cover in local.recordings) {
      final Song? song = localById[cover.songId];
      if (remoteCovers.contains(cover.id) || !remote.deletedCovers.containsKey(cover.id)) continue;
      if (song != null && songsInConflict.contains(_keyOf(song))) continue;
      conflicts.add(_coverConflict(cover, song, SyncConflictKind.coverDeletedThere, remote.deletedCovers[cover.id]));
    }
    return conflicts;
  }

  /// Does on this device what the choices say and writes down what the other device must do.
  Future<_Decisions> _decide(_PendingSync pending, Map<String, SyncChoice> choices) async {
    final List<SyncSongKeyModel> deleteThere = <SyncSongKeyModel>[];
    final List<SyncSongKeyModel> forgetThere = <SyncSongKeyModel>[];
    final List<Song> updateThere = <Song>[];
    final List<String> deleteCoversThere = <String>[];
    final List<String> forgetCoversThere = <String>[];
    final Set<String> skipSongs = <String>{};
    final Set<String> skipCovers = <String>{};
    int deletedHere = 0;
    int updatedHere = 0;

    for (final _Conflict item in pending.conflicts) {
      final SyncConflict conflict = item.conflict;
      final SyncChoice choice = choices[conflict.id] ?? conflict.choices.first;
      final Song? song = item.song;
      final String? coverId = item.coverId;
      switch (conflict.kind) {
        case SyncConflictKind.songDeletedHere:
          final SyncSongKeyModel key = _songKey(song!);
          if (choice == SyncChoice.delete) {
            deleteThere.add(key);
            skipSongs.add(key.key);
          } else {
            await _tombstones.forgetSong(key);
          }
        case SyncConflictKind.songDeletedThere:
          if (choice == SyncChoice.delete) {
            _throwOnFailure(await _songs.deleteSong(songId: song!.id));
            deletedHere++;
          } else {
            forgetThere.add(_songKey(song!));
          }
        case SyncConflictKind.songChanged:
          if (choice == SyncChoice.takeOther) {
            await _updateSong(song!.id, item.otherSong!);
            updatedHere++;
          } else {
            updateThere.add(song!);
          }
        case SyncConflictKind.coverDeletedHere:
          if (choice == SyncChoice.delete) {
            deleteCoversThere.add(coverId!);
            skipCovers.add(coverId);
          } else {
            await _tombstones.forgetCover(coverId!);
          }
        case SyncConflictKind.coverDeletedThere:
          if (choice == SyncChoice.delete) {
            _throwOnFailure(await _recordings.deleteRecording(coverId!));
            deletedHere++;
          } else {
            forgetCoversThere.add(coverId!);
          }
      }
    }
    return _Decisions(
      plan: SyncPlanModel(
        deleteSongs: deleteThere,
        forgetSongs: forgetThere,
        updateSongs: updateThere,
        deleteCovers: deleteCoversThere,
        forgetCovers: forgetCoversThere,
      ),
      skipSongs: skipSongs,
      skipCovers: skipCovers,
      deletedHere: deletedHere,
      updatedHere: updatedHere,
    );
  }

  /// Does on this (hosting) device what the other device's user decided.
  Future<_Applied> _applyPlan(SyncPlanModel plan) async {
    int deleted = 0;
    int updated = 0;
    final Map<String, Song> songs = <String, Song>{
      for (final Song song in _songs.watchSongs().value) _keyOf(song): song,
    };
    for (final SyncSongKeyModel key in plan.deleteSongs) {
      final Song? song = songs[key.key];
      if (song == null) continue;
      _throwOnFailure(await _songs.deleteSong(songId: song.id));
      deleted++;
    }
    final Set<String> covers = _recordings.watchRecordings().value.map(_recordingId).toSet();
    for (final String id in plan.deleteCovers) {
      if (!covers.contains(id)) continue;
      _throwOnFailure(await _recordings.deleteRecording(id));
      deleted++;
    }
    for (final Song incoming in plan.updateSongs) {
      final Song? song = songs[_keyOf(incoming)];
      if (song == null) continue;
      await _updateSong(song.id, incoming);
      updated++;
    }
    for (final SyncSongKeyModel key in plan.forgetSongs) {
      await _tombstones.forgetSong(key);
    }
    for (final String id in plan.forgetCovers) {
      await _tombstones.forgetCover(id);
    }
    return _Applied(deleted: deleted, updated: updated);
  }

  /// Gives the song [songId] the lyrics, album, speed and space above the lyrics of [source].
  Future<void> _updateSong(String songId, Song source) async {
    _throwOnFailure(
      await _songs.updateSong(
        songId: songId,
        author: source.author,
        name: source.name,
        album: source.album,
        lyrics: source.lyrics,
      ),
    );
    final double? speed = source.scrollSpeed;
    if (speed != null) _throwOnFailure(await _songs.updateSongScrollSpeed(songId: songId, speed: speed));
    final double? leadIn = source.leadIn;
    if (leadIn != null) _throwOnFailure(await _songs.updateSongLeadIn(songId: songId, leadIn: leadIn));
  }

  /// Everything of this device to send; covers and sessions of songs that are gone are left out.
  SyncSnapshotModel _snapshot() {
    final List<Song> songs = _songs.watchSongs().value;
    final Set<String> songIds = songs.map(_songId).toSet();
    return SyncSnapshotModel(
      songs: songs,
      recordings: _recordings
          .watchRecordings()
          .value
          .where((Recording recording) => songIds.contains(recording.songId))
          .map(SyncRecordingModel.fromEntity)
          .toList(),
      sessions: _practice
          .watchSessions()
          .value
          .where((PracticeSession session) => songIds.contains(session.songId))
          .toList(),
      history: _history.watchHistory().value,
      deletedSongs: _tombstones.deletedSongs(),
      deletedCovers: _tombstones.deletedCovers(),
    );
  }

  /// Adds what [remote] has and this device misses, except [skipSongs] (by key) and [skipCovers]
  /// (by id); the files of its covers are in [folder]. Whatever comes back stops being deleted.
  Future<SyncCountsModel> _merge(
    SyncSnapshotModel remote,
    Directory? folder, {
    Set<String> skipSongs = const <String>{},
    Set<String> skipCovers = const <String>{},
  }) async {
    final Map<String, String> localByKey = <String, String>{
      for (final Song song in _songs.watchSongs().value) _keyOf(song): song.id,
    };
    final Map<String, String> songIds = <String, String>{};
    final Map<String, int> newByKey = <String, int>{};
    final List<Song> newSongs = <Song>[];
    final Map<String, int> newIndexOfRemote = <String, int>{};
    for (final Song song in remote.songs) {
      final String key = _keyOf(song);
      if (skipSongs.contains(key)) continue;
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
      final Result<List<String>, SongFailure> added = await _songs.addSongs(newSongs);
      final List<String> ids = switch (added) {
        SuccessResult<List<String>, SongFailure>(:final List<String> value) => value,
        FailureResult<List<String>, SongFailure>(:final SongFailure failure) => throw HttpException(failure.name),
      };
      for (final MapEntry<String, int> entry in newIndexOfRemote.entries) {
        if (entry.value < ids.length) songIds[entry.key] = ids[entry.value];
      }
      for (final Song song in newSongs) {
        await _tombstones.forgetSong(_songKey(song));
      }
    }

    final Set<String> localRecordings = _recordings.watchRecordings().value.map(_recordingId).toSet();
    final List<ImportedRecording> covers = <ImportedRecording>[];
    for (final SyncRecordingModel recording in remote.recordings) {
      final String? songId = songIds[recording.songId];
      if (folder == null || songId == null || localRecordings.contains(recording.id)) continue;
      if (skipCovers.contains(recording.id)) continue;
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
    if (covers.isNotEmpty) {
      _throwOnFailure(await _recordings.importRecordings(covers));
      for (final ImportedRecording cover in covers) {
        await _tombstones.forgetCover(cover.id!);
      }
    }

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

  Future<void> _onSongIdChanged(SongIdChange change) async {
    if (change case SongDeletedIdChange(:final String? author, :final String? name)) {
      if (author == null || name == null) return;
      try {
        await _tombstones.putSong(SyncSongKeyModel(author: author, name: name));
      } on Exception catch (e) {
        _logger.e('$_tombstoneLog$_failureLog$e');
      }
    }
  }

  Future<void> _onCoverDeleted(String id) async {
    try {
      await _tombstones.putCover(id);
    } on Exception catch (e) {
      _logger.e('$_tombstoneLog$_failureLog$e');
    }
  }

  /// Shows [step] here and tells the hosting device.
  void _report(Uri base, String token, SyncStepModel step, double? fraction) {
    _step(step, fraction);
    unawaited(_client.progress(base, token, step.encode()));
  }

  /// Downloads [name] into [folder], once more when the first transfer is cut.
  Future<void> _download(Uri base, String token, String name, Directory folder) async {
    for (int attempt = 1; ; attempt++) {
      try {
        await _client.download(base: base, token: token, name: name, to: _fileIn(folder, name));
        return;
      } on Exception {
        if (attempt >= _downloadAttempts) rethrow;
      }
    }
  }

  void _step(SyncStepModel step, double? fraction) {
    _state.value = SyncingSyncState(step: step.step, done: step.done, total: step.total, fraction: fraction);
  }

  Result<void, SyncFailure> _fail(SyncFailure failure) {
    _state.value = FailedSyncState(failure);
    return Result.failure(failure);
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

  static void _throwOnFailure<F extends Enum>(Result<void, F> result) {
    if (result case FailureResult<void, F>(:final F failure)) throw HttpException(failure.name);
  }

  static _Conflict _coverConflict(SyncRecordingModel cover, Song? song, SyncConflictKind kind, DateTime? deletedAt) =>
      _Conflict(
        conflict: SyncConflict(
          id: '$_coverConflictPrefix${cover.id}',
          kind: kind,
          songTitle: song == null ? null : _songTitle(song),
          coverRecordedAt: cover.recordedAt,
          deletedAt: deletedAt,
        ),
        coverId: cover.id,
      );

  /// What differs between [here] and [there]: lyrics, album.
  /// The speed and the space above the lyrics are settings of each device, not of the song.
  static Set<SongDifference> _differences(Song here, Song there) => <SongDifference>{
    if (_lyrics(here.lyrics) != _lyrics(there.lyrics)) SongDifference.lyrics,
    if ((here.album ?? '').trim() != (there.album ?? '').trim()) SongDifference.album,
  };

  /// Lyrics without differences that do not show: line endings and spaces at the ends of lines.
  static String _lyrics(String lyrics) => lyrics
      .replaceAll(_lineEnd, _newLine)
      .split(_newLine)
      .map((String line) => line.trimRight())
      .join(_newLine)
      .trim();

  static SyncSummary _summary({required SyncCountsModel here, required SyncCountsModel there}) => SyncSummary(
    songsReceived: here.songs,
    coversReceived: here.covers,
    sessionsReceived: here.sessions,
    songsSent: there.songs,
    coversSent: there.covers,
    sessionsSent: there.sessions,
    deletedHere: here.deleted,
    deletedThere: there.deleted,
    updatedHere: here.updated,
    updatedThere: there.updated,
  );

  static String _songTitle(Song song) => '${song.name}$_titleSeparator${song.author}';

  static File _fileIn(Directory folder, String name) => File('${folder.path}$_separator$name');

  static String _keyOf(Song song) => SyncSongKeyModel.keyOf(author: song.author, name: song.name);

  static SyncSongKeyModel _songKey(Song song) => SyncSongKeyModel(author: song.author, name: song.name);

  static String _songId(Song song) => song.id;

  static String _recordingId(Recording recording) => recording.id;

  static String _syncRecordingId(SyncRecordingModel recording) => recording.id;

  static String _sessionId(PracticeSession session) => session.id;
}

/// A conflict with what is needed to act on it.
final class _Conflict {
  final SyncConflict conflict;

  /// The song (of this device, or of the other one when it is missing here).
  final Song? song;

  /// The other device's version of a changed song.
  final Song? otherSong;

  /// The cover of a cover conflict.
  final String? coverId;

  const _Conflict({required this.conflict, this.song, this.otherSong, this.coverId});
}

/// An exchange that waits for the user's choices.
final class _PendingSync {
  final Uri base;
  final SyncOfferModel offer;
  final SyncSnapshotModel remote;
  final List<_Conflict> conflicts;

  const _PendingSync({required this.base, required this.offer, required this.remote, required this.conflicts});
}

/// What the choices did here and ask of the other device.
final class _Decisions {
  final SyncPlanModel plan;
  final Set<String> skipSongs;
  final Set<String> skipCovers;
  final int deletedHere;
  final int updatedHere;

  const _Decisions({
    required this.plan,
    required this.skipSongs,
    required this.skipCovers,
    required this.deletedHere,
    required this.updatedHere,
  });
}

/// What the plan of the other device did here.
final class _Applied {
  final int deleted;
  final int updated;

  const _Applied({required this.deleted, required this.updated});
}
