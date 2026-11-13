import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';

import '../entities/song.dart';
import '../entities/song_id_change.dart';
import '../entities/song_failure.dart';

/// Defines the contract for song management operations.
///
/// Implementations handle the actual song and cover CRUD operations.
abstract interface class SongRepository {
  /// The current list of songs, sorted by name.
  ///
  /// Changes when songs are added, updated, or deleted.
  ValueListenable<List<Song>> watchSongs();

  /// Adds a new song with the given [author], [name], optional [album], and [lyrics].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the operation fails (network error, permission denied, etc.).
  Future<Result<void, SongFailure>> addSong({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  });

  /// Adds every song of [songs] with its speed and space, but without covers
  /// (used by the import from a backup file).
  ///
  /// Returns the ids of the new songs in the order of [songs], or a failure with an error message.
  Future<Result<List<String>, SongFailure>> addSongs(List<Song> songs);

  /// Emits when a song id stops being valid: the song moved into the account or was deleted.
  Stream<SongIdChange> watchSongIdChanges();

  /// Number of songs left on the device that may be moved into the account
  /// just signed in; `0` when there are none or the user chose to keep them.
  ValueListenable<int> watchLocalSongsToTransfer();

  /// Moves the songs on the device into the signed-in account and deletes
  /// them from the device; songs that failed stay on the device.
  ///
  /// Returns [Result.ok] on success, or a failure with an error message.
  Future<Result<void, SongFailure>> transferLocalSongs();

  /// Keeps the songs on the device and stops offering them until they change.
  ///
  /// Returns [Result.ok] on success, or a failure with an error message.
  Future<Result<void, SongFailure>> keepLocalSongs();

  /// Updates an existing song identified by [songId] with the given [author],
  /// [name], optional [album], and [lyrics].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the song is not found or the update fails.
  Future<Result<void, SongFailure>> updateSong({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  });

  /// Saves the auto-scroll [speed] of the lyrics of the song identified by [songId].
  ///
  /// Returns [Result.ok] on success, or a failure with an error message.
  Future<Result<void, SongFailure>> updateSongScrollSpeed({required String songId, required double speed});

  /// Saves the space above the lyrics ([leadIn], a part of the screen height)
  /// of the song identified by [songId].
  ///
  /// Returns [Result.ok] on success, or a failure with an error message.
  Future<Result<void, SongFailure>> updateSongLeadIn({required String songId, required double leadIn});

  /// Saves the [lyrics] of the song identified by [songId] as typed.
  ///
  /// Returns [Result.ok] on success, or a failure with an error message.
  Future<Result<void, SongFailure>> updateSongLyrics({required String songId, required String lyrics});

  /// Deletes a song identified by [songId] and all its associated covers.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the deletion fails.
  Future<Result<void, SongFailure>> deleteSong({required String songId});

  /// Adds a new cover to the song identified by [songId] with the given
  /// [audioBytes], optional [notes], and current date.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the operation fails.
  Future<Result<void, SongFailure>> addCover({required String songId, required List<int> audioBytes, String? notes});

  /// Updates an existing cover identified by [coverId] on the song [songId]
  /// with the given [audioBytes], optional [notes], and current date.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the cover is not found or the update fails.
  Future<Result<void, SongFailure>> updateCover({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  });

  /// Deletes a cover identified by [coverId] from the song [songId].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the deletion fails.
  Future<Result<void, SongFailure>> deleteCover({required String songId, required String coverId});
}
