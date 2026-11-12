import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/practice_session_model.dart';

/// The practice sessions on this device: one Hive map per session.
final class HivePracticeService {
  static const String _boxName = 'practice_sessions';

  final LocalStorageService _storage;

  Box<dynamic>? _box;

  /// Creates the service.
  HivePracticeService({required this._storage});

  /// Opens the box; returns this for `registerSingletonAsync`.
  Future<HivePracticeService> init() async {
    _box = await _storage.openBox(_boxName);
    return this;
  }

  Box<dynamic> get _sessions => _box!;

  /// Every stored session.
  List<PracticeSessionModel> readAll() => _sessions.values.map(_toModel).toList();

  /// Stores [model], replacing the one with its id.
  Future<void> put(PracticeSessionModel model) => _sessions.put(model.id, model.toMap());

  /// Deletes the sessions [ids].
  Future<void> deleteAll(Iterable<String> ids) => _sessions.deleteAll(ids);

  PracticeSessionModel _toModel(dynamic value) => PracticeSessionModel.fromMap(value as Map<dynamic, dynamic>);
}
