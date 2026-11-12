import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../../../../core/presentation/di/core_di.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../data/data_sources/hive_history_service.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/use_cases/mark_cover_played_use_case.dart';
import '../../domain/use_cases/mark_song_opened_use_case.dart';
import '../../domain/use_cases/watch_usage_history_use_case.dart';

/// Registers the history feature; it waits for Hive and the song repository.
void registerAndInitHistory() {
  // 1. data sources
  di.registerSingletonAsync<HiveHistoryService>(
    () => HiveHistoryService(storage: di<LocalStorageService>()).init(),
    dependsOn: <Type>[LocalStorageService],
  );

  // 2. repositories
  di.registerSingletonWithDependencies<HistoryRepository>(
    () => HistoryRepositoryImpl(
      store: di<HiveHistoryService>(),
      songs: di<SongRepository>(),
      logger: di<Logger>(),
    ).init(),
    dependsOn: <Type>[HiveHistoryService, SongRepository],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchUsageHistoryUseCase>(() => WatchUsageHistoryUseCase(di<HistoryRepository>()));
  di.registerLazySingleton<MarkSongOpenedUseCase>(() => MarkSongOpenedUseCase(di<HistoryRepository>()));
  di.registerLazySingleton<MarkCoverPlayedUseCase>(() => MarkCoverPlayedUseCase(di<HistoryRepository>()));
}
