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
  static const String _scrollSpeedField = 'scrollSpeed';
  static const String _leadInField = 'leadIn';

  final FirebaseFirestore _firestore;

  /// Creates a new [FirebaseSongService].
  FirebaseSongService({required this._firestore});

  /// Returns the Firestore reference for the user's songs collection.
  CollectionReference<Map<String, dynamic>> _songsCollection(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).collection(_songsCollectionName);
  }

  /// Returns the Firestore reference for a song's covers subcollection.
  CollectionReference<Map<String, dynamic>> _coversCollection(String userId, String songId) {
    return _songsCollection(userId).doc(songId).collection(_coversCollectionName);
  }

  /// Adds a new song document to Firestore.
  ///
  /// Returns the document ID of the newly created song.
  /// Throws the Firestore exception when the operation fails.
  Future<String> addSong({required String userId, required SongModel song}) async {
    final docRef = _songsCollection(userId).doc();
    final songData = <String, dynamic>{
      _idField: docRef.id,
      _authorField: song.author,
      _nameField: song.name,
      _albumField: song.album,
      _lyricsField: song.lyrics,
      _coverIdsField: <String>[],
      _scrollSpeedField: song.scrollSpeed,
      _leadInField: song.leadIn,
      _createdAtField: FieldValue.serverTimestamp(),
    };

    await docRef.set(songData);

    return docRef.id;
  }

  /// Updates an existing song document in Firestore.
  ///
  /// Throws the Firestore exception when the operation fails.
  Future<void> updateSong({required String userId, required SongModel song}) async {
    final docRef = _songsCollection(userId).doc(song.id);
    final songData = <String, dynamic>{
      _authorField: song.author,
      _nameField: song.name,
      _albumField: song.album,
      _lyricsField: song.lyrics,
      _updatedAtField: FieldValue.serverTimestamp(),
    };

    await docRef.update(songData);
  }

  /// Saves the auto-scroll [speed] of a song without touching its other fields.
  ///
  /// Throws the Firestore exception when the operation fails.
  Future<void> updateSongScrollSpeed({required String userId, required String songId, required double speed}) async {
    await _songsCollection(
      userId,
    ).doc(songId).update(<String, dynamic>{_scrollSpeedField: speed, _updatedAtField: FieldValue.serverTimestamp()});
  }

  /// Saves the space above the lyrics ([leadIn]) of a song without touching its other fields.
  ///
  /// Throws the Firestore exception when the operation fails.
  Future<void> updateSongLeadIn({required String userId, required String songId, required double leadIn}) async {
    await _songsCollection(
      userId,
    ).doc(songId).update(<String, dynamic>{_leadInField: leadIn, _updatedAtField: FieldValue.serverTimestamp()});
  }

  /// Saves the [lyrics] of a song without touching its other fields.
  ///
  /// Throws the Firestore exception when the operation fails.
  Future<void> updateSongLyrics({required String userId, required String songId, required String lyrics}) async {
    await _songsCollection(
      userId,
    ).doc(songId).update(<String, dynamic>{_lyricsField: lyrics, _updatedAtField: FieldValue.serverTimestamp()});
  }

  /// Deletes a song document from Firestore and all its covers.
  ///
  /// Throws the Firestore exception when the operation fails.
  Future<void> deleteSong({required String userId, required String songId}) async {
    final songDocRef = _songsCollection(userId).doc(songId);
    final coversSnapshot = await _coversCollection(userId, songId).get();

    for (final coverDoc in coversSnapshot.docs) {
      await coverDoc.reference.delete();
    }

    await songDocRef.delete();
  }

  /// Watches all songs for a user as a Stream of [SongModel].
  ///
  /// Emits a list of [SongModel] sorted by song name whenever any song
  /// changes (add, update, delete).
  Stream<List<SongModel>> watchSongs(String userId) {
    return _songsCollection(userId).orderBy(_nameField).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SongModel(
          id: doc.id,
          author: data[_authorField] as String,
          name: data[_nameField] as String,
          album: data[_albumField] as String?,
          lyrics: data[_lyricsField] as String,
          coverIds: List<String>.from(data[_coverIdsField] as List<dynamic>),
          scrollSpeed: (data[_scrollSpeedField] as num?)?.toDouble(),
          leadIn: (data[_leadInField] as num?)?.toDouble(),
        );
      }).toList();
    });
  }

  /// Adds a new cover document to Firestore.
  ///
  /// Returns the document ID of the newly created cover.
  /// Throws the Firestore exception when the operation fails.
  Future<String> addCover({required String userId, required String songId, required CoverModel cover}) async {
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
  }

  /// Updates an existing cover document in Firestore.
  ///
  /// Throws the Firestore exception when the operation fails.
  Future<void> updateCover({required String userId, required String songId, required CoverModel cover}) async {
    final docRef = _coversCollection(userId, songId).doc(cover.id);
    final coverData = <String, dynamic>{_timestampField: FieldValue.serverTimestamp(), _notesField: cover.notes};

    await docRef.update(coverData);
  }

  /// Deletes a cover document from Firestore.
  ///
  /// Also removes the cover ID from the parent song's coverIds array.
  /// Throws the Firestore exception when the operation fails.
  Future<void> deleteCover({required String userId, required String songId, required String coverId}) async {
    final coversRef = _coversCollection(userId, songId).doc(coverId);
    await coversRef.delete();

    await _songsCollection(userId).doc(songId).update({
      _coverIdsField: FieldValue.arrayRemove([coverId]),
    });
  }

  /// Watches all covers for a specific song as a Stream of [CoverModel].
  ///
  /// Emits a list of [CoverModel] sorted by date whenever any cover
  /// changes (add, update, delete).
  Stream<List<CoverModel>> watchCovers(String userId, String songId) {
    return _coversCollection(userId, songId).orderBy(_timestampField, descending: true).snapshots().map((snapshot) {
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
    final snapshot = await _coversCollection(userId, songId).orderBy(_timestampField, descending: true).get();

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
