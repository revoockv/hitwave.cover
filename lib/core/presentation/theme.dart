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

  /// Widest a page of several columns grows (the home dashboard on a desktop).
  static const double maxPageWidth = 1080;

  /// From this window width on the tabs are a rail on the left instead of a bar at the bottom.
  static const double railBreakpoint = 840;

  /// From this content width on the home dashboard has two columns.
  static const double twoColumnBreakpoint = 900;

  /// Padding that keeps content of [maxWidth] in the middle of [width], at least [minimum] wide.
  static EdgeInsets centeredPadding(double width, double maxWidth, {double minimum = spacingMedium}) {
    final double side = width > maxWidth + 2 * minimum ? (width - maxWidth) / 2 : minimum;
    return EdgeInsets.symmetric(horizontal: side, vertical: minimum);
  }

  /// Line height of lyrics and other long text.
  static const double readingLineHeight = 1.5;

  /// Seconds in a minute, for the `m:ss` times of recordings.
  static const int secondsPerMinute = 60;

  /// Digits of a two-digit date or time part ("05").
  static const int twoDigits = 2;

  /// Accent colors the user can choose from.
  static const Color accentOrange = Color(0xFFF97316);

  /// Neon blue accent.
  static const Color accentBlue = Color(0xFF3B9EFF);

  /// Indigo accent.
  static const Color accentIndigo = Color(0xFF6366F1);

  /// Violet accent.
  static const Color accentViolet = Color(0xFFA855F7);

  /// Pink accent.
  static const Color accentPink = Color(0xFFEC4899);

  /// Red accent.
  static const Color accentRed = Color(0xFFEF4444);

  /// Green accent.
  static const Color accentGreen = Color(0xFF22C55E);

  /// Teal accent.
  static const Color accentTeal = Color(0xFF14B8A6);

  /// The theme of [style] in [brightness] with [accent] as the main color.
  static ThemeData build({required SurfaceStyle style, required Brightness brightness, required Color accent}) {
    final SurfaceTheme surfaces = SurfaceTheme.forStyle(style, brightness, accent);
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: accent,
          onPrimary: onColor(accent),
          surface: surfaces.solid,
          surfaceContainerLowest: surfaces.solid,
          surfaceContainerLow: surfaces.solid,
          surfaceContainer: surfaces.solid,
          surfaceContainerHigh: surfaces.field,
          surfaceContainerHighest: surfaces.field,
          onSurface: brightness == Brightness.dark ? _lightOnSurface : _darkOnSurface,
          onSurfaceVariant: brightness == Brightness.dark ? _lightOnSurfaceVariant : _darkOnSurfaceVariant,
        );
    final double buttonElevation = style == SurfaceStyle.neumorphic ? _neumorphicButtonElevation : 0;
    final RoundedRectangleBorder shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final RoundedRectangleBorder largeShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge));
    const Size buttonSize = Size(0, buttonHeight);
    final OutlineInputBorder noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[surfaces],
      scaffoldBackgroundColor: _transparent,
      canvasColor: surfaces.solid,
      appBarTheme: const AppBarTheme(
        backgroundColor: _transparent,
        surfaceTintColor: _transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.panel,
        surfaceTintColor: _transparent,
        elevation: 0,
        indicatorColor: accent.withValues(alpha: _indicatorAlpha),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaces.panel,
        elevation: 0,
        indicatorColor: accent.withValues(alpha: _indicatorAlpha),
        labelType: NavigationRailLabelType.all,
        groupAlignment: -1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.field,
        border: noBorder,
        enabledBorder: noBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: accent, width: loadingIndicatorStroke),
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
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
          backgroundColor: accent,
          foregroundColor: onColor(accent),
          elevation: style == SurfaceStyle.glass ? _glassButtonElevation : buttonElevation,
          shadowColor: style == SurfaceStyle.glass ? accent : surfaces.shade,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: shape,
          backgroundColor: surfaces.panel,
          side: BorderSide(color: surfaces.border),
          elevation: buttonElevation,
          shadowColor: surfaces.shade,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: largeShape,
        backgroundColor: accent,
        foregroundColor: onColor(accent),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      chipTheme: ChipThemeData(
        shape: shape,
        backgroundColor: surfaces.panel,
        side: BorderSide(color: surfaces.border),
      ),
      cardTheme: CardThemeData(
        shape: shape,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: surfaces.panel,
        elevation: 0,
        surfaceTintColor: _transparent,
      ),
      listTileTheme: ListTileThemeData(shape: shape),
      dialogTheme: DialogThemeData(shape: largeShape, backgroundColor: surfaces.solid),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surfaces.solid, surfaceTintColor: _transparent),
      popupMenuTheme: PopupMenuThemeData(color: surfaces.solid, shape: shape),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: shape),
      dividerTheme: DividerThemeData(color: surfaces.border),
    );
  }

  static const Color _transparent = Color(0x00000000);
  static const Color _darkText = Color(0xFF111318);
  static const Color _lightText = Color(0xFFFFFFFF);
  static const double _indicatorAlpha = 0.22;
  static const double _neumorphicButtonElevation = 4;
  static const double _glassButtonElevation = 6;
  static const Color _darkOnSurface = Color(0xFF1C2028);
  static const Color _darkOnSurfaceVariant = Color(0xFF555C6B);
  static const Color _lightOnSurface = Color(0xFFE7E9EE);
  static const Color _lightOnSurfaceVariant = Color(0xFFA3A9B5);

  /// Black or white, whichever reads better on [color].
  static Color onColor(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? _lightText : _darkText;

  const AppTheme._();
}

