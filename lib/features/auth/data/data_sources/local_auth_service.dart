import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';

/// Remembers on the device whether the app is used without an account.
final class LocalAuthService {
  /// Name of the Hive box of this service.
  static const String _boxName = 'auth';

  /// Key of the "used without an account" flag.
  static const String _guestKey = 'guest';

  final LocalStorageService _storage;

  Box<dynamic>? _box;

  /// Creates a new [LocalAuthService].
  LocalAuthService({required this._storage});

  /// Opens the box; returns this for `registerSingletonAsync`.
  Future<LocalAuthService> init() async {
    _box = await _storage.openBox(_boxName);
    return this;
  }

  Box<dynamic> get _openBox => _box!;

  /// Whether the user chose to use the app without an account.
  bool get isGuest => _openBox.get(_guestKey, defaultValue: false) as bool;

  /// Saves whether the app is used without an account.
  Future<void> setGuest(bool isGuest) => _openBox.put(_guestKey, isGuest);
}
