import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/hive_settings_service.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/use_cases/set_language_use_case.dart';
import '../../domain/use_cases/watch_settings_use_case.dart';

/// Registers the settings feature; it waits for Hive.
void registerAndInitSettings() {
  // 1. data sources
  di.registerSingletonAsync<HiveSettingsService>(
    () => HiveSettingsService(storage: di<LocalStorageService>()).init(),
    dependsOn: <Type>[LocalStorageService],
  );

  // 2. repositories
  di.registerSingletonWithDependencies<SettingsRepository>(
    () => SettingsRepositoryImpl(store: di<HiveSettingsService>(), logger: di<Logger>()).init(),
    dependsOn: <Type>[HiveSettingsService],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchSettingsUseCase>(() => WatchSettingsUseCase(di<SettingsRepository>()));
  di.registerLazySingleton<SetLanguageUseCase>(() => SetLanguageUseCase(di<SettingsRepository>()));
}