/// How surfaces look: frosted glass over a blurred background, or soft neumorphic relief.
enum SurfaceStyle {
  /// Translucent panels that blur what is behind them.
  glass,

  /// Panels of the background color raised by a light and a dark shadow.
  neumorphic,
}

/// Colors of the surfaces of a [SurfaceStyle]; read with `Theme.of(context).extension<SurfaceTheme>()`.
final class SurfaceTheme extends ThemeExtension<SurfaceTheme> {
  // Glass, light.
  static const Color _glassLightTop = Color(0xFFF1F2F6);
  static const Color _glassLightBottom = Color(0xFFDCDFE8);
  static const Color _glassLightPanel = Color(0x8CFFFFFF);
  static const Color _glassLightBorder = Color(0xB3FFFFFF);
  static const Color _glassLightField = Color(0x99FFFFFF);
  static const Color _glassLightSolid = Color(0xFFF6F7FA);
  static const Color _glassLightMiddle = Color(0xFFE3E5F0);
  static const Color _glassLightShadow = Color(0x1F2A3050);

  // Glass, dark.
  static const Color _glassDarkTop = Color(0xFF151821);
  static const Color _glassDarkBottom = Color(0xFF0D0F14);
  static const Color _glassDarkPanel = Color(0x14FFFFFF);
  static const Color _glassDarkBorder = Color(0x26FFFFFF);
  static const Color _glassDarkField = Color(0x1AFFFFFF);
  static const Color _glassDarkSolid = Color(0xFF1C1F28);
  static const Color _glassDarkMiddle = Color(0xFF181C2A);
  static const Color _glassDarkShadow = Color(0x66000000);

  // Neumorphic, light.
  static const Color _neuLightBase = Color(0xFFE4E8EE);
  static const Color _neuLightHighlight = Color(0xFFFFFFFF);
  static const Color _neuLightShade = Color(0xFFA9B4C6);
  static const Color _neuLightField = Color(0xFFD8DDE5);

  // Neumorphic, dark.
  static const Color _neuDarkBase = Color(0xFF2B2E33);
  static const Color _neuDarkHighlight = Color(0xFF353940);
  static const Color _neuDarkShade = Color(0xFF1D1F23);
  static const Color _neuDarkField = Color(0xFF24272B);

  static const double _accentTintAlpha = 0.16;
  static const double _accentTintAlphaDark = 0.14;
  static const double _glassBlur = 24;

