import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../data/data_sources/backup_data_source.dart';
import '../../data/data_sources/backup_data_source_mobile.dart';
import '../../data/data_sources/backup_data_source_web.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/use_cases/export_songs_use_case.dart';
import '../../domain/use_cases/import_songs_use_case.dart';
import '../../domain/use_cases/watch_backup_status_use_case.dart';

/// Registers the backup feature; the repository waits for the song repository.
void registerAndInitBackup() {
  // 1. data sources
  di.registerLazySingleton<BackupDataSource>(_createDataSource);

  // 2. repositories
  di.registerSingletonWithDependencies<BackupRepository>(
    () => BackupRepositoryImpl(
      songRepository: di<SongRepository>(),
      dataSource: di<BackupDataSource>(),
      logger: di<Logger>(),
    ),
    dependsOn: <Type>[SongRepository],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<ExportSongsUseCase>(() => ExportSongsUseCase(di<BackupRepository>()));
  di.registerLazySingleton<ImportSongsUseCase>(() => ImportSongsUseCase(di<BackupRepository>()));
  di.registerLazySingleton<WatchBackupStatusUseCase>(() => WatchBackupStatusUseCase(di<BackupRepository>()));
}

/// The file picker implementation of the current platform.
BackupDataSource _createDataSource() => kIsWeb ? BackupDataSourceWeb() : BackupDataSourceMobile();
