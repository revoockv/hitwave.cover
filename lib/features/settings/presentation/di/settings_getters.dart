import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/set_accent_color_use_case.dart';
import '../../domain/use_cases/set_language_use_case.dart';
import '../../domain/use_cases/set_theme_style_use_case.dart';
import '../../domain/use_cases/watch_settings_use_case.dart';

/// The use case that watches the app settings; call it to get the [ValueListenable].
WatchSettingsUseCase get watchSettingsUseCase => di<WatchSettingsUseCase>();

/// The use case that changes the language of the app.
SetLanguageUseCase get setLanguageUseCase => di<SetLanguageUseCase>();

/// The use case that changes the look of the app.
SetThemeStyleUseCase get setThemeStyleUseCase => di<SetThemeStyleUseCase>();

/// The use case that changes the main color of the app.
SetAccentColorUseCase get setAccentColorUseCase => di<SetAccentColorUseCase>();
