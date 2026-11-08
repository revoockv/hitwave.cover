import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_form_controller.dart';
import '../di/song_getters.dart';
import '../widgets/song_form_widget.dart';

/// A full page for editing an existing song.
///
/// The fields start with the current song data. Closes after a successful
/// save; on failure stays open and shows the error.
final class EditSongPage extends WatchingWidget {
  /// Title of the page.
  static const String _pageTitle = 'Редагувати пісню';

  /// Label of the save button.
  static const String _saveButtonText = 'Зберегти зміни';

  /// The [Song] to edit.
  final Song song;

  /// Creates a new [EditSongPage].
  const EditSongPage({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final SongFormController controller = createOnce(_createController, dispose: _disposeController);
    registerHandler(target: controller, handler: _onSaveChanged);

    return Scaffold(
      appBar: AppBar(title: const Text(_pageTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: SongFormWidget(controller: controller, submitLabel: _saveButtonText),
        ),
      ),
    );
  }

  SongFormController _createController() => SongFormController(save: _updateSong, song: song);

  static void _disposeController(SongFormController controller) => controller.dispose();

  /// Updates this song with the entered values.
  Future<Result<void>> _updateSong({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) {
    return updateSongUseCase(songId: song.id, author: author, name: name, album: album, lyrics: lyrics);
  }

  /// Closes the page after a save; shows the error of a failed one.
  void _onSaveChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
    switch (state) {
      case SuccessResultState<void>():
        Navigator.of(context).pop();
      case FailureResultState<void>(:final String message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      case IdleResultState<void>() || LoadingResultState<void>():
        break;
    }
  }
}
