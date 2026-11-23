import 'package:watch_it/watch_it.dart';

import 'core/presentation/di/core_di.dart';
import 'features/backup/presentation/di/backup_di.dart';
import 'features/history/presentation/di/history_di.dart';
import 'features/practice/presentation/di/practice_di.dart';
import 'features/recordings/presentation/di/recordings_di.dart';
import 'features/settings/presentation/di/settings_di.dart';
import 'features/song/presentation/di/song_di.dart';
import 'features/sync/presentation/di/sync_di.dart';
import 'features/vocal_enhance/presentation/di/vocal_enhance_di.dart';

/// Registers every feature and waits until all async initializations finish.
Future<void> registerAndInit() async {
  await di.reset();

  registerAndInitCore();
  registerAndInitSettings();

  registerAndInitSong();
  registerAndInitVocalEnhance();
  registerAndInitRecordings();
  registerAndInitPractice();
  registerAndInitHistory();
  registerAndInitSync();
  registerAndInitBackup();

  await di.allReady();
}
