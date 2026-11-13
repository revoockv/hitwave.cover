import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/accent_color.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_style.dart';
import '../../domain/entities/settings_failure.dart';
import '../di/settings_getters.dart';
import '../l10n/settings_texts.dart';
import '../widgets/accent_color_picker_widget.dart';
import '../widgets/language_picker_widget.dart';
import '../widgets/theme_picker_widget.dart';

/// The app settings: the language, the look and the main color of the app.
final class SettingsPage extends WatchingWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = watch(watchSettingsUseCase()).value;
    final Translations t = context.t;
    final TextStyle? sectionStyle = Theme.of(context).textTheme.titleSmall;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingLarge),
        children: <Widget>[
          ListTile(title: Text(t.settings.theme, style: sectionStyle)),
          ThemePickerWidget(
            selected: settings.themeStyle,
            onSelected: (AppThemeStyle style) => _onThemeStyleSelected(context, style),
          ),
          ListTile(title: Text(t.settings.accentColor, style: sectionStyle)),
          AccentColorPickerWidget(
            selected: settings.accentColor,
            onSelected: (AccentColor color) => _onAccentColorSelected(context, color),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ListTile(title: Text(t.settings.language, style: sectionStyle)),
          LanguagePickerWidget(
            selected: settings.language,
            onSelected: (AppLanguage language) => _onLanguageSelected(context, language),
          ),
        ],
      ),
    );
  }

  Future<void> _onLanguageSelected(BuildContext context, AppLanguage language) =>
      _show(context, setLanguageUseCase(language));

  Future<void> _onThemeStyleSelected(BuildContext context, AppThemeStyle style) =>
      _show(context, setThemeStyleUseCase(style));

  Future<void> _onAccentColorSelected(BuildContext context, AccentColor color) =>
      _show(context, setAccentColorUseCase(color));

  /// Waits for [saving] and shows its failure, if any.
  static Future<void> _show(BuildContext context, Future<Result<void, SettingsFailure>> saving) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Translations t = context.t;
    final Result<void, SettingsFailure> result = await saving;
    if (result case FailureResult<void, SettingsFailure>(:final SettingsFailure failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
    }
  }
}
