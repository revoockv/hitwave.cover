import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cover_model.dart';
import '../models/song_model.dart';

/// Firebase backend implementation of the song management service.
///
/// Wraps the Firebase Firestore SDK and provides CRUD operations for songs
/// and covers, organized by the current user's ID.
final class FirebaseSongService {
  static const String _usersCollection = 'users';
  static const String _songsCollectionName = 'songs';
  static const String _coversCollectionName = 'covers';
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _coverIdsField = 'coverIds';
  static const String _createdAtField = 'createdAt';
  static const String _updatedAtField = 'updatedAt';
  static const String _timestampField = 'timestamp';
  static const String _notesField = 'notes';

  final FirebaseFirestore _firestore;

  /// Creates a new [FirebaseSongService].
  FirebaseSongService({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Returns the Firestore reference for the user's songs collection.
  CollectionReference<Map<String, dynamic>> _songsCollection(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).collection(_songsCollectionName);
  }

  /// Returns the Firestore reference for a song's covers subcollection.
  CollectionReference<Map<String, dynamic>> _coversCollection(
    String userId,
    String songId,
  ) {
    return _songsCollection(userId).doc(songId).collection(_coversCollectionName);
  }

  /// Adds a new song document to Firestore.
  ///
  /// Returns the document ID of the newly created song.
  /// Throws a [String] error message when the operation fails.
  Future<String> addSong({
    required String userId,
    required SongModel song,
  }) async {
    try {
      final docRef = _songsCollection(userId).doc();
      final songData = <String, dynamic>{
        _idField: docRef.id,
        _authorField: song.author,
        _nameField: song.name,
        _albumField: song.album,
        _lyricsField: song.lyrics,
        _coverIdsField: <String>[],
        _createdAtField: FieldValue.serverTimestamp(),
      };

      await docRef.set(songData);

      return docRef.id;
    } catch (e) {
      throw 'Помилка при створенні пісні: $e';
    }
  }

  /// Updates an existing song document in Firestore.
  ///
  /// Throws a [String] error message when the operation fails.
  Future<void> updateSong({
    required String userId,
    required SongModel song,
  }) async {
    try {
      final docRef = _songsCollection(userId).doc(song.id);
      final songData = <String, dynamic>{
        _authorField: song.author,
        _nameField: song.name,
        _albumField: song.album,
        _lyricsField: song.lyrics,
        _updatedAtField: FieldValue.serverTimestamp(),
      };

      await docRef.update(songData);
    } catch (e) {
      throw 'Помилка при оновленні пісні: $e';
    }
  }

  /// Deletes a song document from Firestore and all its covers.
  ///
  /// Throws a [String] error message when the operation fails.
  Future<void> deleteSong({
    required String userId,
    required String songId,
  }) async {
    try {
      final songDocRef = _songsCollection(userId).doc(songId);
      final coversSnapshot = await _coversCollection(userId, songId).get();

      for (final coverDoc in coversSnapshot.docs) {
        await coverDoc.reference.delete();
      }

      await songDocRef.delete();
    } catch (e) {
      throw 'Помилка при видаленні пісні: $e';
    }
  }

  /// Watches all songs for a user as a Stream of [SongModel].
  ///
  /// Emits a list of [SongModel] sorted by song name whenever any song
  /// changes (add, update, delete).
  Stream<List<SongModel>> watchSongs(String userId) {
    return _songsCollection(userId)
        .orderBy(_nameField)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SongModel(
              id: doc.id,
              author: data[_authorField] as String,
              name: data[_nameField] as String,
              album: data[_albumField] as String?,
              lyrics: data[_lyricsField] as String,
              coverIds: List<String>.from(data[_coverIdsField] as List<dynamic>),
            );
          }).toList();
        });
  }

  /// Adds a new cover document to Firestore.
  ///
  /// Returns the document ID of the newly created cover.
  /// Throws a [String] error message when the operation fails.
  Future<String> addCover({
    required String userId,
    required String songId,
    required CoverModel cover,
  }) async {
    try {
      final docRef = _coversCollection(userId, songId).doc();
      final coverData = <String, dynamic>{
        _idField: docRef.id,
        _timestampField: FieldValue.serverTimestamp(),
        _notesField: cover.notes,
      };

      await docRef.set(coverData);

      await _songsCollection(userId).doc(songId).update({
        _coverIdsField: FieldValue.arrayUnion([docRef.id]),
      });

      return docRef.id;
    } catch (e) {
      throw 'Помилка при створенні обкладинки: $e';
    }
  }

  /// Updates an existing cover document in Firestore.
  ///
  /// Throws a [String] error message when the operation fails.
  Future<void> updateCover({
    required String userId,
    required String songId,
    required CoverModel cover,
  }) async {
    try {
      final docRef = _coversCollection(userId, songId).doc(cover.id);
      final coverData = <String, dynamic>{
        _timestampField: FieldValue.serverTimestamp(),
        _notesField: cover.notes,
      };

      await docRef.update(coverData);
    } catch (e) {
      throw 'Помилка при оновленні обкладинки: $e';
    }
  }

  /// Deletes a cover document from Firestore.
  ///
  /// Also removes the cover ID from the parent song's coverIds array.
  /// Throws a [String] error message when the operation fails.
  Future<void> deleteCover({
    required String userId,
    required String songId,
    required String coverId,
  }) async {
    try {
      final coversRef = _coversCollection(userId, songId).doc(coverId);
      await coversRef.delete();

      await _songsCollection(userId).doc(songId).update({
        _coverIdsField: FieldValue.arrayRemove([coverId]),
      });
    } catch (e) {
      throw 'Помилка при видаленні обкладинки: $e';
    }
  }

  /// Watches all covers for a specific song as a Stream of [CoverModel].
  ///
  /// Emits a list of [CoverModel] sorted by date whenever any cover
  /// changes (add, update, delete).
  Stream<List<CoverModel>> watchCovers(String userId, String songId) {
    return _coversCollection(userId, songId)
        .orderBy(_timestampField, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return CoverModel(
              id: doc.id,
              timestamp: (data[_timestampField] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
              audioBytes: const <int>[],
              notes: data[_notesField] as String?,
            );
          }).toList();
        });
  }

  /// Fetches all covers for a specific song as a [Future].
  ///
  /// Returns a list of [CoverModel] sorted by date.
  Future<List<CoverModel>> getCovers(String userId, String songId) async {
    final snapshot = await _coversCollection(userId, songId)
        .orderBy(_timestampField, descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CoverModel(
        id: doc.id,
        timestamp: (data[_timestampField] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
        audioBytes: const <int>[],
        notes: data[_notesField] as String?,
      );
    }).toList();
  }
}
