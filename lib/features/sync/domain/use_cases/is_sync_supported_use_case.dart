import '../repositories/sync_repository.dart';

/// Use case that tells whether this platform can synchronise with another device.
final class IsSyncSupportedUseCase {
  final SyncRepository _repository;

  /// Creates an [IsSyncSupportedUseCase].
  IsSyncSupportedUseCase(this._repository);

  /// Whether the synchronisation is offered.
  bool call() {
    return _repository.isSupported();
  }
}
