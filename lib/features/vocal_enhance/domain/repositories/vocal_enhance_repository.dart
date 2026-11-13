import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/enhance_preset.dart';
import '../entities/enhance_progress.dart';
import '../entities/enhance_report.dart';
import '../entities/recording_analysis.dart';

/// Measures recordings and turns raw vocal takes into cleaned, mastered WAV files.
///
/// The work runs in the audio engine on the device (embedded Python); one request runs at a time.
abstract interface class VocalEnhanceRepository {
  /// The step of the running enhancement, or `null` when nothing runs.
  ValueListenable<EnhanceProgress?> watchProgress();

  /// Measures the WAV file at [path].
  Future<Result<RecordingAnalysis>> analyzeRecording(String path);

  /// Processes [inputPath] with [preset] plus [settings] (engine setting name → value) and
  /// writes a 24-bit WAV file to [outputPath].
  ///
  /// [roomToneSeconds] is how long the take starts with room tone only; `null` lets the engine
  /// learn the noise from the quietest parts. [trimSilence] cuts the silence before the first
  /// and after the last sung note of the enhanced file (the raw take stays whole).
  Future<Result<EnhanceReport>> enhanceRecording({
    required String inputPath,
    required String outputPath,
    required EnhancePreset preset,
    required double? roomToneSeconds,
    required bool trimSilence,
    required Map<String, double> settings,
  });
}
