/// A song as both devices recognise it: by artist and name (ignoring case and outer spaces).
final class SyncSongKeyModel {
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _separator = '\u0000';

  /// Artist.
  final String author;

  /// Name.
  final String name;

  /// Creates a [SyncSongKeyModel].
  const SyncSongKeyModel({required this.author, required this.name});

  /// Reads the JSON of another device or of the store.
  factory SyncSongKeyModel.fromJson(Map<dynamic, dynamic> json) =>
      SyncSongKeyModel(author: json[_authorField] as String, name: json[_nameField] as String);

  /// The JSON form.
  Map<String, dynamic> toJson() => <String, dynamic>{_authorField: author, _nameField: name};

  /// The text two songs are matched by.
  String get key => keyOf(author: author, name: name);

  /// The text a song with [author] and [name] is matched by.
  static String keyOf({required String author, required String name}) =>
      '${author.trim().toLowerCase()}$_separator${name.trim().toLowerCase()}';
}
