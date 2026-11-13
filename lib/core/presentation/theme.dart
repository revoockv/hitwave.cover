/// Values shared by more than one feature: spacing, sizes, colors.
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

  /// Size of the small progress indicator inside buttons.
  static const double loadingIndicatorSize = 20;

  const AppTheme._();
}
