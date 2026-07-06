import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../../core/domain/result.dart';

import '../entities/song.dart';

/// Defines the contract for song management operations.
///
/// Implementations handle the actual song and cover CRUD operations.
abstract interface class SongRepository {
  /// Returns a [ValueNotifier] containing the current list of songs.
  ///
  /// Songs are sorted by name. This is exposed as a [ValueNotifier] so the
  /// UI can reactively watch changes when songs are added, updated, or deleted.
  ValueNotifier<List<Song>> get songs;

  /// Adds a new song with the given [author], [name], optional [album], and [lyrics].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the operation fails (network error, permission denied, etc.).
  Future<Result<void>> addSong({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  });

  /// Updates an existing song identified by [songId] with the given [author],
  /// [name], optional [album], and [lyrics].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the song is not found or the update fails.
  Future<Result<void>> updateSong({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  });

  /// Deletes a song identified by [songId] and all its associated covers.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the deletion fails.
  Future<Result<void>> deleteSong({
    required String songId,
  });

  /// Adds a new cover to the song identified by [songId] with the given
  /// [audioBytes], optional [notes], and current date.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the operation fails.
  Future<Result<void>> addCover({
    required String songId,
    required List<int> audioBytes,
    String? notes,
  });

  /// Updates an existing cover identified by [coverId] on the song [songId]
  /// with the given [audioBytes], optional [notes], and current date.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the cover is not found or the update fails.
  Future<Result<void>> updateCover({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  });

  /// Deletes a cover identified by [coverId] from the song [songId].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when the deletion fails.
  Future<Result<void>> deleteCover({
    required String songId,
    required String coverId,
  });

  /// Initializes the repository and starts listening for song changes.
  ///
  /// Must be called once at app startup via [runAppInitiations].
  /// Subscribes to underlying data source changes and updates the [songs] ValueNotifier.
  Future<void> init();
}
