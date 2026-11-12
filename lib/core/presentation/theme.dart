import 'package:flutter/material.dart';

/// Values shared by more than one feature: spacing, sizes, colors and the
/// app [ThemeData] for light and dark mode.
///
/// A value used by a single widget stays a private `static const` of that widget.
final class AppTheme {
  /// Tiny gap between closely related elements.
  static const double spacingTiny = 6;

  /// Small gap between related elements.
  static const double spacingSmall = 8;

  /// Default padding of screens and cards.
  static const double spacingMedium = 16;

  /// Large gap between sections and around full-screen text.
  static const double spacingLarge = 24;

  /// Extra large gap above a screen's main content.
  static const double spacingExtraLarge = 48;

  /// Size of the small progress indicator inside buttons.
  static const double loadingIndicatorSize = 20;

  /// Stroke width of the small progress indicator inside buttons.
  static const double loadingIndicatorStroke = 2;

  /// Corner radius of fields, buttons, cards and chips.
  static const double radius = 12;

  /// Corner radius of large surfaces: panels and dialogs.
  static const double radiusLarge = 20;

  /// Minimum height of buttons — a comfortable touch target.
  static const double buttonHeight = 52;

  /// Largest width of forms and reading content on wide screens.
  static const double maxContentWidth = 560;

  /// Line height of lyrics and other long text.
  static const double readingLineHeight = 1.5;

  /// Seconds in a minute, for the `m:ss` times of recordings.
  static const int secondsPerMinute = 60;

  /// Digits of a two-digit date or time part ("05").
  static const int twoDigits = 2;

  /// Seed color of the app color scheme (deep indigo).
  static const Color seedColor = Color(0xFF4338CA);

  /// Light theme of the app.
  static ThemeData light() => _build(Brightness.light);

  /// Dark theme of the app.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    final RoundedRectangleBorder shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    const Size buttonSize = Size(0, buttonHeight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: colorScheme.primary, width: loadingIndicatorStroke),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: colorScheme.error, width: loadingIndicatorStroke),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: buttonSize, shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      chipTheme: ChipThemeData(shape: shape),
      cardTheme: CardThemeData(shape: shape, clipBehavior: Clip.antiAlias, margin: EdgeInsets.zero),
      listTileTheme: ListTileThemeData(shape: shape),
      dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: shape),
    );
  }

  const AppTheme._();
}
