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
/// The fields start with the current song data. Saves the song itself; closes
/// after a successful save, on failure stays open and shows the error.
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
    final SongFormController songFormController = createOnce(
      _createSongFormController,
      dispose: _disposeSongFormController,
    );
    registerHandler(target: songFormController.savingStateController, handler: _onSavingChanged);

    return Scaffold(
      appBar: AppBar(title: const Text(_pageTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: SongFormWidget(
            songFormController: songFormController,
            submitLabel: _saveButtonText,
            onSubmit: () => _onSavePressed(songFormController),
          ),
        ),
      ),
    );
  }

  SongFormController _createSongFormController() => SongFormController(song: song);

  static void _disposeSongFormController(SongFormController songFormController) => songFormController.dispose();

  /// Closes the page after a save; shows the error of a failed one.
  void _onSavingChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
    switch (state) {
      case SuccessResultState<void>():
        Navigator.of(context).pop();
      case FailureResultState<void>(:final String message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      case IdleResultState<void>() || LoadingResultState<void>():
        break;
    }
  }

  /// Saves the edited song; ignored while a save runs or the form is invalid.
  Future<void> _onSavePressed(SongFormController songFormController) async {
    if (!songFormController.canSave()) return;
    final ValueNotifier<ResultState<void>> savingStateController = songFormController.savingStateController;
    savingStateController.value = ResultState.loading;

    final Result<void> result = await updateSongUseCase(
      songId: song.id,
      author: songFormController.author,
      name: songFormController.name,
      album: songFormController.album,
      lyrics: songFormController.lyrics,
    );
    if (songFormController.isDisposed) return;

    savingStateController.value = ResultState.of(result);
  }
}
