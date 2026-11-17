import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/build_practice_timeline_use_case.dart';
import '../../domain/use_cases/calculate_practice_stats_use_case.dart';
import '../../domain/use_cases/clear_practice_use_case.dart';
import '../../domain/use_cases/start_practice_use_case.dart';
import '../../domain/use_cases/stop_practice_use_case.dart';
import '../../domain/use_cases/watch_practice_sessions_use_case.dart';

/// The use case that starts measuring the practice of a song.
StartPracticeUseCase get startPracticeUseCase => di<StartPracticeUseCase>();

/// The use case that ends the practice session being measured.
StopPracticeUseCase get stopPracticeUseCase => di<StopPracticeUseCase>();

/// The use case that watches every practice session; call it to get the [ValueListenable].
WatchPracticeSessionsUseCase get watchPracticeSessionsUseCase => di<WatchPracticeSessionsUseCase>();

/// The use case that counts the totals, streaks and calendar of the practice.
CalculatePracticeStatsUseCase get calculatePracticeStatsUseCase => di<CalculatePracticeStatsUseCase>();

/// The use case that puts the sessions and the takes into one timeline.
BuildPracticeTimelineUseCase get buildPracticeTimelineUseCase => di<BuildPracticeTimelineUseCase>();

/// The use case that forgets every practice session.
ClearPracticeUseCase get clearPracticeUseCase => di<ClearPracticeUseCase>();
