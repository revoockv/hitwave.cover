import 'package:flutter/material.dart';

import 'app_background_widget.dart';
import 'locale_fade_widget.dart';

/// What is around every page: the background, and the fade of a language change over the pages.
final class AppFrameWidget extends StatelessWidget {
  /// The pages.
  final Widget child;

  /// Creates the frame.
  const AppFrameWidget({required this.child, super.key});

  /// `MaterialApp.builder` that puts the frame around every page.
  static Widget wrap(BuildContext context, Widget? child) => AppFrameWidget(child: child ?? const SizedBox.shrink());

  @override
  Widget build(BuildContext context) => AppBackgroundWidget(child: LocaleFadeWidget(child: child));
}
