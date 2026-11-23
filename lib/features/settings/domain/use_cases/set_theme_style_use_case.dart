import '../../../../core/domain/entities/result.dart';
import '../entities/app_theme_style.dart';
import '../entities/settings_failure.dart';
import '../repositories/settings_repository.dart';

/// Use case that changes the look of the app.
final class SetThemeStyleUseCase {
  final SettingsRepository _repository;

  /// Creates a [SetThemeStyleUseCase].
  SetThemeStyleUseCase(this._repository);

  /// Makes [style] the look of the app.
  Future<Result<void, SettingsFailure>> call(AppThemeStyle style) async {
    return _repository.setThemeStyle(style);
  }
}
