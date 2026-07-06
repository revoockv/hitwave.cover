import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../models/cover_model.dart';
import '../models/song_model.dart';


/// Firebase backend implementation of the song management service.
///
/// Wraps the Firebase Firestore and Storage SDKs and provides CRUD operations
/// for songs and covers, organized by the current user's ID.
final class FirebaseSongService {
  final FirebaseFirestore _firestore;
  final firebase_storage.FirebaseStorage _storage;

  /// Creates a new [FirebaseSongService].
  FirebaseSongService({
    required FirebaseFirestore firestore,
    required firebase_storage.FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  /// Returns the Firestore reference for the user's songs collection.
  CollectionReference<Map<String, dynamic>> _songsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('songs');
  }

  /// Returns the Firestore reference for a song's covers subcollection.
  CollectionReference<Map<String, dynamic>> _coversCollection(
    String userId,
    String songId,
  ) {
    return _songsCollection(userId).doc(songId).collection('covers');
  }

  /// Returns the Storage reference for a song's audio files.
  firebase_storage.Reference _songAudioRef(String userId, String songId) {
    return _storage.ref().child('users/$userId/songs/$songId');
  }

  /// Returns the Storage reference for a cover's audio file.
  firebase_storage.Reference _coverAudioRef(String userId, String songId, String coverId) {
    return _storage.ref().child('users/$userId/songs/$songId/covers/$coverId');
  }

  /// Adds a new song document to Firestore and uploads the audio to Storage.
  ///
  /// Returns the document ID of the newly created song.
  /// Throws a [String] error message when the operation fails.
  Future<String> addSong({
    required String userId,
    required SongModel song,
    required Uint8List audioData,
  }) async {
    try {
      final docRef = _songsCollection(userId).doc();
      final songData = <String, dynamic>{
        'id': docRef.id,
        'author': song.author,
        'name': song.name,
        'album': song.album,
        'lyrics': song.lyrics,
        'coverIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(songData);

      await _songAudioRef(userId, docRef.id).putData(audioData);

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
        'author': song.author,
        'name': song.name,
        'album': song.album,
        'lyrics': song.lyrics,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(songData);
    } catch (e) {
      throw 'Помилка при оновленні пісні: $e';
    }
  }

  /// Deletes a song document from Firestore and all its covers from Storage.
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
        await _coverAudioRef(userId, songId, coverDoc.id).delete();
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
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SongModel(
              id: doc.id,
              author: data['author'] as String,
              name: data['name'] as String,
              album: data['album'] as String?,
              lyrics: data['lyrics'] as String,
              coverIds: List<String>.from(data['coverIds'] as List<dynamic>),
            );
          }).toList();
        });
  }

  /// Adds a new cover document to Firestore and uploads the audio to Storage.
  ///
  /// Returns the document ID of the newly created cover.
  /// Throws a [String] error message when the operation fails.
  Future<String> addCover({
    required String userId,
    required String songId,
    required CoverModel cover,
    required Uint8List audioData,
  }) async {
    try {
      final docRef = _coversCollection(userId, songId).doc();
      final coverData = <String, dynamic>{
        'id': docRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'notes': cover.notes,
      };

      await docRef.set(coverData);

      await _coverAudioRef(userId, songId, docRef.id).putData(audioData);

      await _songsCollection(userId).doc(songId).update({
        'coverIds': FieldValue.arrayUnion([docRef.id]),
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
    required Uint8List audioData,
  }) async {
    try {
      final docRef = _coversCollection(userId, songId).doc(cover.id);
      final coverData = <String, dynamic>{
        'timestamp': FieldValue.serverTimestamp(),
        'notes': cover.notes,
      };

      await docRef.update(coverData);

      await _coverAudioRef(userId, songId, cover.id).putData(audioData);
    } catch (e) {
      throw 'Помилка при оновленні обкладинки: $e';
    }
  }

  /// Deletes a cover document from Firestore and its audio from Storage.
  ///
  /// Also removes the cover ID from the parent song's coverIds array.
  /// Throws a [String] error message when the operation fails.
  Future<void> deleteCover({
    required String userId,
    required String songId,
    required String coverId,
  }) async {
    try {
      await _coverAudioRef(userId, songId, coverId).delete();

      final coversRef = _coversCollection(userId, songId).doc(coverId);
      await coversRef.delete();

      await _songsCollection(userId).doc(songId).update({
        'coverIds': FieldValue.arrayRemove([coverId]),
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
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return CoverModel(
              id: doc.id,
              timestamp: (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
              audioBytes: const <int>[],
              notes: data['notes'] as String?,
            );
          }).toList();
        });
  }

  /// Fetches all covers for a specific song as a [Future].
  ///
  /// Returns a list of [CoverModel] sorted by date.
  Future<List<CoverModel>> getCovers(String userId, String songId) async {
    final snapshot = await _coversCollection(userId, songId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CoverModel(
        id: doc.id,
        timestamp: (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
        audioBytes: const <int>[],
        notes: data['notes'] as String?,
      );
    }).toList();
  }
}
