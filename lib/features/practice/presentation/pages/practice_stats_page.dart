import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../song/domain/entities/song.dart';
import '../controllers/practice_page_controller.dart';
import '../l10n/practice_texts.dart';
import '../wrappers/practice_stats_wrapper.dart';

/// The practice statistics tab: owns the calendar position; never rebuilds — its wrapper counts the practice.
final class PracticeStatsPage extends WatchingWidget {
  /// Opens a song (tapping it in a list).
  final ValueChanged<Song> onSongPressed;

  /// Creates a new [PracticeStatsPage].
  const PracticeStatsPage({super.key, required this.onSongPressed});

  @override
  Widget build(BuildContext context) {
    final PracticePageController practicePageController = createOnce(
      _createPracticePageController,
      dispose: _disposePracticePageController,
    );
    return PracticeStatsWrapper(
      practicePageController: practicePageController,
      texts: context.t.practiceTexts,
      onSongPressed: onSongPressed,
    );
  }

  static PracticePageController _createPracticePageController() => PracticePageController(today: DateTime.now());

  static void _disposePracticePageController(PracticePageController practicePageController) =>
      practicePageController.dispose();
}
