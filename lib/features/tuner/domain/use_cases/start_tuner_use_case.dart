import '../../../../core/domain/entities/result.dart';
import '../entities/tuner_failure.dart';
import '../repositories/tuner_repository.dart';

/// Use case that starts listening to the microphone for the tuner.
final class StartTunerUseCase {
  final TunerRepository _repository;

  /// Creates a [StartTunerUseCase].
  StartTunerUseCase(this._repository);

  /// Starts the tuner; fails when the microphone may not or cannot be used.
  Future<Result<void, TunerFailure>> call() => _repository.start();
}
