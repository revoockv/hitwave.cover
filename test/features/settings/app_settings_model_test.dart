import 'package:flutter_test/flutter_test.dart';
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
      'accentColor': 'gold',
    }).toEntity();

    expect(old.language, AppLanguage.interslavic);
    expect(old.themeStyle, AppThemeStyle.glassLight);
    expect(unknown.language, AppLanguage.english);
    expect(unknown.themeStyle, AppThemeStyle.glassLight);
    expect(unknown.accentColor, AccentColor.orange);
  });
}
