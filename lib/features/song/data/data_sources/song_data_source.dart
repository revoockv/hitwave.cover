import '../../domain/entities/lyrics_layout.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';

/// Where the songs of the current session are stored: the account
/// ([FirebaseUserSongDataSource]) or this device ([HiveSongService]).
///
/// Every method throws the storage exception when the operation fails.
abstract interface class SongDataSource {
  /// The songs sorted by name; emits again after every change.
  Stream<List<SongModel>> watchSongs();

  /// The covers of the song [songId], newest first.
  Future<List<CoverModel>> getCovers(String songId);

  /// Adds [song] with all its fields and returns the id of the new song.
  Future<String> addSong(SongModel song);

  /// Updates the author, name, album and lyrics of [song].
  Future<void> updateSong(SongModel song);

  /// Saves the auto-scroll [speed] of the song [songId] on [layout].
  Future<void> updateSongScrollSpeed({required String songId, required LyricsLayout layout, required double speed});

  /// Saves the space above the lyrics ([leadIn]) of the song [songId] on [layout].
  Future<void> updateSongLeadIn({required String songId, required LyricsLayout layout, required double leadIn});

  /// Saves the [lyrics] of the song [songId].
  Future<void> updateSongLyrics({required String songId, required String lyrics});

  /// Deletes the song [songId] with its covers.
  Future<void> deleteSong(String songId);

  /// Adds [cover] to the song [songId] and returns the id of the new cover.
  Future<String> addCover({required String songId, required CoverModel cover});

  /// Updates the notes of [cover] of the song [songId].
  Future<void> updateCover({required String songId, required CoverModel cover});

  /// Deletes the cover [coverId] of the song [songId].
  Future<void> deleteCover({required String songId, required String coverId});
}
