import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/theme.dart';
import '../controllers/song_form_controller.dart';

/// Song form shared by the add and edit pages.
///
/// Shows the author, name, album and lyrics fields with inline validation and
/// a submit button pinned to the bottom. Knows nothing about use cases: the
/// button calls [onSubmit], and the page saves the song.
final class SongFormWidget extends StatelessWidget {
  /// Visible lines of the lyrics field before it scrolls.
  static const int _lyricsMinLines = 8;

  /// Label of the author field.
  static const String _authorLabel = 'Виконавець';

  /// Label of the name field.
  static const String _nameLabel = 'Назва пісні';

  /// Label of the album field.
  static const String _albumLabel = 'Альбом';

  /// Helper under the album field.
  static const String _albumHelper = "Необов'язково";

  /// Label of the lyrics field.
  static const String _lyricsLabel = 'Текст пісні';

  /// Error shown under an empty required field.
  static const String _requiredError = 'Заповніть це поле';

  /// Controller holding the fields and the saving progress.
  final SongFormController songFormController;

  /// Label of the submit button.
  final String submitLabel;

  /// Called when the submit button is pressed.
  final VoidCallback onSubmit;

  /// Creates a new [SongFormWidget].
  const SongFormWidget({
    super.key,
    required this.songFormController,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: songFormController.formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: <Widget>[
                TextFormField(
                  controller: songFormController.authorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: _authorLabel, prefixIcon: Icon(Icons.person_outline)),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: songFormController.nameController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: _nameLabel, prefixIcon: Icon(Icons.music_note_outlined)),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: songFormController.albumController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: _albumLabel,
                    helperText: _albumHelper,
                    prefixIcon: Icon(Icons.album_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: songFormController.lyricsController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: _lyricsMinLines,
                  maxLines: null,
                  style: const TextStyle(height: AppTheme.readingLineHeight),
                  decoration: const InputDecoration(labelText: _lyricsLabel, alignLabelWithHint: true),
                  validator: _validateRequired,
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: _SaveButtonWidget(
              savingState: songFormController.savingStateController,
              label: submitLabel,
              onPressed: onSubmit,
            ),
          ),
        ),
      ],
    );
  }

  static String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredError;
    }
    return null;
  }
}

/// Save button that shows progress while the save runs.
final class _SaveButtonWidget extends WatchingWidget {
  /// Progress of saving.
  final ValueListenable<ResultState<void>> savingState;

  /// Label of the button.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_SaveButtonWidget].
  const _SaveButtonWidget({required this.savingState, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = watch(savingState).value.isLoading;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: AppTheme.loadingIndicatorSize,
                child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
              )
            : Text(label),
      ),
    );
  }
}
