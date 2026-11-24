import '../repositories/tuner_repository.dart';

/// Use case that stops the tuner and frees the microphone.
final class StopTunerUseCase {
  final TunerRepository _repository;

  /// Creates a [StopTunerUseCase].
  StopTunerUseCase(this._repository);

  /// Stops the tuner.
  Future<void> call() => _repository.stop();
}
