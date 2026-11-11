import '../models/cover_model.dart';
import '../models/song_model.dart';
import 'firebase_song_service.dart';
import 'song_data_source.dart';

/// The songs of one signed-in user in Firestore.
final class FirebaseUserSongDataSource implements SongDataSource {
  final FirebaseSongService _service;

  final String _userId;

  /// Creates the songs of the user [userId], stored through [service].
  FirebaseUserSongDataSource({required this._service, required this._userId});

  @override
  Stream<List<SongModel>> watchSongs() => _service.watchSongs(_userId);

  @override
  Future<List<CoverModel>> getCovers(String songId) => _service.getCovers(_userId, songId);

  @override
  Future<String> addSong(SongModel song) => _service.addSong(userId: _userId, song: song);

  @override
  Future<void> updateSong(SongModel song) => _service.updateSong(userId: _userId, song: song);

  @override
  Future<void> updateSongScrollSpeed({required String songId, required double speed}) =>
      _service.updateSongScrollSpeed(userId: _userId, songId: songId, speed: speed);

  @override
  Future<void> updateSongLeadIn({required String songId, required double leadIn}) =>
      _service.updateSongLeadIn(userId: _userId, songId: songId, leadIn: leadIn);

  @override
  Future<void> updateSongLyrics({required String songId, required String lyrics}) =>
      _service.updateSongLyrics(userId: _userId, songId: songId, lyrics: lyrics);

  @override
  Future<void> deleteSong(String songId) => _service.deleteSong(userId: _userId, songId: songId);

  @override
  Future<String> addCover({required String songId, required CoverModel cover}) =>
      _service.addCover(userId: _userId, songId: songId, cover: cover);

  @override
  Future<void> updateCover({required String songId, required CoverModel cover}) =>
      _service.updateCover(userId: _userId, songId: songId, cover: cover);

  @override
  Future<void> deleteCover({required String songId, required String coverId}) =>
      _service.deleteCover(userId: _userId, songId: songId, coverId: coverId);
}
