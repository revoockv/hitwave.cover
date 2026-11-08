import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../controllers/song_form_controller.dart';

/// Song form shared by the add and edit pages.
///
/// Shows the author, name, album and lyrics fields with inline validation and
/// a submit button pinned to the bottom. Knows nothing about use cases: it
/// validates the [formKey] and calls [onSubmit].
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

  /// Key of the [Form], validated before [onSubmit].
  final GlobalKey<FormState> formKey;

  /// Label of the submit button.
  final String submitLabel;

  /// Whether the save is in progress.
  final ValueListenable<bool> isLoading;

  /// Called when the form is valid and the user submits it.
  final VoidCallback onSubmit;

  /// Creates a new [SongFormWidget].
  const SongFormWidget({
    required this.controller,
    required this.formKey,
    required this.submitLabel,
    required this.isLoading,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: <Widget>[
                TextFormField(
                  controller: controller.authorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: _authorLabel, prefixIcon: Icon(Icons.person_outline)),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: controller.nameController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: _nameLabel, prefixIcon: Icon(Icons.music_note_outlined)),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: controller.albumController,
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
                  controller: controller.lyricsController,
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
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (BuildContext context, bool loading, Widget? child) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : _onSubmitPressed,
                    child: loading
                        ? const SizedBox.square(
                            dimension: AppTheme.loadingIndicatorSize,
                            child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
                          )
                        : Text(submitLabel),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _onSubmitPressed() {
    final FormState? form = formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    onSubmit();
  }

  static String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredError;
    }
    return null;
  }
}
