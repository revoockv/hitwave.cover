import 'package:flutter/widgets.dart' show FormState, GlobalKey, TextEditingController, ValueNotifier;

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/song.dart';

/// Saves a song with the entered values; the add or the update action.
typedef SaveSong =
    Future<Result<void>> Function({
      required String author,
      required String name,
      String? album,
      required String lyrics,
    });

/// UI logic of the add and edit song pages: the form fields and one
/// [ResultState] of the save.
///
/// Knows nothing about DI or use cases — the owner passes the save action in.
final class SongFormController extends ValueNotifier<ResultState<void>> {
  /// Key of the form, validated before saving.
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Controller of the author field.
  final TextEditingController author;

  /// Controller of the name field.
  final TextEditingController name;

  /// Controller of the album field.
  final TextEditingController album;

  /// Controller of the lyrics field.
  final TextEditingController lyrics;

  final SaveSong _save;

  bool _isDisposed = false;

  /// Creates the controller; the fields start with the values of [song] when given.
  SongFormController({required this._save, Song? song})
    : author = TextEditingController(text: song?.author),
      name = TextEditingController(text: song?.name),
      album = TextEditingController(text: song?.album),
      lyrics = TextEditingController(text: song?.lyrics),
      super(ResultState.idle);

  /// Saves the song when the form is valid; ignored while a save runs.
  Future<void> save() async {
    if (value.isLoading) return;
    if (formKey.currentState?.validate() != true) return;
    value = ResultState.loading;

    final String albumText = album.text.trim();
    final Result<void> result = await _save(
      author: author.text.trim(),
      name: name.text.trim(),
      album: albumText.isEmpty ? null : albumText,
      lyrics: lyrics.text.trim(),
    );
    if (_isDisposed) return;

    value = ResultState.of(result);
  }

  /// Releases the fields and the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  @override
  void dispose() {
    _isDisposed = true;
    author.dispose();
    name.dispose();
    album.dispose();
    lyrics.dispose();
    super.dispose();
  }
}
