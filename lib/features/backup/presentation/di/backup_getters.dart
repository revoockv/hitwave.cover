import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/export_songs_use_case.dart';
import '../../domain/use_cases/import_songs_use_case.dart';
import '../../domain/use_cases/share_backup_use_case.dart';
import '../../domain/use_cases/watch_backup_status_use_case.dart';

/// The use case that exports all songs to a JSON file.
ExportSongsUseCase get exportSongsUseCase => di<ExportSongsUseCase>();

/// The use case that imports songs from a JSON file.
ImportSongsUseCase get importSongsUseCase => di<ImportSongsUseCase>();

/// The use case that watches the backup status; call it to get the [ValueListenable].
WatchBackupStatusUseCase get watchBackupStatusUseCase => di<WatchBackupStatusUseCase>();

/// The use case that shares a backup to Google Drive or another app.
ShareBackupUseCase get shareBackupUseCase => di<ShareBackupUseCase>();
