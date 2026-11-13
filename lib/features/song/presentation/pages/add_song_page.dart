import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../controllers/song_form_controller.dart';
import '../di/song_getters.dart';
import '../widgets/song_form_widget.dart';
import '../../domain/entities/song_failure.dart';
import '../l10n/song_texts.dart';

/// A full page for adding a new song.
///
/// Opened from an artist's page, the author field starts with that artist ([author]).
///
/// Saves the song itself; closes after a successful save, on failure stays
/// open and shows the error.
final class AddSongPage extends WatchingWidget {
  /// The author the form starts with, or `null` for an empty field.
  final String? author;

  /// Creates a new [AddSongPage].
  const AddSongPage({super.key, this.author});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final SongFormController songFormController = createOnce(
      _createSongFormController,
      dispose: _disposeSongFormController,
    );
    registerHandler(target: songFormController.savingStateController, handler: _onSavingChanged);

    return Scaffold(
      appBar: AppBar(title: Text(t.song.newSong)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: SongFormWidget(
            songFormController: songFormController,
            submitLabel: t.song.addSong,
            onSubmit: () => _onSavePressed(songFormController),
          ),
        ),
      ),
    );
  }

  SongFormController _createSongFormController() => SongFormController(author: author);

  static void _disposeSongFormController(SongFormController songFormController) => songFormController.dispose();

  /// Closes the page after a save; shows the error of a failed one.
  void _onSavingChanged(BuildContext context, ResultState<void, SongFailure> state, void Function() cancel) {
    switch (state) {
      case SuccessResultState<void, SongFailure>():
        Navigator.of(context).pop();
      case FailureResultState<void, SongFailure>(:final SongFailure failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.text(context.t))));
      case IdleResultState<void, SongFailure>() || LoadingResultState<void, SongFailure>():
        break;
    }
  }

  /// Adds the entered song; ignored while a save runs or the form is invalid.
  Future<void> _onSavePressed(SongFormController songFormController) async {
    if (!songFormController.canSave()) return;
    final ValueNotifier<ResultState<void, SongFailure>> savingStateController =
        songFormController.savingStateController;
    savingStateController.value = ResultState.loading;

    final Result<void, SongFailure> result = await addSongUseCase(
      author: songFormController.author,
      name: songFormController.name,
      album: songFormController.album,
      lyrics: songFormController.lyrics,
    );
    if (songFormController.isDisposed) return;

    savingStateController.value = ResultState.of(result);
  }
}
