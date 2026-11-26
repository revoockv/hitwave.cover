import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/l10n/strings.g.dart';
import 'package:hitwave.cover/features/settings/presentation/l10n/settings_texts.dart';
import 'package:hitwave.cover/features/settings/presentation/widgets/accent_color_picker_widget.dart';
import 'package:hitwave.cover/features/settings/data/models/app_settings_model.dart';
import 'package:hitwave.cover/features/settings/domain/entities/accent_color.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_language.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_settings.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_theme_style.dart';

void main() {
  test('a first start is English, light glass and orange', () {
    expect(AppSettings.initial.language, AppLanguage.english);
    expect(AppSettings.initial.themeStyle, AppThemeStyle.glassLight);
    expect(AppSettings.initial.accentColor, AccentColor.orange);
  });

  test('the settings come back as they were stored', () {
    const AppSettings settings = AppSettings(
      language: AppLanguage.interslavic,
      themeStyle: AppThemeStyle.neumorphicDark,
      accentColor: AccentColor.teal,
    );

    final AppSettings read = AppSettingsModel.fromMap(AppSettingsModel.fromEntity(settings).toMap()).toEntity();

    expect(read.language, AppLanguage.interslavic);
    expect(read.themeStyle, AppThemeStyle.neumorphicDark);
    expect(read.accentColor, AccentColor.teal);
  });

  test('settings stored before the themes, or with unknown values, get the first-start look', () {
    final AppSettings old = AppSettingsModel.fromMap(<String, dynamic>{'language': 'interslavic'}).toEntity();
    final AppSettings unknown = AppSettingsModel.fromMap(<String, dynamic>{
      'language': 'klingon',
      'themeStyle': 'paper',
      'accentColor': 'plaid',
    }).toEntity();

    expect(old.language, AppLanguage.interslavic);
    expect(old.themeStyle, AppThemeStyle.glassLight);
    expect(unknown.language, AppLanguage.english);
    expect(unknown.themeStyle, AppThemeStyle.glassLight);
    expect(unknown.accentColor, AccentColor.orange);
  });

  test('every accent has its own color, a name in both languages and comes back by its name', () {
    final Set<int> colors = <int>{for (final AccentColor accent in AccentColor.values) accent.color.toARGB32()};

    expect(AccentColor.values, hasLength(15));
    expect(colors, hasLength(AccentColor.values.length));
    for (final AppLocale locale in AppLocale.values) {
      final Translations t = locale.buildSync();
      final Set<String> names = <String>{for (final AccentColor accent in AccentColor.values) accent.text(t)};
      expect(names, hasLength(AccentColor.values.length), reason: '$locale');
    }
    for (final AccentColor accent in AccentColor.values) {
      final AppSettings settings = AppSettings.initial.copyWith(accentColor: accent);
      expect(AppSettingsModel.fromMap(AppSettingsModel.fromEntity(settings).toMap()).toEntity().accentColor, accent);
    }
  });
}
