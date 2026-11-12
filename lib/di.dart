import 'package:watch_it/watch_it.dart';

import 'core/presentation/di/core_di.dart';
import 'features/auth/presentation/di/auth_di.dart';
import 'features/backup/presentation/di/backup_di.dart';
import 'features/practice/presentation/di/practice_di.dart';
import 'features/recordings/presentation/di/recordings_di.dart';
import 'features/song/presentation/di/song_di.dart';
import 'features/vocal_enhance/presentation/di/vocal_enhance_di.dart';

/// Registers every feature and waits until all async initializations finish.
Future<void> registerAndInit() async {
  await di.reset();

  registerAndInitCore();

  registerAndInitAuth();
  registerAndInitSong();
  registerAndInitVocalEnhance();
  registerAndInitRecordings();
  registerAndInitPractice();
  registerAndInitBackup();

  await di.allReady();
}
