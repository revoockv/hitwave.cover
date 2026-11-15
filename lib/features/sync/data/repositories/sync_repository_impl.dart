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
import '../../../song/domain/entities/lyrics_layout.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/entities/song_id_change.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/entities/sync_change.dart';
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
/// lists every change, both ways: what each device misses, what was deleted on one side and is
/// still on the other, songs that differ. When there are any, it waits for the user to choose
/// which to make. Then it makes its own side of them, downloads the chosen covers it misses and
/// merges, uploads the chosen covers the host misses and sends its snapshot (without what was not
/// chosen) with a plan of what the host must delete, update and bring back; the host applies the
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
  static const String _idSeparator = ':';
  static const String _practiceRef = 'sessions';
  static const String _titleSeparator = ' — ';
  static final RegExp _lineEnd = RegExp(r'\r\n?');
  static const String _newLine = '\n';
  static const String _hostLog = 'SyncHost: ';
  static const String _clientLog = 'SyncWith: ';
  static const String _tombstoneLog = 'SyncTombstone: ';
  static const String _successLog = 'success — ';
  static const String _failureLog = 'failure — ';
  static const String _changesLog = ' changes';
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
        changes: _findChanges(_snapshot(), remote),
      );
      if (pending.changes.isEmpty) return await _finish(pending, const <String>{});
      _pending = pending;
      _state.value = ReviewSyncState(
        changes: <SyncChange>[for (final _Change c in pending.changes) c.change],
        peerName: offer.deviceName,
      );
      unawaited(_client.progress(base, offer.token, const SyncStepModel(SyncStep.choosing).encode()));
      _logger.i('$_clientLog${pending.changes.length}$_changesLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_clientLog$_failureLog$e');
      final SyncFailure failure = e is SocketException ? SyncFailure.connect : SyncFailure.interrupted;
      if (connected != null) await _client.abort(connected, offer.token, failure.name);
      return _fail(failure);
    }
  }

  @override
  Future<Result<void, SyncFailure>> applyChanges(Set<String> chosen) async {
    final _PendingSync? pending = _pending;
    _pending = null;
    if (pending == null) return const Result.failure(SyncFailure.nothingWaits);
    return _finish(pending, chosen);
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

  /// Makes the [chosen] changes on this device, exchanges the covers and sends the snapshot and
  /// the plan for the other device.
  Future<Result<void, SyncFailure>> _finish(_PendingSync pending, Set<String> chosen) async {
    Directory? folder;
    try {
      final String token = pending.offer.token;
      final Uri base = pending.base;
      _report(base, token, const SyncStepModel(SyncStep.applying), null);
      final _Decisions decisions = await _decide(pending, chosen);
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
        skipSessions: decisions.skipSessions,
      )).plus(deleted: decisions.deletedHere, updated: decisions.updatedHere);

      final SyncSnapshotModel local = _withoutSkipped(_snapshot(), decisions);
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

  /// Every change between [local] and [remote], those made on this device first. Covers of a song
  /// that is added or deleted go with the song; practice sessions are one change each way.
  List<_Change> _findChanges(SyncSnapshotModel local, SyncSnapshotModel remote) {
    final Map<String, Song> localSongs = <String, Song>{for (final Song song in local.songs) _keyOf(song): song};
    final Map<String, Song> remoteSongs = <String, Song>{for (final Song song in remote.songs) _keyOf(song): song};
    final Map<String, DateTime?> localDeleted = <String, DateTime?>{
      for (final SyncSongKeyModel song in local.deletedSongs) song.key: song.deletedAt,
    };
    final Map<String, DateTime?> remoteDeleted = <String, DateTime?>{
      for (final SyncSongKeyModel song in remote.deletedSongs) song.key: song.deletedAt,
    };
    final List<_Change> here = <_Change>[];
    final List<_Change> there = <_Change>[];

    // Songs.
    for (final MapEntry<String, Song> entry in remoteSongs.entries) {
      final String key = entry.key;
      final Song song = entry.value;
      final Song? mine = localSongs[key];
      final int covers = _coversOf(remote, song.id);
      if (mine == null && localDeleted.containsKey(key)) {
        final _Change delete = _songChange(SyncChangeKind.delete, SyncDirection.toThere, song, key);
        final _Change restore = _songChange(SyncChangeKind.add, SyncDirection.toHere, song, key);
        there.add(delete.withChange(deletedAt: localDeleted[key], excludes: restore.id));
        here.add(restore.withChange(count: covers, restores: true, excludes: delete.id, chosenFirst: false));
      } else if (mine == null) {
        here.add(_songChange(SyncChangeKind.add, SyncDirection.toHere, song, key).withChange(count: covers));
      } else {
        final Set<SongDifference> differences = _differences(mine, song);
        if (differences.isEmpty) continue;
        final _Change take = _songChange(SyncChangeKind.update, SyncDirection.toHere, mine, key, other: song);
        final _Change give = _songChange(SyncChangeKind.update, SyncDirection.toThere, mine, key);
        here.add(take.withChange(differences: differences, excludes: give.id, chosenFirst: false));
        there.add(give.withChange(differences: differences, excludes: take.id, chosenFirst: false));
      }
    }
    for (final MapEntry<String, Song> entry in localSongs.entries) {
      final String key = entry.key;
      final Song song = entry.value;
      if (remoteSongs.containsKey(key)) continue;
      final int covers = _coversOf(local, song.id);
      if (remoteDeleted.containsKey(key)) {
        final _Change delete = _songChange(SyncChangeKind.delete, SyncDirection.toHere, song, key);
        final _Change restore = _songChange(SyncChangeKind.add, SyncDirection.toThere, song, key);
        here.add(delete.withChange(deletedAt: remoteDeleted[key], excludes: restore.id));
        there.add(restore.withChange(count: covers, restores: true, excludes: delete.id, chosenFirst: false));
      } else {
        there.add(_songChange(SyncChangeKind.add, SyncDirection.toThere, song, key).withChange(count: covers));
      }
    }

    // Covers of the songs both devices have.
    void covers(SyncSnapshotModel from, SyncSnapshotModel to, Map<String, Song> songsOfTo, SyncDirection direction) {
      final Map<String, Song> fromById = <String, Song>{for (final Song song in from.songs) song.id: song};
      final Set<String> toCovers = to.recordings.map(_syncRecordingId).toSet();
      final List<_Change> list = direction == SyncDirection.toHere ? here : there;
      final List<_Change> other = direction == SyncDirection.toHere ? there : here;
      final SyncDirection back = direction == SyncDirection.toHere ? SyncDirection.toThere : SyncDirection.toHere;
      for (final SyncRecordingModel cover in from.recordings) {
        final Song? song = fromById[cover.songId];
        if (toCovers.contains(cover.id) || song == null || !songsOfTo.containsKey(_keyOf(song))) continue;
        if (to.deletedCovers.containsKey(cover.id)) {
          final _Change delete = _coverChange(SyncChangeKind.delete, back, cover, song);
          final _Change restore = _coverChange(SyncChangeKind.add, direction, cover, song);
          other.add(delete.withChange(deletedAt: to.deletedCovers[cover.id], excludes: restore.id));
          list.add(restore.withChange(restores: true, excludes: delete.id, chosenFirst: false));
        } else {
          list.add(_coverChange(SyncChangeKind.add, direction, cover, song));
        }
      }
    }

    covers(remote, local, localSongs, SyncDirection.toHere);
    covers(local, remote, remoteSongs, SyncDirection.toThere);

    // Practice sessions.
    final int sessionsToHere = _newSessions(remote, local);
    if (sessionsToHere > 0) here.add(_practiceChange(SyncDirection.toHere, sessionsToHere));
    final int sessionsToThere = _newSessions(local, remote);
    if (sessionsToThere > 0) there.add(_practiceChange(SyncDirection.toThere, sessionsToThere));
    return <_Change>[...here, ...there];
  }

  /// Makes on this device the changes in [chosen] and writes down what the other device must do
  /// and what it must not be sent.
  Future<_Decisions> _decide(_PendingSync pending, Set<String> chosen) async {
    final List<SyncSongKeyModel> deleteThere = <SyncSongKeyModel>[];
    final List<SyncSongKeyModel> forgetThere = <SyncSongKeyModel>[];
    final List<Song> updateThere = <Song>[];
    final List<String> deleteCoversThere = <String>[];
    final List<String> forgetCoversThere = <String>[];
    final _Decisions decisions = _Decisions(
      plan: SyncPlanModel(
        deleteSongs: deleteThere,
        forgetSongs: forgetThere,
        updateSongs: updateThere,
        deleteCovers: deleteCoversThere,
        forgetCovers: forgetCoversThere,
      ),
    );

    for (final _Change item in pending.changes) {
      final SyncChange change = item.change;
      final bool isChosen = chosen.contains(change.id);
      final Song? song = item.song;
      final String? coverId = item.coverId;
      switch ((change.subject, change.kind, change.direction)) {
        case (SyncSubject.song, SyncChangeKind.add, SyncDirection.toHere):
          if (!isChosen) decisions.skipSongs.add(item.songKey!);
        case (SyncSubject.song, SyncChangeKind.add, SyncDirection.toThere):
          if (!isChosen) {
            decisions.skipSongsThere.add(item.songKey!);
          } else if (change.restores) {
            forgetThere.add(_songKey(song!));
          }
        case (SyncSubject.song, SyncChangeKind.delete, SyncDirection.toHere):
          if (isChosen) {
            _throwOnFailure(await _songs.deleteSong(songId: song!.id));
            decisions.deletedHere++;
          }
        case (SyncSubject.song, SyncChangeKind.delete, SyncDirection.toThere):
          if (isChosen) deleteThere.add(_songKey(song!));
        case (SyncSubject.song, SyncChangeKind.update, SyncDirection.toHere):
          if (isChosen) {
            await _updateSong(song!.id, item.otherSong!);
            decisions.updatedHere++;
          }
        case (SyncSubject.song, SyncChangeKind.update, SyncDirection.toThere):
          if (isChosen) updateThere.add(song!);
        case (SyncSubject.cover, SyncChangeKind.add, SyncDirection.toHere):
          if (!isChosen) decisions.skipCovers.add(coverId!);
        case (SyncSubject.cover, SyncChangeKind.add, SyncDirection.toThere):
          if (!isChosen) {
            decisions.skipCoversThere.add(coverId!);
          } else if (change.restores) {
            forgetCoversThere.add(coverId!);
          }
        case (SyncSubject.cover, SyncChangeKind.delete, SyncDirection.toHere):
          if (isChosen) {
            _throwOnFailure(await _recordings.deleteRecording(coverId!));
            decisions.deletedHere++;
          }
        case (SyncSubject.cover, SyncChangeKind.delete, SyncDirection.toThere):
          if (isChosen) deleteCoversThere.add(coverId!);
        case (SyncSubject.practice, _, SyncDirection.toHere):
          if (!isChosen) decisions.skipSessions = true;
        case (SyncSubject.practice, _, SyncDirection.toThere):
          if (!isChosen) decisions.skipSessionsThere = true;
        case (SyncSubject.cover, SyncChangeKind.update, _):
          break; // A cover is never updated.
      }
    }
    return decisions;
  }

  /// [snapshot] without the songs, covers and practice sessions the other device must not get.
  static SyncSnapshotModel _withoutSkipped(SyncSnapshotModel snapshot, _Decisions decisions) {
    final List<Song> songs = <Song>[
      for (final Song song in snapshot.songs)
        if (!decisions.skipSongsThere.contains(_keyOf(song))) song,
    ];
    final Set<String> songIds = songs.map(_songId).toSet();
    return SyncSnapshotModel(
      songs: songs,
      recordings: <SyncRecordingModel>[
        for (final SyncRecordingModel recording in snapshot.recordings)
          if (songIds.contains(recording.songId) && !decisions.skipCoversThere.contains(recording.id)) recording,
      ],
      sessions: decisions.skipSessionsThere
          ? const <PracticeSession>[]
          : <PracticeSession>[
              for (final PracticeSession session in snapshot.sessions)
                if (songIds.contains(session.songId)) session,
            ],
      history: snapshot.history,
      deletedSongs: snapshot.deletedSongs,
      deletedCovers: snapshot.deletedCovers,
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
    for (final LyricsLayout layout in LyricsLayout.values) {
      final double? speed = switch (layout) {
        LyricsLayout.compact => source.scrollSpeed,
        LyricsLayout.wide => source.wideScrollSpeed,
      };
      if (speed != null) {
        _throwOnFailure(await _songs.updateSongScrollSpeed(songId: songId, layout: layout, speed: speed));
      }
      final double? leadIn = switch (layout) {
        LyricsLayout.compact => source.leadIn,
        LyricsLayout.wide => source.wideLeadIn,
      };
      if (leadIn != null) {
        _throwOnFailure(await _songs.updateSongLeadIn(songId: songId, layout: layout, leadIn: leadIn));
      }
    }
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
    bool skipSessions = false,
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
            wideScrollSpeed: song.wideScrollSpeed,
            wideLeadIn: song.wideLeadIn,
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
      for (final PracticeSession session in skipSessions ? const <PracticeSession>[] : remote.sessions)
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

  static _Change _songChange(SyncChangeKind kind, SyncDirection direction, Song song, String key, {Song? other}) =>
      _Change(
        change: SyncChange(
          id: _changeId(kind, direction, SyncSubject.song, key),
          kind: kind,
          direction: direction,
          subject: SyncSubject.song,
          songTitle: _songTitle(song),
        ),
        song: song,
        otherSong: other,
        songKey: key,
      );

  static _Change _coverChange(SyncChangeKind kind, SyncDirection direction, SyncRecordingModel cover, Song song) =>
      _Change(
        change: SyncChange(
          id: _changeId(kind, direction, SyncSubject.cover, cover.id),
          kind: kind,
          direction: direction,
          subject: SyncSubject.cover,
          songTitle: _songTitle(song),
          coverRecordedAt: cover.recordedAt,
        ),
        coverId: cover.id,
      );

  static _Change _practiceChange(SyncDirection direction, int count) => _Change(
    change: SyncChange(
      id: _changeId(SyncChangeKind.add, direction, SyncSubject.practice, _practiceRef),
      kind: SyncChangeKind.add,
      direction: direction,
      subject: SyncSubject.practice,
      count: count,
    ),
  );

  static String _changeId(SyncChangeKind kind, SyncDirection direction, SyncSubject subject, String ref) =>
      '${direction.name}$_idSeparator${kind.name}$_idSeparator${subject.name}$_idSeparator$ref';

  /// The covers of [snapshot] of its song [songId].
  static int _coversOf(SyncSnapshotModel snapshot, String songId) =>
      snapshot.recordings.where((SyncRecordingModel recording) => recording.songId == songId).length;

  /// The practice sessions of [from] that [to] misses.
  static int _newSessions(SyncSnapshotModel from, SyncSnapshotModel to) {
    final Set<String> known = to.sessions.map(_sessionId).toSet();
    return from.sessions.where((PracticeSession session) => !known.contains(session.id)).length;
  }

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

/// A change with what is needed to make it.
final class _Change {
  final SyncChange change;

  /// The song (of this device, or of the other one when it is missing here).
  final Song? song;

  /// The other device's version of a song that is updated here.
  final Song? otherSong;

  /// The key (artist and name) of the song of a song change.
  final String? songKey;

  /// The cover of a cover change.
  final String? coverId;

  const _Change({required this.change, this.song, this.otherSong, this.songKey, this.coverId});

  String get id => change.id;

  /// This change with these details.
  _Change withChange({
    DateTime? deletedAt,
    Set<SongDifference> differences = const <SongDifference>{},
    int count = 0,
    bool restores = false,
    String? excludes,
    bool chosenFirst = true,
  }) => _Change(
    change: SyncChange(
      id: change.id,
      kind: change.kind,
      direction: change.direction,
      subject: change.subject,
      songTitle: change.songTitle,
      coverRecordedAt: change.coverRecordedAt,
      deletedAt: deletedAt,
      differences: differences,
      count: count,
      restores: restores,
      excludes: excludes,
      chosenFirst: chosenFirst,
    ),
    song: song,
    otherSong: otherSong,
    songKey: songKey,
    coverId: coverId,
  );
}

/// An exchange that waits for the user's choices.
final class _PendingSync {
  final Uri base;
  final SyncOfferModel offer;
  final SyncSnapshotModel remote;
  final List<_Change> changes;

  const _PendingSync({required this.base, required this.offer, required this.remote, required this.changes});
}

/// What the choices did here, ask of the other device and leave out.
final class _Decisions {
  final SyncPlanModel plan;

  /// Songs (by key) and covers (by id) of the other device not to take here.
  final Set<String> skipSongs = <String>{};
  final Set<String> skipCovers = <String>{};

  /// Whether the practice sessions of the other device are not taken here.
  bool skipSessions = false;

  /// Songs (by key) and covers (by id) of this device not to send.
  final Set<String> skipSongsThere = <String>{};
  final Set<String> skipCoversThere = <String>{};

  /// Whether the practice sessions of this device are not sent.
  bool skipSessionsThere = false;

  int deletedHere = 0;
  int updatedHere = 0;

  _Decisions({required this.plan});
}

/// What the plan of the other device did here.
final class _Applied {
  final int deleted;
  final int updated;

  const _Applied({required this.deleted, required this.updated});
}
