import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song_difference.dart';
import '../../domain/entities/sync_change.dart';
import '../../domain/entities/sync_failure.dart';
import '../../domain/entities/sync_state.dart';
import '../../domain/entities/sync_step.dart';

/// The text of a [SyncFailure] shown to the user.
extension SyncFailureText on SyncFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    SyncFailure.emptyCode => t.sync.failure.emptyCode,
    SyncFailure.notACode => t.sync.failure.notACode,
    SyncFailure.noNetwork => t.sync.failure.noNetwork,
    SyncFailure.host => t.sync.failure.host,
    SyncFailure.busy => t.sync.failure.busy,
    SyncFailure.nothingWaits => t.sync.failure.nothingWaits,
    SyncFailure.connect => t.sync.failure.connect,
    SyncFailure.interrupted => t.sync.failure.interrupted,
    SyncFailure.cancelled => t.sync.failure.cancelled,
    SyncFailure.peerStopped => t.sync.failure.peerStopped,
  };
}

/// The text of a failed sync shown to the user.
extension FailedSyncStateText on FailedSyncState {
  /// What went wrong in the language of [t]; when the other device stopped, which one and why.
  String text(Translations t) {
    final SyncFailure? reason = peerFailure;
    if (failure != SyncFailure.peerStopped || reason == null) return failure.text(t);
    return t.sync.peerStopped(device: peerName ?? t.sync.anotherDevice, reason: reason.text(t));
  }
}

/// The text of a running sync step shown to the user.
extension SyncingSyncStateText on SyncingSyncState {
  /// The step in the language of [t]; a step of the other device names that device.
  String text(Translations t) {
    final String text = switch (step) {
      SyncStep.connecting => t.sync.step.connecting,
      SyncStep.reading => t.sync.step.reading,
      SyncStep.applying => t.sync.step.applying,
      SyncStep.downloading => t.sync.step.downloading(done: done ?? 0, total: total ?? 0),
      SyncStep.uploading => t.sync.step.uploading(done: done ?? 0, total: total ?? 0),
      SyncStep.merging => t.sync.step.merging,
      SyncStep.joined => t.sync.step.joined,
      SyncStep.choosing => t.sync.step.choosing,
    };
    return isPeer ? t.sync.peerStep(device: peerName ?? t.sync.anotherDevice, step: text) : text;
  }
}

/// The title, the detail and the badge of a [SyncChange] shown to the user.
extension SyncChangeText on SyncChange {
  static const String _dateSeparator = '.';
  static const String _timeSeparator = ':';
  static const String _listSeparator = ', ';
  static const String _zero = '0';

  /// What is added, deleted or changed, in the language of [t].
  String title(Translations t) {
    final String song = songTitle ?? t.sync.goneSong;
    final DateTime? recordedAt = coverRecordedAt;
    return switch (subject) {
      SyncSubject.practice => t.sync.practiceItem(n: count),
      SyncSubject.cover when recordedAt != null => t.sync.coverTitle(song: song, date: _date(recordedAt)),
      SyncSubject.song when kind == SyncChangeKind.add && count > 0 =>
        '${t.sync.songItem(song: song)}$_listSeparator${t.sync.withCovers(n: count)}',
      SyncSubject.song || SyncSubject.cover => t.sync.songItem(song: song),
    };
  }

  /// When it was deleted, what differs or that it was deleted, with the other device named
  /// [peer]; `null` when there is nothing to tell.
  String? detail(Translations t, String peer) {
    final DateTime? at = deletedAt;
    if (kind == SyncChangeKind.delete && at != null) {
      final String time = '${_two(at.hour)}$_timeSeparator${_two(at.minute)}';
      return switch (direction) {
        SyncDirection.toThere => t.sync.deletedHereAt(date: _date(at), time: time),
        SyncDirection.toHere => t.sync.deletedThereAtDevice(device: peer, date: _date(at), time: time),
      };
    }
    if (restores) {
      return switch (direction) {
        SyncDirection.toHere => t.sync.restoredHere,
        SyncDirection.toThere => t.sync.restoredThere(device: peer),
      };
    }
    if (kind != SyncChangeKind.update || differences.isEmpty) return null;
    final String list = <String>[
      for (final SongDifference difference in differences)
        switch (difference) {
          SongDifference.lyrics => t.sync.difference.lyrics,
          SongDifference.album => t.sync.difference.album,
        },
    ].join(_listSeparator);
    return switch (direction) {
      SyncDirection.toHere => t.sync.updateHere(list: list, device: peer),
      SyncDirection.toThere => t.sync.updateThere(list: list, device: peer),
    };
  }

  /// The word on the coloured badge: add, bring back, delete or change.
  String badge(Translations t) => switch (kind) {
    SyncChangeKind.add when restores => t.sync.badge.restore,
    SyncChangeKind.add => t.sync.badge.add,
    SyncChangeKind.delete => t.sync.badge.delete,
    SyncChangeKind.update => t.sync.badge.update,
  };

  static String _date(DateTime time) =>
      '${_two(time.day)}$_dateSeparator${_two(time.month)}$_dateSeparator${time.year}';

  static String _two(int part) => part.toString().padLeft(AppTheme.twoDigits, _zero);
}
