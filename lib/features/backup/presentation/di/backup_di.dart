import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/data/data_sources/system_files_data_source.dart';
import '../../../../core/presentation/di/core_di.dart';
import '../../../recordings/domain/repositories/recordings_repository.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../data/data_sources/backup_archive_data_source.dart';
import '../../data/data_sources/backup_data_source.dart';
import '../../data/data_sources/backup_data_source_mobile.dart';
import '../../data/data_sources/backup_data_source_web.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/use_cases/apply_import_use_case.dart';
import '../../domain/use_cases/cancel_import_use_case.dart';
import '../../domain/use_cases/export_songs_use_case.dart';
import '../../domain/use_cases/open_import_use_case.dart';
import '../../domain/use_cases/share_backup_use_case.dart';
import '../../domain/use_cases/watch_backup_status_use_case.dart';

/// Registers the backup feature; the repository waits for the song and recordings repositories.
void registerAndInitBackup() {
  // 1. data sources
  di.registerLazySingleton<BackupDataSource>(_createDataSource);
  di.registerLazySingleton<BackupArchiveDataSource>(BackupArchiveDataSource.new);

  // 2. repositories
  di.registerSingletonWithDependencies<BackupRepository>(
    () => BackupRepositoryImpl(
      songRepository: di<SongRepository>(),
      recordingsRepository: di<RecordingsRepository>(),
      dataSource: di<BackupDataSource>(),
      archive: di<BackupArchiveDataSource>(),
      system: di<SystemFilesDataSource>(),
      logger: di<Logger>(),
    ),
    dependsOn: <Type>[SongRepository, RecordingsRepository],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<ExportSongsUseCase>(() => ExportSongsUseCase(di<BackupRepository>()));
  di.registerLazySingleton<OpenImportUseCase>(() => OpenImportUseCase(di<BackupRepository>()));
  di.registerLazySingleton<ApplyImportUseCase>(() => ApplyImportUseCase(di<BackupRepository>()));
  di.registerLazySingleton<CancelImportUseCase>(() => CancelImportUseCase(di<BackupRepository>()));
  di.registerLazySingleton<ShareBackupUseCase>(() => ShareBackupUseCase(di<BackupRepository>()));
  di.registerLazySingleton<WatchBackupStatusUseCase>(() => WatchBackupStatusUseCase(di<BackupRepository>()));
}

/// The file picker implementation of the current platform.
BackupDataSource _createDataSource() => kIsWeb ? BackupDataSourceWeb() : BackupDataSourceMobile();
