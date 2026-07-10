import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../data/data_sources/backup_data_source.dart';
import '../../data/data_sources/backup_data_source_mobile.dart';
import '../../data/data_sources/backup_data_source_web.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/use_cases/export_songs_use_case.dart';
import '../../domain/use_cases/import_songs_use_case.dart';
import '../../domain/use_cases/watch_backup_status_use_case.dart';
import '../../../song/data/data_sources/firebase_song_service.dart';
import '../../../song/domain/repositories/song_repository.dart';

/// Registers all backup feature dependencies in GetIt.
///
/// Creates singleton instances for the backup data source, repository
/// implementation, then registers the status ValueNotifier with the
/// instance key `backup.status`. Registers all use cases as singletons.
Future<void> registerBackupFeature() async {
  final getIt = GetIt.instance;

  getIt.registerSingleton<BackupDataSource>(
    kIsWeb ? BackupDataSourceWeb() : BackupDataSourceMobile(),
  );

  final repository = BackupRepositoryImpl(
    songService: getIt<FirebaseSongService>(),
    songRepository: getIt<SongRepository>(),
    dataSource: getIt<BackupDataSource>(),
    auth: firebase_auth.FirebaseAuth.instance,
    logger: getIt<Logger>(),
  );

  getIt.registerSingleton<BackupRepository>(repository);

  getIt.registerSingleton<ValueNotifier<String>>(
    repository.status,
    instanceName: 'backup.status',
  );

  getIt.registerSingleton<ExportSongsUseCase>(ExportSongsUseCase(repository));
  getIt.registerSingleton<ImportSongsUseCase>(ImportSongsUseCase(repository));
  getIt.registerSingleton<WatchBackupStatusUseCase>(
    WatchBackupStatusUseCase(repository),
  );
}
