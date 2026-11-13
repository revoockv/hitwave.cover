import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/analyze_recording_use_case.dart';
import '../../domain/use_cases/enhance_recording_use_case.dart';
import '../../domain/use_cases/watch_enhance_progress_use_case.dart';

/// The use case that turns a raw vocal take into a cleaned, mastered WAV file.
EnhanceRecordingUseCase get enhanceRecordingUseCase => di<EnhanceRecordingUseCase>();

/// The use case that measures a take (loudness, peaks, clipping, noise).
AnalyzeRecordingUseCase get analyzeRecordingUseCase => di<AnalyzeRecordingUseCase>();

/// The use case that watches the running enhancement; call it to get the [ValueListenable].
WatchEnhanceProgressUseCase get watchEnhanceProgressUseCase => di<WatchEnhanceProgressUseCase>();
