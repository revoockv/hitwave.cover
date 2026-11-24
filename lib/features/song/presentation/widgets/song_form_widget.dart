import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// The texts of [SongFormWidget].
final class SongFormTexts {
  /// Label of the artist field.
  final String artistLabel;

  /// Label of the song name field.
  final String songNameLabel;

  /// Label of the album field.
  final String albumLabel;

  /// Helper under the album field ("optional").
  final String optionalText;

  /// Label of the lyrics field.
  final String lyricsLabel;

  /// Error of a required field left empty.
  final String requiredText;

  /// Creates the texts.
  const SongFormTexts({
    required this.artistLabel,
    required this.songNameLabel,
    required this.albumLabel,
    required this.optionalText,
    required this.lyricsLabel,
    required this.requiredText,
  });
}

/// Song form shared by the add and edit pages.
///
/// Shows the author, name, album and lyrics fields with inline validation and a submit button pinned to the bottom,
/// with a progress indicator while saving. Dumb: the fields' controllers, the texts and the callback come from above.
final class SongFormWidget extends StatelessWidget {
  /// Visible lines of the lyrics field before it scrolls.
  static const int _lyricsMinLines = 8;

  /// Key of the form, used to validate it.
  final GlobalKey<FormState> formKey;

  /// Text of the artist field.
  final TextEditingController authorController;

  /// Text of the song name field.
  final TextEditingController nameController;

  /// Text of the album field.
  final TextEditingController albumController;

  /// Text of the lyrics field.
  final TextEditingController lyricsController;

  /// Whether the song is being saved; the button shows progress meanwhile.
  final bool isSaving;

  /// The field labels and the validation text.
  final SongFormTexts texts;

  /// Label of the submit button.
  final String submitLabel;

  /// Called when the submit button is pressed.
  final VoidCallback onSubmitPressed;

  /// Creates a new [SongFormWidget].
  const SongFormWidget({
    super.key,
    required this.formKey,
    required this.authorController,
    required this.nameController,
    required this.albumController,
    required this.lyricsController,
    required this.isSaving,
    required this.texts,
    required this.submitLabel,
    required this.onSubmitPressed,
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
                  controller: authorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: texts.artistLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: texts.songNameLabel,
                    prefixIcon: const Icon(Icons.music_note_outlined),
                  ),
                  validator: _validateRequired,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: albumController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: texts.albumLabel,
                    helperText: texts.optionalText,
                    prefixIcon: const Icon(Icons.album_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextFormField(
                  controller: lyricsController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: _lyricsMinLines,
                  maxLines: null,
                  style: const TextStyle(height: AppTheme.readingLineHeight),
                  decoration: InputDecoration(labelText: texts.lyricsLabel, alignLabelWithHint: true),
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
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : onSubmitPressed,
                child: isSaving
                    ? const SizedBox.square(
                        dimension: AppTheme.loadingIndicatorSize,
                        child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
                      )
                    : Text(submitLabel),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _validateRequired(String? value) => value == null || value.trim().isEmpty ? texts.requiredText : null;
}
