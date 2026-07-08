import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get_it/get_it.dart';
import 'package:hitwave.cover/features/backup/domain/use_cases/export_songs_use_case.dart';
import 'package:hitwave.cover/features/backup/domain/use_cases/import_songs_use_case.dart';
import 'package:hitwave.cover/features/backup/domain/use_cases/watch_backup_status_use_case.dart';
import 'package:watch_it/watch_it.dart';

/// Returns the export songs use case.
ExportSongsUseCase get exportSongsUseCase {
  return GetIt.instance<ExportSongsUseCase>();
}

/// Returns the import songs use case.
ImportSongsUseCase get importSongsUseCase {
  return GetIt.instance<ImportSongsUseCase>();
}

/// Returns the watch backup status use case.
ValueNotifier<String> get watchBackupStatusUseCase {
  return GetIt.instance<WatchBackupStatusUseCase>()();
}
