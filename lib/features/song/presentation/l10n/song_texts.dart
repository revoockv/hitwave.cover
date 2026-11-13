import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/song_failure.dart';

/// The text of a [SongFailure] shown to the user.
extension SongFailureText on SongFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    SongFailure.notAuthenticated => t.song.failure.notAuthenticated,
    SongFailure.addSong => t.song.failure.addSong,
    SongFailure.addSongs => t.song.failure.addSongs,
    SongFailure.updateSong => t.song.failure.updateSong,
    SongFailure.updateSpeed => t.song.failure.updateSpeed,
    SongFailure.updateLeadIn => t.song.failure.updateLeadIn,
    SongFailure.updateLyrics => t.song.failure.updateLyrics,
    SongFailure.deleteSong => t.song.failure.deleteSong,
    SongFailure.transfer => t.song.failure.transfer,
    SongFailure.keepLocal => t.song.failure.keepLocal,
    SongFailure.addCover => t.song.failure.addCover,
    SongFailure.updateCover => t.song.failure.updateCover,
    SongFailure.deleteCover => t.song.failure.deleteCover,
  };
}
