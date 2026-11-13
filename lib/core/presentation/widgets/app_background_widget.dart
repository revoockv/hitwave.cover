import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The background under every page: a soft gradient with large blurred spots for glass,
/// one flat color for neumorphic.
final class AppBackgroundWidget extends StatelessWidget {
  static const double _blobBlur = 90;
  static const double _blobSizeFactor = 0.9;

  /// Where the spots stand, as fractions of the screen (center x, center y).
  static const List<Offset> _blobCenters = <Offset>[Offset(0.9, 0.12), Offset(0.05, 0.55), Offset(0.85, 0.9)];

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
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: surfaces.background),
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

/// Large blurred spots of [colors] behind the glass panels.
final class _BlobsWidget extends StatelessWidget {
  /// The colors, taken in turn.
  final List<Color> colors;

  const _BlobsWidget({required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double size = constraints.biggest.shortestSide * AppBackgroundWidget._blobSizeFactor;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: AppBackgroundWidget._blobBlur, sigmaY: AppBackgroundWidget._blobBlur),
            child: Stack(
              children: <Widget>[
                for (int index = 0; index < AppBackgroundWidget._blobCenters.length; index++)
                  Positioned(
                    left: constraints.maxWidth * AppBackgroundWidget._blobCenters[index].dx - size / 2,
                    top: constraints.maxHeight * AppBackgroundWidget._blobCenters[index].dy - size / 2,
                    width: size,
                    height: size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
