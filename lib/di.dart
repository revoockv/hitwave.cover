import 'package:get_it/get_it.dart';

import 'core/presentation/di/core_di.dart';
import 'features/auth/presentation/di/auth_di.dart';
import 'features/backup/presentation/di/backup_di.dart';
import 'features/song/presentation/di/song_di.dart';

/// Registers all application dependencies and runs all one-time
/// initialization before [runApp].
///
/// Resets GetIt, registers core dependencies (Logger), then registers
/// and initializes every feature (auth, song, backup).
Future<void> registerAndInit() async {
  final getIt = GetIt.instance;
  await getIt.reset();

  await registerCoreDI();

  await registerAuthFeature();
  await initAuthFeature();

  await registerSongFeature();
  await initSongFeature();

  await registerBackupFeature();

  await getIt.allReady();
}
