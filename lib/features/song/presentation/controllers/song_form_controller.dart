import 'package:flutter/widgets.dart' show FormState, GlobalKey, TextEditingController, ValueNotifier;

import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/song.dart';

/// UI state of the add and edit song pages, like a Flutter controller: the form
/// fields and the progress of saving.
///
/// Knows nothing about use cases: the page calls them and records the outcome
/// in [savingStateController].
final class SongFormController {
  /// Key of the form, validated before saving.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Text of the author field.
  final TextEditingController authorController;

  /// Text of the name field.
  final TextEditingController nameController;

  /// Text of the album field.
  final TextEditingController albumController;

  /// Text of the lyrics field.
  final TextEditingController lyricsController;

  /// Progress of saving the song; the save button is disabled while it runs.
  final ValueNotifier<ResultState<void>> savingStateController = ValueNotifier<ResultState<void>>(ResultState.idle);

  bool _isDisposed = false;

  /// Creates the controller; the fields start with the values of [song] when given, the author
  /// field of a new song with [author] (the artist whose page is open).
  SongFormController({Song? song, String? author})
    : authorController = TextEditingController(text: song?.author ?? author),
      nameController = TextEditingController(text: song?.name),
      albumController = TextEditingController(text: song?.album),
      lyricsController = TextEditingController(text: song?.lyrics);

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Entered author without surrounding spaces.
  String get author => authorController.text.trim();

  /// Entered name without surrounding spaces.
  String get name => nameController.text.trim();

  /// Entered album, or `null` when the field is empty.
  String? get album {
    final String text = albumController.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Entered lyrics without surrounding spaces.
  String get lyrics => lyricsController.text.trim();

  /// Whether a save may start: none is running and every required field is filled.
  bool canSave() => !savingStateController.value.isLoading && formKey.currentState?.validate() == true;

  /// Releases the fields and the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    _isDisposed = true;
    authorController.dispose();
    nameController.dispose();
    albumController.dispose();
    lyricsController.dispose();
    savingStateController.dispose();
  }
}
