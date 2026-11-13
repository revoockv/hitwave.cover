import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/settings_failure.dart';
import '../di/settings_getters.dart';
import '../l10n/settings_texts.dart';
import '../widgets/language_picker_widget.dart';

/// The app settings: the language of the app.
final class SettingsPage extends WatchingWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = watch(watchSettingsUseCase()).value;
    final Translations t = context.t;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        children: <Widget>[
          ListTile(title: Text(t.settings.language, style: Theme.of(context).textTheme.titleSmall)),
          LanguagePickerWidget(
            selected: settings.language,
            onSelected: (AppLanguage language) => _onLanguageSelected(context, language),
          ),
        ],
      ),
    );
  }

  Future<void> _onLanguageSelected(BuildContext context, AppLanguage language) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Translations t = context.t;
    final Result<void, SettingsFailure> result = await setLanguageUseCase(language);
    result.when(success: _ignore, failure: (SettingsFailure failure) => _showFailure(messenger, t, failure));
  }

  static void _ignore(void _) {}

  static void _showFailure(ScaffoldMessengerState messenger, Translations t, SettingsFailure failure) {
    messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
  }
}
