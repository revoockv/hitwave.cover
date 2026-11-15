import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:revoockv_audio_enhance/revoockv_audio_enhance.dart' as audio;

import '../../../../core/domain/entities/disposable_resource.dart';
import '../models/enhance_progress_model.dart';
import '../models/enhance_report_model.dart';
import '../models/recording_analysis_model.dart';
import 'vocal_enhance_data_source.dart';

/// [VocalEnhanceDataSource] on the pure-Dart `revoockv_audio_enhance` package.
///
/// Every request runs in its own background isolate, which reads the WAV file, processes it and
/// writes the result itself, so the audio never crosses into the UI isolate. Settings use the
/// engine's snake_case names (`noise_reduction_db`, `trim_silence`, …).
final class PackageVocalEnhanceDataSource implements VocalEnhanceDataSource, DisposableResource {
  static const String _closedError = 'The audio engine stopped';
  static const String _temporarySuffix = '.part';
  static const String _widenMonoKey = 'widen_mono';

  final Set<audio.AudioTask<Object?>> _running = <audio.AudioTask<Object?>>{};

  /// Creates a [PackageVocalEnhanceDataSource].
  PackageVocalEnhanceDataSource();

  @override
  Future<RecordingAnalysisModel> analyze(String inputPath) async {
    final audio.RecordingAnalysis analysis = await _run(
      audio.AudioTask<audio.RecordingAnalysis>.start(_analyzeWork(inputPath)),
    );
    return _analysisModel(analysis);
  }

  @override
  Future<EnhanceReportModel> enhance({
    required String inputPath,
    required String outputPath,
    required String preset,
    required Map<String, double> settings,
    required void Function(EnhanceProgressModel progress) onProgress,
  }) async {
    final audio.EnhanceSettings applied = _settingsOf(preset, settings);
    final audio.AudioTask<_Outcome> task = audio.AudioTask<_Outcome>.start(
      _enhanceWork(inputPath, outputPath, applied),
    );
    final StreamSubscription<audio.AudioProgress> progress = task.progress.listen(
      (audio.AudioProgress p) =>
          onProgress(EnhanceProgressModel(step: p.step, steps: p.steps, label: p.label, fraction: p.fraction)),
    );
    try {
      final _Outcome outcome = await _run(task);
      return EnhanceReportModel(
        inputPath: inputPath,
        outputPath: outputPath,
        settings: _settingsMap(applied),
        before: _analysisModel(outcome.before),
        after: _analysisModel(outcome.after),
        secondsSpent: outcome.secondsSpent,
        keptFromSeconds: outcome.keptFromSeconds,
        keptToSeconds: outcome.keptToSeconds,
      );
    } finally {
      await progress.cancel();
    }
  }

  /// Stops the running requests; they fail with [VocalEnhanceEngineException].
  @override
  void dispose() {
    for (final audio.AudioTask<Object?> task in _running.toList()) {
      task.cancel();
    }
    _running.clear();
  }

  Future<T> _run<T>(audio.AudioTask<T> task) async {
    _running.add(task);
    try {
      return await task.result;
    } on audio.AudioTaskCancelledException {
      throw const VocalEnhanceEngineException(_closedError);
    } on VocalEnhanceEngineException {
      rethrow;
    } catch (e) {
      throw VocalEnhanceEngineException(e.toString());
    } finally {
      _running.remove(task);
    }
  }

  // The work is built in static functions, so the closure sent to the background isolate holds
  // only these values (a closure made inside an instance method could drag along the progress
  // callback and everything it holds).
  static audio.AudioWork<audio.RecordingAnalysis> _analyzeWork(String inputPath) =>
      (audio.AudioProgressListener report) => audio.VocalEnhancer().analyze(_read(inputPath));

  static audio.AudioWork<_Outcome> _enhanceWork(String inputPath, String outputPath, audio.EnhanceSettings settings) =>
      (audio.AudioProgressListener report) => _enhanceFile(inputPath, outputPath, settings, report);

