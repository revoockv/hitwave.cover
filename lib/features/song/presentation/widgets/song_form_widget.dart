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
/// button calls [SongFormController.save], which validates the form first.
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

  /// Controller holding the field values.
  final SongFormController controller;

  /// Label of the submit button.
  final String submitLabel;

  /// Creates a new [SongFormWidget].
  const SongFormWidget({required this.controller, required this.submitLabel, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: controller.formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: <Widget>[
                TextFormField(
                  controller: controller.author,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: _authorLabel, prefixIcon: Icon(Icons.person_outline)),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: controller.name,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: _nameLabel, prefixIcon: Icon(Icons.music_note_outlined)),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: controller.album,
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
                  controller: controller.lyrics,
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
            child: _SaveButtonWidget(state: controller, label: submitLabel, onPressed: controller.save),
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
  /// State of the save.
  final ValueListenable<ResultState<void>> state;

  /// Label of the button.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_SaveButtonWidget].
  const _SaveButtonWidget({required this.state, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = watch(state).value.isLoading;

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
