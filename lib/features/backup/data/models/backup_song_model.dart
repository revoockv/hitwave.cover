import '../../../song/domain/entities/cover.dart';
import '../../../song/domain/entities/song.dart';

/// One song of a backup file, as it is written in its JSON.
final class BackupSongModel {
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _coverIdsField = 'coverIds';
  static const String _scrollSpeedField = 'scrollSpeed';
  static const String _leadInField = 'leadIn';
  static const String _wideScrollSpeedField = 'wideScrollSpeed';
  static const String _wideLeadInField = 'wideLeadIn';

  /// Id of the song on the device that made the backup.
  final String id;

  /// The author/artist name.
  final String author;

  /// The name/title of the song.
  final String name;

  /// The album name, if the song belongs to one.
  final String? album;

  /// The lyrics.
  final String lyrics;

  /// Ids of the covers of the song on the device that made the backup.
  final List<String> coverIds;

  /// Saved auto-scroll speed on a phone, or `null` when never set.
  final double? scrollSpeed;

  /// Saved space above the lyrics on a phone, or `null` when never set.
  final double? leadIn;

  /// [scrollSpeed] on a big screen, or `null` when never set there.
  final double? wideScrollSpeed;

  /// [leadIn] on a big screen, or `null` when never set there.
  final double? wideLeadIn;

  /// Creates a new [BackupSongModel].
  const BackupSongModel({
    required this.id,
    required this.author,
    required this.name,
    this.album,
    required this.lyrics,
    this.coverIds = const <String>[],
    this.scrollSpeed,
    this.leadIn,
    this.wideScrollSpeed,
    this.wideLeadIn,
  });

  /// The song as it goes into a backup.
  factory BackupSongModel.fromEntity(Song song) => BackupSongModel(
    id: song.id,
    author: song.author,
    name: song.name,
    album: song.album,
    lyrics: song.lyrics,
    coverIds: song.covers.map(_coverId).toList(),
    scrollSpeed: song.scrollSpeed,
    leadIn: song.leadIn,
    wideScrollSpeed: song.wideScrollSpeed,
    wideLeadIn: song.wideLeadIn,
  );

  /// Reads one song of the `songs` list of a backup file.
  factory BackupSongModel.fromJson(Object? json) {
    final Map<dynamic, dynamic> map = json! as Map<dynamic, dynamic>;
    return BackupSongModel(
      id: map[_idField] as String,
      author: map[_authorField] as String,
      name: map[_nameField] as String,
      album: map[_albumField] as String?,
      lyrics: map[_lyricsField] as String,
      coverIds: List<String>.from(map[_coverIdsField] as List<dynamic>? ?? const <dynamic>[]),
      scrollSpeed: (map[_scrollSpeedField] as num?)?.toDouble(),
      leadIn: (map[_leadInField] as num?)?.toDouble(),
      wideScrollSpeed: (map[_wideScrollSpeedField] as num?)?.toDouble(),
      wideLeadIn: (map[_wideLeadInField] as num?)?.toDouble(),
    );
  }

  /// The JSON of the song in a backup file.
  Map<String, dynamic> toJson() => <String, dynamic>{
    _idField: id,
    _authorField: author,
    _nameField: name,
    _albumField: album,
    _lyricsField: lyrics,
    _coverIdsField: coverIds,
    _scrollSpeedField: scrollSpeed,
    _leadInField: leadIn,
    _wideScrollSpeedField: wideScrollSpeed,
    _wideLeadInField: wideLeadIn,
  };

  /// The song to import under [id] (and [name] when given); its covers are not imported.
  Song toImportedSong({required String id, String? name}) => Song(
    id: id,
    author: author,
    name: name ?? this.name,
    album: album,
    lyrics: lyrics,
    covers: const <Cover>[],
    scrollSpeed: scrollSpeed,
    leadIn: leadIn,
    wideScrollSpeed: wideScrollSpeed,
    wideLeadIn: wideLeadIn,
  );

  /// The song as the backup describes it, with its covers by id.
  Song toEntity() => Song(
    id: id,
    author: author,
    name: name,
    album: album,
    lyrics: lyrics,
    covers: coverIds.map(_coverOf).toList(),
    scrollSpeed: scrollSpeed,
    leadIn: leadIn,
    wideScrollSpeed: wideScrollSpeed,
    wideLeadIn: wideLeadIn,
  );

  static String _coverId(Cover cover) => cover.id;

  static Cover _coverOf(String coverId) => Cover(id: coverId, date: DateTime.now(), audioBytes: const <int>[]);
}
