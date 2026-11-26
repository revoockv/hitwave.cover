import '../../domain/entities/lyrics_layout.dart';
import 'cover_model.dart';
import 'song_model.dart';

/// A song as it is stored on the device: its fields and its covers in one record.
///
/// The only place that knows the stored keys: [fromStored] reads the raw map Hive returns and [toMap] writes it.
final class SongRecordModel {
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _scrollSpeedField = 'scrollSpeed';
  static const String _leadInField = 'leadIn';
  static const String _wideScrollSpeedField = 'wideScrollSpeed';
  static const String _wideLeadInField = 'wideLeadIn';
  static const String _coversField = 'covers';

  /// The unique identifier of the song.
  final String id;

  /// The author/artist name.
  final String author;

  /// The name/title of the song.
  final String name;

  /// The album name, if the song belongs to one.
  final String? album;

  /// The lyrics.
  final String lyrics;

  /// Saved auto-scroll speed on a phone, or `null` when never set.
  final double? scrollSpeed;

  /// Saved space above the lyrics on a phone, or `null` when never set.
  final double? leadIn;

  /// [scrollSpeed] on a big screen, or `null` when never set there.
  final double? wideScrollSpeed;

  /// [leadIn] on a big screen, or `null` when never set there.
  final double? wideLeadIn;

  /// The covers of the song, in the order they were added.
  final List<CoverModel> covers;

  /// Creates a new [SongRecordModel].
  const SongRecordModel({
    required this.id,
    required this.author,
    required this.name,
    this.album,
    required this.lyrics,
    this.scrollSpeed,
    this.leadIn,
    this.wideScrollSpeed,
    this.wideLeadIn,
    this.covers = const <CoverModel>[],
  });

  /// A new record of [song] under [id], without covers.
  factory SongRecordModel.fromSongModel(SongModel song, {required String id}) => SongRecordModel(
    id: id,
    author: song.author,
    name: song.name,
    album: song.album,
    lyrics: song.lyrics,
    scrollSpeed: song.scrollSpeed,
    leadIn: song.leadIn,
    wideScrollSpeed: song.wideScrollSpeed,
    wideLeadIn: song.wideLeadIn,
  );

  /// Reads the map Hive returned for a song.
  factory SongRecordModel.fromStored(Object? stored) {
    final Map<dynamic, dynamic> map = stored! as Map<dynamic, dynamic>;
    final List<dynamic> covers = map[_coversField] as List<dynamic>? ?? const <dynamic>[];
    return SongRecordModel(
      id: map[_idField] as String,
      author: map[_authorField] as String,
      name: map[_nameField] as String,
      album: map[_albumField] as String?,
      lyrics: map[_lyricsField] as String,
      scrollSpeed: (map[_scrollSpeedField] as num?)?.toDouble(),
      leadIn: (map[_leadInField] as num?)?.toDouble(),
      wideScrollSpeed: (map[_wideScrollSpeedField] as num?)?.toDouble(),
      wideLeadIn: (map[_wideLeadInField] as num?)?.toDouble(),
      covers: covers.map(CoverModel.fromStored).toList(),
    );
  }

  /// The map Hive stores for this song.
  Map<String, dynamic> toMap() => <String, dynamic>{
    _idField: id,
    _authorField: author,
    _nameField: name,
    _albumField: album,
    _lyricsField: lyrics,
    _scrollSpeedField: scrollSpeed,
    _leadInField: leadIn,
    _wideScrollSpeedField: wideScrollSpeed,
    _wideLeadInField: wideLeadIn,
    _coversField: covers.map((CoverModel cover) => cover.toMap()).toList(),
  };

  /// The song without the covers' data, as the rest of the app reads it.
  SongModel toSongModel() => SongModel(
    id: id,
    author: author,
    name: name,
    album: album,
    lyrics: lyrics,
    coverIds: covers.map((CoverModel cover) => cover.id).toList(),
    scrollSpeed: scrollSpeed,
    leadIn: leadIn,
    wideScrollSpeed: wideScrollSpeed,
    wideLeadIn: wideLeadIn,
  );

  /// This record with the author, name, album and lyrics of [song].
  SongRecordModel withDetailsOf(SongModel song) =>
      _copyWith(author: song.author, name: song.name, album: song.album, lyrics: song.lyrics);

  /// This record with [lyrics].
  SongRecordModel withLyrics(String lyrics) => _copyWith(lyrics: lyrics);

  /// This record with the scroll [speed] on [layout].
  SongRecordModel withScrollSpeed(LyricsLayout layout, double speed) => switch (layout) {
    LyricsLayout.compact => _copyWith(scrollSpeed: speed),
    LyricsLayout.wide => _copyWith(wideScrollSpeed: speed),
  };

  /// This record with the space above the lyrics ([leadIn]) on [layout].
  SongRecordModel withLeadIn(LyricsLayout layout, double leadIn) => switch (layout) {
    LyricsLayout.compact => _copyWith(leadIn: leadIn),
    LyricsLayout.wide => _copyWith(wideLeadIn: leadIn),
  };

  /// This record with [covers].
  SongRecordModel withCovers(List<CoverModel> covers) => _copyWith(covers: covers);

  /// The album stays as it is: only [withDetailsOf] changes it, and it may set it to `null`.
  SongRecordModel _copyWith({
    String? author,
    String? name,
    Object? album = _keep,
    String? lyrics,
    double? scrollSpeed,
    double? leadIn,
    double? wideScrollSpeed,
    double? wideLeadIn,
    List<CoverModel>? covers,
  }) => SongRecordModel(
    id: id,
    author: author ?? this.author,
    name: name ?? this.name,
    album: identical(album, _keep) ? this.album : album as String?,
    lyrics: lyrics ?? this.lyrics,
    scrollSpeed: scrollSpeed ?? this.scrollSpeed,
    leadIn: leadIn ?? this.leadIn,
    wideScrollSpeed: wideScrollSpeed ?? this.wideScrollSpeed,
    wideLeadIn: wideLeadIn ?? this.wideLeadIn,
    covers: covers ?? this.covers,
  );

  /// Marks a [_copyWith] argument that was not given.
  static const Object _keep = Object();
}
