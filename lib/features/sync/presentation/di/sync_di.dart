import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../practice/domain/repositories/practice_repository.dart';
import '../../../recordings/domain/repositories/recordings_repository.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../data/data_sources/sync_client_data_source.dart';
import '../../data/data_sources/sync_server_data_source.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/use_cases/is_sync_supported_use_case.dart';
import '../../domain/use_cases/start_sync_hosting_use_case.dart';
import '../../domain/use_cases/stop_sync_use_case.dart';
import '../../domain/use_cases/sync_with_device_use_case.dart';
import '../../domain/use_cases/watch_sync_state_use_case.dart';

/// Registers the synchronisation with another device; it works with the songs, recordings,
/// practice and history repositories.
void registerAndInitSync() {
  // 1. data sources
  di.registerLazySingleton<SyncServerDataSource>(SyncServerDataSource.new);
  di.registerLazySingleton<SyncClientDataSource>(SyncClientDataSource.new);

  // 2. repositories
  di.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      songs: di<SongRepository>(),
      recordings: di<RecordingsRepository>(),
      practice: di<PracticeRepository>(),
      history: di<HistoryRepository>(),
      server: di<SyncServerDataSource>(),
      client: di<SyncClientDataSource>(),
      logger: di<Logger>(),
      deviceName: kIsWeb ? '' : Platform.localHostname,
    ),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchSyncStateUseCase>(() => WatchSyncStateUseCase(di<SyncRepository>()));
  di.registerLazySingleton<IsSyncSupportedUseCase>(() => IsSyncSupportedUseCase(di<SyncRepository>()));
  di.registerLazySingleton<StartSyncHostingUseCase>(() => StartSyncHostingUseCase(di<SyncRepository>()));
  di.registerLazySingleton<SyncWithDeviceUseCase>(() => SyncWithDeviceUseCase(di<SyncRepository>()));
  di.registerLazySingleton<StopSyncUseCase>(() => StopSyncUseCase(di<SyncRepository>()));
}
