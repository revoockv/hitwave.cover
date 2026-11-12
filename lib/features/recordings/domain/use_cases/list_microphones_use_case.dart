import '../../../../core/domain/entities/result.dart';
import '../entities/microphone.dart';
import '../repositories/recordings_repository.dart';

/// Use case that lists the sound inputs a take can be recorded from.
final class ListMicrophonesUseCase {
  final RecordingsRepository _repository;

  /// Creates a [ListMicrophonesUseCase].
  ListMicrophonesUseCase(this._repository);

  /// Returns the inputs of the device.
  Future<Result<List<Microphone>>> call() async {
    return _repository.listMicrophones();
  }
}
