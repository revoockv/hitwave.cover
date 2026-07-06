import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

/// Registers core application dependencies in GetIt.
///
/// Must be called before any feature DI registration. Registers a singleton
/// [Logger] instance accessible via `getIt<Logger>()`.
Future<void> registerCoreDI() async {
  final getIt = GetIt.instance;

  getIt.registerSingleton<Logger>(Logger());
}
