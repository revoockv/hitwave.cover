import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/song_failure.dart';
import '../controllers/song_form_controller.dart';
import '../widgets/song_form_widget.dart';

/// Gives [SongFormWidget] the fields of the page's [SongFormController] and whether the song is being saved:
/// rebuilds only when saving starts or ends.
final class SongFormWrapper extends WatchingWidget {
  /// The fields and the saving progress, owned by the page.
  final SongFormController songFormController;

  /// The field labels and the validation text.
  final SongFormTexts texts;

  /// Label of the submit button.
  final String submitLabel;

  /// Called when the submit button is pressed; the page saves the song.
  final VoidCallback onSubmitPressed;

  /// Creates the wrapper.
  const SongFormWrapper({
    required this.songFormController,
    required this.texts,
    required this.submitLabel,
    required this.onSubmitPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSaving = watchPropertyValue(_isSavingOf, target: songFormController.savingStateController);
    return SongFormWidget(
      formKey: songFormController.formKey,
      authorController: songFormController.authorController,
      nameController: songFormController.nameController,
      albumController: songFormController.albumController,
      lyricsController: songFormController.lyricsController,
      isSaving: isSaving,
      texts: texts,
      submitLabel: submitLabel,
      onSubmitPressed: onSubmitPressed,
    );
  }

  static bool _isSavingOf(ValueListenable<ResultState<void, SongFailure>> state) => state.value.isLoading;
}
