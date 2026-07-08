import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get_it/get_it.dart';

import '../../data/repositories/backup_repository_impl.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/use_cases/export_songs_use_case.dart';
import '../../domain/use_cases/import_songs_use_case.dart';
import '../../domain/use_cases/watch_backup_status_use_case.dart';
import '../../../song/data/data_sources/firebase_song_service.dart';
import '../../../song/domain/repositories/song_repository.dart';

/// Registers all backup feature dependencies in GetIt.
///
/// Creates singleton instances for the backup repository implementation,
/// then registers the status ValueNotifier with the instance key
/// `backup.status`. Registers all use cases as singletons.
Future<void> registerBackupFeature() async {
  final getIt = GetIt.instance;

  final repository = BackupRepositoryImpl(
    songService: getIt<FirebaseSongService>(),
    songRepository: getIt<SongRepository>(),
    logger: getIt.get(),
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
