import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song_difference.dart';
import '../../domain/entities/sync_conflict.dart';
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

/// The title and the detail of a [SyncConflict] shown to the user.
extension SyncConflictText on SyncConflict {
  static const String _dateSeparator = '.';
  static const String _timeSeparator = ':';
  static const String _listSeparator = ', ';
  static const String _zero = '0';

  /// The song, or the cover with its song and date, in the language of [t].
  String title(Translations t) {
    final DateTime? recordedAt = coverRecordedAt;
    if (recordedAt == null) return songTitle ?? t.sync.goneSong;
    return t.sync.coverTitle(song: songTitle ?? t.sync.goneSong, date: _date(recordedAt));
  }

  /// When it was deleted, or what differs; `null` when there is nothing to tell.
  String? detail(Translations t) {
    final DateTime? at = deletedAt;
    if (at != null) {
      final String time = '${_two(at.hour)}$_timeSeparator${_two(at.minute)}';
      return switch (kind) {
        SyncConflictKind.songDeletedHere ||
        SyncConflictKind.coverDeletedHere => t.sync.deletedHereAt(date: _date(at), time: time),
        _ => t.sync.deletedThereAt(date: _date(at), time: time),
      };
    }
    if (differences.isEmpty) return null;
    final List<String> names = <String>[
      for (final SongDifference difference in differences)
        switch (difference) {
          SongDifference.lyrics => t.sync.difference.lyrics,
          SongDifference.album => t.sync.difference.album,
        },
    ];
    return t.sync.differs(list: names.join(_listSeparator));
  }

  static String _date(DateTime time) =>
      '${_two(time.day)}$_dateSeparator${_two(time.month)}$_dateSeparator${time.year}';

  static String _two(int part) => part.toString().padLeft(AppTheme.twoDigits, _zero);
}
