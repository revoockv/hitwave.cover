import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// On-device key-value storage (Hive CE) shared by the features.
///
/// [init] prepares Hive once for the app; each feature opens its own box.
final class LocalStorageService {
  /// A subfolder of the documents folder for the data, set with `--dart-define=HITWAVE_STORAGE_FOLDER=…` (the README
  /// screenshots use one, so that their demo songs never touch the real library); empty means the documents folder.
  static const String storageFolder = String.fromEnvironment('HITWAVE_STORAGE_FOLDER');

  /// Prepares Hive in the app documents folder; returns this for `registerSingletonAsync`.
  Future<LocalStorageService> init() async {
    await Hive.initFlutter(storageFolder.isEmpty ? null : storageFolder);
    return this;
  }

  /// Opens (or creates) the box called [name].
  Future<Box<dynamic>> openBox(String name) => Hive.openBox<dynamic>(name);
}
