import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/python_vocal_enhance_data_source.dart';
import '../../data/data_sources/unsupported_python_engine_channel.dart'
    if (dart.library.ffi) '../../data/data_sources/serious_python_engine_channel.dart';
import '../../data/data_sources/vocal_enhance_data_source.dart';
import '../../data/repositories/vocal_enhance_repository_impl.dart';
import '../../domain/repositories/vocal_enhance_repository.dart';
import '../../domain/use_cases/analyze_recording_use_case.dart';
import '../../domain/use_cases/enhance_recording_use_case.dart';
import '../../domain/use_cases/watch_enhance_progress_use_case.dart';

/// Registers the vocal_enhance feature.
///
/// Everything is lazy: the embedded Python starts on the first request, not at app start.
void registerAndInitVocalEnhance() {
  // 1. data sources
  di.registerLazySingleton<VocalEnhanceDataSource>(
    () => PythonVocalEnhanceDataSource(createPythonEngineChannel()),
    dispose: disposeResource,
  );

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
