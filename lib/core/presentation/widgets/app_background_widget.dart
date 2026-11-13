import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The background under every page: a soft gradient with blurred spots of color for glass
/// (large hazy glows and a few clearer circles, so the frosted panels have something to
/// blur), one flat color for neumorphic.
final class AppBackgroundWidget extends StatelessWidget {
  /// The spots of glass, from the back: large hazy glows first, clearer circles on top.
  ///
  /// Every spot: center x and y (fractions of the screen), size (fraction of its shorter side),
  /// which of the theme's spot colors it takes, and how much it is blurred.
  static const List<({double x, double y, double size, int color, double blur})> _blobs =
      <({double x, double y, double size, int color, double blur})>[
        (x: 1, y: 0.05, size: 1.1, color: 0, blur: 80),
        (x: -0.05, y: 0.45, size: 0.95, color: 1, blur: 70),
        (x: 1.05, y: 0.95, size: 0.9, color: 0, blur: 70),
        (x: 0.2, y: 0.92, size: 0.6, color: 2, blur: 40),
        (x: 0.82, y: 0.58, size: 0.42, color: 1, blur: 24),
        (x: 0.12, y: 0.16, size: 0.3, color: 2, blur: 18),
      ];

  /// The pages.
  final Widget child;

  /// Creates the background.
  const AppBackgroundWidget({required this.child, super.key});

  /// `MaterialApp.builder` that puts the background under every page.
  static Widget wrap(BuildContext context, Widget? child) =>
      AppBackgroundWidget(child: child ?? const SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final SurfaceTheme surfaces = SurfaceTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: surfaces.background),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (surfaces.blobs.isNotEmpty) _BlobsWidget(colors: surfaces.blobs),
          child,
        ],
      ),
    );
  }
}

/// The blurred spots of [colors] behind the glass panels.
final class _BlobsWidget extends StatelessWidget {
  /// The colors of the theme's spots.
  final List<Color> colors;

  const _BlobsWidget({required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double side = constraints.biggest.shortestSide;
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                for (final ({double x, double y, double size, int color, double blur}) blob
                    in AppBackgroundWidget._blobs)
                  Positioned(
                    left: constraints.maxWidth * blob.x - side * blob.size / 2,
                    top: constraints.maxHeight * blob.y - side * blob.size / 2,
                    width: side * blob.size,
                    height: side * blob.size,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blob.blur, sigmaY: blob.blur, tileMode: TileMode.decal),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: colors[blob.color % colors.length], shape: BoxShape.circle),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