  /// The style.
  final SurfaceStyle style;

  /// The background gradient, from the top left to the bottom right (one color twice for a flat
  /// background).
  final List<Color> background;

  /// Fill of a panel: translucent for glass, the background color for neumorphic.
  final Color panel;

  /// Fill of a text field and a pressed (inset) panel.
  final Color field;

  /// An opaque surface: dialogs, sheets, menus.
  final Color solid;

  /// Thin edge of a glass panel and of outlined controls.
  final Color border;

  /// The light shadow of neumorphic relief (top left).
  final Color highlight;

  /// The dark shadow under a panel (bottom right).
  final Color shade;

  /// How much glass blurs what is behind it; 0 for neumorphic.
  final double blur;

  /// Creates the colors.
  const SurfaceTheme({
    required this.style,
    required this.background,
    required this.panel,
    required this.field,
    required this.solid,
    required this.border,
    required this.highlight,
    required this.shade,
    required this.blur,
  });

  /// The colors of [style] in [brightness]; the background spots of glass take [accent].
  factory SurfaceTheme.forStyle(SurfaceStyle style, Brightness brightness, Color accent) {
    final bool isDark = brightness == Brightness.dark;
    return switch (style) {
      SurfaceStyle.glass => SurfaceTheme(
        style: style,
        background: <Color>[
          if (isDark) _glassDarkTop else _glassLightTop,
          if (isDark) _glassDarkMiddle else _glassLightMiddle,
          Color.alphaBlend(
            accent.withValues(alpha: isDark ? _accentTintAlphaDark : _accentTintAlpha),
            isDark ? _glassDarkBottom : _glassLightBottom,
          ),
        ],
        panel: isDark ? _glassDarkPanel : _glassLightPanel,
        field: isDark ? _glassDarkField : _glassLightField,
        solid: isDark ? _glassDarkSolid : _glassLightSolid,
        border: isDark ? _glassDarkBorder : _glassLightBorder,
        highlight: isDark ? _glassDarkBorder : _glassLightBorder,
        shade: isDark ? _glassDarkShadow : _glassLightShadow,
        blur: _glassBlur,
      ),
      SurfaceStyle.neumorphic => SurfaceTheme(
        style: style,
        background: isDark ? const <Color>[_neuDarkBase, _neuDarkBase] : const <Color>[_neuLightBase, _neuLightBase],
        panel: isDark ? _neuDarkBase : _neuLightBase,
        field: isDark ? _neuDarkField : _neuLightField,
        solid: isDark ? _neuDarkBase : _neuLightBase,
        border: isDark ? _neuDarkHighlight : _neuLightHighlight,
        highlight: isDark ? _neuDarkHighlight : _neuLightHighlight,
        shade: isDark ? _neuDarkShade : _neuLightShade,
        blur: 0,
      ),
    };
  }

  /// The colors of the current theme; glass in its brightness and color when it has none
  /// (a theme not built by [AppTheme.build], as in widget tests).
  static SurfaceTheme of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<SurfaceTheme>() ??
        SurfaceTheme.forStyle(SurfaceStyle.glass, theme.brightness, theme.colorScheme.primary);
  }

  @override
  SurfaceTheme copyWith({
    SurfaceStyle? style,
    List<Color>? background,
    Color? panel,
    Color? field,
    Color? solid,
    Color? border,
    Color? highlight,
    Color? shade,
    double? blur,
  }) => SurfaceTheme(
    style: style ?? this.style,
    background: background ?? this.background,
    panel: panel ?? this.panel,
    field: field ?? this.field,
    solid: solid ?? this.solid,
    border: border ?? this.border,
    highlight: highlight ?? this.highlight,
    shade: shade ?? this.shade,
    blur: blur ?? this.blur,
  );

  /// Switching themes swaps the colors at once; the style cannot be blended.
  @override
  SurfaceTheme lerp(covariant ThemeExtension<SurfaceTheme>? other, double t) =>
      other is SurfaceTheme && t >= _half ? other : this;

  static const double _half = 0.5;
}