  /// Runs in the background isolate: read, enhance, write atomically, report the levels.
  static _Outcome _enhanceFile(
    String inputPath,
    String outputPath,
    audio.EnhanceSettings settings,
    audio.AudioProgressListener report,
  ) {
    final Stopwatch watch = Stopwatch()..start();
    final audio.PcmAudio take = _read(inputPath);
    final audio.EnhanceResult result = audio.VocalEnhancer().enhance(take, settings: settings, onProgress: report);
    final File output = File(outputPath);
    output.parent.createSync(recursive: true);
    final File temporary = File('$outputPath$_temporarySuffix');
    temporary.writeAsBytesSync(audio.WavCodec.encode24(result.audio), flush: true);
    temporary.renameSync(output.path);
    return _Outcome(
      before: result.before,
      after: result.after,
      secondsSpent: watch.elapsedMicroseconds / Duration.microsecondsPerSecond,
      keptFromSeconds: result.keptFrom / take.sampleRate,
      keptToSeconds: result.keptTo / take.sampleRate,
    );
  }

  static audio.PcmAudio _read(String path) {
    final File file = File(path);
    if (!file.existsSync()) {
      throw VocalEnhanceEngineException('no such file: $path');
    }
    final Uint8List bytes = file.readAsBytesSync();
    try {
      return audio.WavCodec.decode(bytes);
    } on audio.WavFormatException catch (e) {
      throw VocalEnhanceEngineException('$path: ${e.message}');
    }
  }

  /// The preset by its engine name, then the [overrides] on top.
  ///
  /// Whatever the preset, a one-channel take always comes out as mono-compatible pseudo-stereo:
  /// most microphones (laptops, most phones) give a single channel.
  static audio.EnhanceSettings _settingsOf(String preset, Map<String, double> overrides) {
    final audio.EnhanceSettings base = switch (preset) {
      'studio' => audio.EnhancePreset.studio.settings,
      'loudness' => audio.EnhancePreset.loudnessOnly.settings,
      'classic' => audio.EnhancePreset.classic.settings,
      _ => audio.EnhancePreset.natural.settings,
    };
    final Map<String, double> current = _settingsMap(base)
      ..addAll(overrides)
      ..[_widenMonoKey] = 1;
    double value(String key) => current[key]!;
    return audio.EnhanceSettings(
      alignStereo: value('align_stereo') > 0,
      toneMaxBoostDb: value('tone_max_boost_db'),
      toneMaxCutDb: value('tone_max_cut_db'),
      highPassHz: value('high_pass_hz'),
      noiseReductionDb: value('noise_reduction_db'),
      noiseSensitivity: value('noise_sensitivity'),
      noiseProfileSeconds: value('noise_profile_seconds'),
      mudCutDb: value('mud_cut_db'),
      mudHz: value('mud_hz'),
      presenceDb: value('presence_db'),
      presenceHz: value('presence_hz'),
      airDb: value('air_db'),
      airHz: value('air_hz'),
      deEssDb: value('de_ess_db'),
      compressionRatio: value('compression_ratio'),
      compressionThresholdDb: value('compression_threshold_db'),
      compressionAttackSeconds: value('compression_attack_s'),
      compressionReleaseSeconds: value('compression_release_s'),
      expanderRatio: value('expander_ratio'),
      expanderBelowDb: value('expander_below_db'),
      expanderFloorDb: value('expander_floor_db'),
      widenMono: value(_widenMonoKey) > 0,
      monoWidthDb: value('mono_width_db'),
      targetLufs: value('target_lufs'),
      maxGainDb: value('max_gain_db'),
      truePeakDb: value('true_peak_db'),
      limiterReleaseSeconds: value('limiter_release_s'),
      trimSilence: value('trim_silence') > 0,
      trimPaddingSeconds: value('trim_padding_s'),
      alignMaxLagSeconds: value('align_max_lag_s'),
      toneNoBoostBelowHz: value('tone_no_boost_below_hz'),
      noiseTransitionDb: value('noise_transition_db'),
      deEssLowHz: value('de_ess_low_hz'),
      deEssHighHz: value('de_ess_high_hz'),
      deEssAboveVoiceDb: value('de_ess_above_voice_db'),
      deEssAttackSeconds: value('de_ess_attack_s'),
      deEssReleaseSeconds: value('de_ess_release_s'),
      compressionKneeDb: value('compression_knee_db'),
      expanderOpenSeconds: value('expander_open_s'),
      expanderCloseSeconds: value('expander_close_s'),
      monoWidthLowHz: value('mono_width_low_hz'),
      monoWidthHighHz: value('mono_width_high_hz'),
      limiterLookaheadSeconds: value('limiter_lookahead_s'),
      limiterMakeupMaxDb: value('limiter_makeup_max_db'),
      trimAboveNoiseDb: value('trim_above_noise_db'),
      trimBelowLoudDb: value('trim_below_loud_db'),
      trimSilenceBelowLoudDb: value('trim_silence_below_loud_db'),
      trimFadeSeconds: value('trim_fade_s'),
    );
  }

