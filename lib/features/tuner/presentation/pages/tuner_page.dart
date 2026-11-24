import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../widgets/tuner_widget.dart';

/// The tuner on a page of its own, opened from the lyrics of a song.
final class TunerPage extends StatelessWidget {
  /// Creates a [TunerPage].
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.tuner.title)),
      body: const TunerWidget(),
    );
  }
}
