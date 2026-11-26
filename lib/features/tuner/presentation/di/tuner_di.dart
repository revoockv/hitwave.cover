import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/pitch_data_source.dart';
import '../../data/data_sources/record_pitch_data_source.dart';
import '../../data/repositories/tuner_repository_impl.dart';
import '../../domain/repositories/tuner_repository.dart';
import '../../domain/use_cases/start_tuner_use_case.dart';
import '../../domain/use_cases/stop_tuner_use_case.dart';
import '../../domain/use_cases/watch_tuner_use_case.dart';

/// Registers the tuner feature; the microphone is opened only when the tuner starts.
void registerAndInitTuner() {
  // 1. data sources — released by the repository
  di.registerLazySingleton<PitchDataSource>(RecordPitchDataSource.new);

  // 2. repositories
  di.registerLazySingleton<TunerRepository>(
    () => TunerRepositoryImpl(dataSource: di<PitchDataSource>(), logger: di<Logger>()),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchTunerUseCase>(() => WatchTunerUseCase(di<TunerRepository>()));
  di.registerLazySingleton<StartTunerUseCase>(() => StartTunerUseCase(di<TunerRepository>()));
  di.registerLazySingleton<StopTunerUseCase>(() => StopTunerUseCase(di<TunerRepository>()));
}
