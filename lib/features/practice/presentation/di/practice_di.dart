import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../../../../core/presentation/di/core_di.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../data/data_sources/hive_practice_service.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/use_cases/calculate_practice_stats_use_case.dart';
import '../../domain/use_cases/start_practice_use_case.dart';
import '../../domain/use_cases/stop_practice_use_case.dart';
import '../../domain/use_cases/watch_practice_sessions_use_case.dart';

/// Registers the practice feature; the sessions wait for Hive and the song repository.
void registerAndInitPractice() {
  // 1. data sources
  di.registerSingletonAsync<HivePracticeService>(
    () => HivePracticeService(storage: di<LocalStorageService>()).init(),
    dependsOn: <Type>[LocalStorageService],
  );

  // 2. repositories
  di.registerSingletonWithDependencies<PracticeRepository>(
    () => PracticeRepositoryImpl(
      store: di<HivePracticeService>(),
      songs: di<SongRepository>(),
      logger: di<Logger>(),
    ).init(),
    dependsOn: <Type>[HivePracticeService, SongRepository],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<StartPracticeUseCase>(() => StartPracticeUseCase(di<PracticeRepository>()));
  di.registerLazySingleton<StopPracticeUseCase>(() => StopPracticeUseCase(di<PracticeRepository>()));
  di.registerLazySingleton<WatchPracticeSessionsUseCase>(() => WatchPracticeSessionsUseCase(di<PracticeRepository>()));
  di.registerLazySingleton<CalculatePracticeStatsUseCase>(CalculatePracticeStatsUseCase.new);
}
