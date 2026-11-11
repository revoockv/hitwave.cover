import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// On-device key-value storage (Hive CE) shared by the features.
///
/// [init] prepares Hive once for the app; each feature opens its own box.
final class LocalStorageService {
  /// Prepares Hive in the app documents folder; returns this for `registerSingletonAsync`.
  Future<LocalStorageService> init() async {
    await Hive.initFlutter();
    return this;
  }

  /// Opens (or creates) the box called [name].
  Future<Box<dynamic>> openBox(String name) => Hive.openBox<dynamic>(name);
}
