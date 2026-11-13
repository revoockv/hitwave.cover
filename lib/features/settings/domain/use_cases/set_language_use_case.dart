import '../../../../core/domain/entities/result.dart';
import '../entities/app_language.dart';
import '../entities/settings_failure.dart';
import '../repositories/settings_repository.dart';

/// Use case that changes the language of the app.
final class SetLanguageUseCase {
  final SettingsRepository _repository;

  /// Creates a [SetLanguageUseCase].
  SetLanguageUseCase(this._repository);

  /// Makes [language] the language of the app.
  Future<Result<void, SettingsFailure>> call(AppLanguage language) async {
    return _repository.setLanguage(language);
  }
}
