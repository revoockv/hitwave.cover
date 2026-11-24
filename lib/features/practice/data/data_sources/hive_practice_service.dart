import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/practice_session_model.dart';

/// The practice sessions on this device: one Hive map per session.
final class HivePracticeService {
  static const String _boxName = 'practice_sessions';
  static const String _deletedBoxName = 'deleted_practice_sessions';

  final LocalStorageService _storage;

  Box<dynamic>? _box;
  Box<dynamic>? _deletedBox;

  /// Creates the service.
  HivePracticeService({required this._storage});

  /// Opens the box; returns this for `registerSingletonAsync`.
  Future<HivePracticeService> init() async {
    _box = await _storage.openBox(_boxName);
    _deletedBox = await _storage.openBox(_deletedBoxName);
    return this;
  }

  Box<dynamic> get _sessions => _box!;

  /// Every stored session.
  List<PracticeSessionModel> readAll() => _sessions.values.map(_toModel).toList();

  /// Stores [model], replacing the one with its id.
  Future<void> put(PracticeSessionModel model) => _sessions.put(model.id, model.toMap());

  /// Deletes the sessions [ids].
  Future<void> deleteAll(Iterable<String> ids) => _sessions.deleteAll(ids);

  /// Ids of the sessions deleted by the user, so that a synchronisation does not bring them back.
  Set<String> readDeletedIds() => _deletedBox!.keys.map((dynamic key) => key as String).toSet();

  /// Remembers that the sessions [ids] were deleted by the user.
  Future<void> markDeleted(Iterable<String> ids) =>
      _deletedBox!.putAll(<String, String>{for (final String id in ids) id: DateTime.now().toUtc().toIso8601String()});

  PracticeSessionModel _toModel(dynamic value) => PracticeSessionModel.fromStored(value);
}