  /// [settings] under the engine's names, as the report lists them.
  static Map<String, double> _settingsMap(audio.EnhanceSettings settings) => <String, double>{
    'align_stereo': settings.alignStereo ? 1 : 0,
    'tone_max_boost_db': settings.toneMaxBoostDb,
    'tone_max_cut_db': settings.toneMaxCutDb,
    'high_pass_hz': settings.highPassHz,
    'noise_reduction_db': settings.noiseReductionDb,
    'noise_sensitivity': settings.noiseSensitivity,
    'noise_profile_seconds': settings.noiseProfileSeconds,
    'mud_cut_db': settings.mudCutDb,
    'mud_hz': settings.mudHz,
    'presence_db': settings.presenceDb,
    'presence_hz': settings.presenceHz,
    'air_db': settings.airDb,
    'air_hz': settings.airHz,
    'de_ess_db': settings.deEssDb,
    'compression_ratio': settings.compressionRatio,
    'compression_threshold_db': settings.compressionThresholdDb,
    'compression_attack_s': settings.compressionAttackSeconds,
    'compression_release_s': settings.compressionReleaseSeconds,
    'expander_ratio': settings.expanderRatio,
    'expander_below_db': settings.expanderBelowDb,
    'expander_floor_db': settings.expanderFloorDb,
    _widenMonoKey: settings.widenMono ? 1 : 0,
    'mono_width_db': settings.monoWidthDb,
    'target_lufs': settings.targetLufs,
    'max_gain_db': settings.maxGainDb,
    'true_peak_db': settings.truePeakDb,
    'limiter_release_s': settings.limiterReleaseSeconds,
    'trim_silence': settings.trimSilence ? 1 : 0,
    'trim_padding_s': settings.trimPaddingSeconds,
    'align_max_lag_s': settings.alignMaxLagSeconds,
    'tone_no_boost_below_hz': settings.toneNoBoostBelowHz,
    'noise_transition_db': settings.noiseTransitionDb,
    'de_ess_low_hz': settings.deEssLowHz,
    'de_ess_high_hz': settings.deEssHighHz,
    'de_ess_above_voice_db': settings.deEssAboveVoiceDb,
    'de_ess_attack_s': settings.deEssAttackSeconds,
    'de_ess_release_s': settings.deEssReleaseSeconds,
    'compression_knee_db': settings.compressionKneeDb,
    'expander_open_s': settings.expanderOpenSeconds,
    'expander_close_s': settings.expanderCloseSeconds,
    'mono_width_low_hz': settings.monoWidthLowHz,
    'mono_width_high_hz': settings.monoWidthHighHz,
    'limiter_lookahead_s': settings.limiterLookaheadSeconds,
    'limiter_makeup_max_db': settings.limiterMakeupMaxDb,
    'trim_above_noise_db': settings.trimAboveNoiseDb,
    'trim_below_loud_db': settings.trimBelowLoudDb,
    'trim_silence_below_loud_db': settings.trimSilenceBelowLoudDb,
    'trim_fade_s': settings.trimFadeSeconds,
  };

  static RecordingAnalysisModel _analysisModel(audio.RecordingAnalysis analysis) {
    double? finite(double value) => value.isFinite ? value : null;
    return RecordingAnalysisModel(
      durationSeconds: analysis.durationSeconds,
      sampleRate: analysis.sampleRate,
      channels: analysis.channels,
      integratedLufs: finite(analysis.integratedLufs),
      truePeakDb: finite(analysis.truePeakDb),
      clippedPercent: analysis.clippedPercent,
      noiseFloorDb: finite(analysis.noiseFloorDb),
      signalToNoiseDb: finite(analysis.signalToNoiseDb),
      isClipped: analysis.isClipped,
      isTooQuiet: analysis.isTooQuiet,
      isNoisy: analysis.isNoisy,
    );
  }
}

/// What the background isolate sends back after enhancing (no audio, only the levels).
final class _Outcome {
  final audio.RecordingAnalysis before;
  final audio.RecordingAnalysis after;
  final double secondsSpent;
  final double keptFromSeconds;
  final double keptToSeconds;

  const _Outcome({
    required this.before,
    required this.after,
    required this.secondsSpent,
    required this.keptFromSeconds,
    required this.keptToSeconds,
  });
}
