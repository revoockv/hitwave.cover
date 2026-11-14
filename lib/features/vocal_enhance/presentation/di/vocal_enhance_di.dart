import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/unsupported_vocal_enhance_engine.dart'
    if (dart.library.io) '../../data/data_sources/vocal_enhance_engine.dart';
import '../../data/data_sources/vocal_enhance_data_source.dart';
import '../../data/repositories/vocal_enhance_repository_impl.dart';
import '../../domain/repositories/vocal_enhance_repository.dart';
import '../../domain/use_cases/analyze_recording_use_case.dart';
import '../../domain/use_cases/enhance_recording_use_case.dart';
import '../../domain/use_cases/watch_enhance_progress_use_case.dart';

/// Registers the vocal_enhance feature.
///
/// Everything is lazy; every request runs the pure-Dart engine in a background isolate.
void registerAndInitVocalEnhance() {
  // 1. data sources
  di.registerLazySingleton<VocalEnhanceDataSource>(createVocalEnhanceDataSource, dispose: disposeResource);

  // 2. repositories
  di.registerLazySingleton<VocalEnhanceRepository>(
    () => VocalEnhanceRepositoryImpl(dataSource: di<VocalEnhanceDataSource>(), logger: di<Logger>()),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<EnhanceRecordingUseCase>(() => EnhanceRecordingUseCase(di<VocalEnhanceRepository>()));
  di.registerLazySingleton<AnalyzeRecordingUseCase>(() => AnalyzeRecordingUseCase(di<VocalEnhanceRepository>()));
  di.registerLazySingleton<WatchEnhanceProgressUseCase>(
    () => WatchEnhanceProgressUseCase(di<VocalEnhanceRepository>()),
  );
}
