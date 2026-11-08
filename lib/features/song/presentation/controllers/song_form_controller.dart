import 'package:flutter/material.dart';

/// Controller for song form dialogs (add and edit).
///
/// Manages [TextEditingController] instances for the four form fields
/// (author, name, album, lyrics) and an [isLoading] notifier for
/// showing a loading indicator during save operations.
final class SongFormController {
  /// Controller for the author field.
  late TextEditingController authorController;

  /// Controller for the name field.
  late TextEditingController nameController;

  /// Controller for the album field.
  late TextEditingController albumController;

  /// Controller for the lyrics field.
  late TextEditingController lyricsController;

  /// Whether the save operation is in progress.
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Initializes all text controllers with empty values for add mode.
  void init() {
    authorController = TextEditingController();
    nameController = TextEditingController();
    albumController = TextEditingController();
    lyricsController = TextEditingController();
  }

  /// Initializes all text controllers with the given song values for edit mode.
  void initEdit({required String author, required String name, required String? album, required String lyrics}) {
    authorController = TextEditingController(text: author);
    nameController = TextEditingController(text: name);
    albumController = TextEditingController(text: album);
    lyricsController = TextEditingController(text: lyrics);
  }

  /// Disposes all controllers and notifiers.
  void dispose() {
    authorController.dispose();
    nameController.dispose();
    albumController.dispose();
    lyricsController.dispose();
    isLoading.dispose();
  }

  /// Returns the author text.
  String get author => authorController.text.trim();

  /// Returns the name text.
  String get name => nameController.text.trim();

  /// Returns the album text, or null if empty.
  String? get album {
    final String album = albumController.text.trim();
    return album.isEmpty ? null : album;
  }

  /// Returns the lyrics text.
  String get lyrics => lyricsController.text.trim();

  /// Validates that required fields are non-empty.
  bool get isValid => author.isNotEmpty && name.isNotEmpty && lyrics.isNotEmpty;
}
