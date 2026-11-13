import '../../../../core/domain/entities/result.dart';
import '../entities/accent_color.dart';
import '../entities/settings_failure.dart';
import '../repositories/settings_repository.dart';

/// Use case that changes the main color of the app.
final class SetAccentColorUseCase {
  final SettingsRepository _repository;

  /// Creates a [SetAccentColorUseCase].
  SetAccentColorUseCase(this._repository);

  /// Makes [color] the main color of the app.
  Future<Result<void, SettingsFailure>> call(AccentColor color) async {
    return _repository.setAccentColor(color);
  }
}
