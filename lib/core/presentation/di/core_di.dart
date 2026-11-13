import 'dart:async';

import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../data/data_sources/local_storage_service.dart';
import '../../data/data_sources/system_files_data_source.dart';
import '../../domain/entities/disposable_resource.dart';

/// GetIt `dispose:` callback: calls our [DisposableResource.dispose] if [instance] owns resources.
FutureOr<void> disposeResource(Object instance) => instance is DisposableResource ? instance.dispose() : null;

/// Registers app-wide services used by every feature.
///
/// [LocalStorageService] prepares Hive; features that keep data on the device
/// depend on it. [SystemFilesDataSource] shares files and opens folders.
void registerAndInitCore() {
  di.registerSingleton<Logger>(Logger());
  di.registerSingletonAsync<LocalStorageService>(() => LocalStorageService().init());
  di.registerLazySingleton<SystemFilesDataSource>(SystemFilesDataSource.new);
}
