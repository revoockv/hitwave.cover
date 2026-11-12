import '../../../../core/domain/entities/result.dart';
import '../entities/enhance_preset.dart';
import '../entities/enhance_report.dart';
import '../repositories/vocal_enhance_repository.dart';

/// Use case that turns a raw vocal take into a cleaned, mastered WAV file.
final class EnhanceRecordingUseCase {
  static const String _wavExtension = '.wav';
  static const String _samePathError = 'Покращений запис має бути окремим файлом';
  static const String _notWavError = 'Покращений запис має бути файлом .wav';
  static const String _negativeLeadInError = 'Тиша на початку не може бути від’ємною';

  final VocalEnhanceRepository _repository;

  /// Creates an [EnhanceRecordingUseCase].
  EnhanceRecordingUseCase(this._repository);

  /// Enhances [inputPath] into [outputPath] with [preset].
  ///
  /// [roomToneSeconds] is how long the take starts with room tone only (the lead-in before
  /// singing); the engine learns the noise from it. Leave it `null` to let the engine find the
  /// quietest parts. [trimSilence] cuts the silence before and after the singing in the enhanced
  /// file. [settings] change single engine settings on top of the preset.
  Future<Result<EnhanceReport>> call({
    required String inputPath,
    required String outputPath,
    EnhancePreset preset = EnhancePreset.natural,
    double? roomToneSeconds,
    bool trimSilence = false,
    Map<String, double> settings = const <String, double>{},
  }) async {
    if (inputPath == outputPath) {
      return const Result.failure(_samePathError);
    }
    if (!outputPath.toLowerCase().endsWith(_wavExtension)) {
      return const Result.failure(_notWavError);
    }
    if (roomToneSeconds != null && roomToneSeconds < 0) {
      return const Result.failure(_negativeLeadInError);
    }
    return _repository.enhanceRecording(
      inputPath: inputPath,
      outputPath: outputPath,
      preset: preset,
      roomToneSeconds: roomToneSeconds,
      trimSilence: trimSilence,
      settings: settings,
    );
  }
}
