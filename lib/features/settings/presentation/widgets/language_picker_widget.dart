import 'package:flutter/material.dart';

import '../../domain/entities/app_language.dart';
import '../l10n/settings_texts.dart';

/// The languages of the app as radio buttons; [selected] is marked.
final class LanguagePickerWidget extends StatelessWidget {
  /// The language of the app now.
  final AppLanguage selected;

  /// Called with the language the user picked.
  final ValueChanged<AppLanguage> onSelected;

  /// Creates the picker.
  const LanguagePickerWidget({required this.selected, required this.onSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return RadioGroup<AppLanguage>(
      groupValue: selected,
      onChanged: _onChanged,
      child: Column(
        children: <Widget>[
          for (final AppLanguage language in AppLanguage.values)
            RadioListTile<AppLanguage>(value: language, title: Text(language.nativeName)),
        ],
      ),
    );
  }

  void _onChanged(AppLanguage? language) {
    if (language != null) onSelected(language);
  }
}
