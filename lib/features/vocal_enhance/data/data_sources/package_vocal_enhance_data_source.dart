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
  static const String _noFileError = 'no such file: ';
  static const String _separator = ': ';
  static const String _studioPreset = 'studio';
  static const String _loudnessPreset = 'loudness';
  static const String _classicPreset = 'classic';

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
      throw VocalEnhanceEngineException('$_noFileError$path');
    }
    final Uint8List bytes = file.readAsBytesSync();
    try {
      return audio.WavCodec.decode(bytes);
    } on audio.WavFormatException catch (e) {
      throw VocalEnhanceEngineException('$path$_separator${e.message}');
    }
  }

  /// The preset by its engine name, then the [overrides] on top.
  ///
  /// Whatever the preset, a one-channel take always comes out as mono-compatible pseudo-stereo:
  /// most microphones (laptops, most phones) give a single channel.
  static audio.EnhanceSettings _settingsOf(String preset, Map<String, double> overrides) {
    final audio.EnhanceSettings base = switch (preset) {
      _studioPreset => audio.EnhancePreset.studio.settings,
      _loudnessPreset => audio.EnhancePreset.loudnessOnly.settings,
      _classicPreset => audio.EnhancePreset.classic.settings,
      _ => audio.EnhancePreset.natural.settings,
    };
    final Map<String, double> current = _settingsMap(base)
      ..addAll(overrides)
      ..[_Key.widenMono] = 1;
    double value(String key) => current[key]!;
    return audio.EnhanceSettings(
      alignStereo: value(_Key.alignStereo) > 0,
      toneMaxBoostDb: value(_Key.toneMaxBoostDb),
      toneMaxCutDb: value(_Key.toneMaxCutDb),
      highPassHz: value(_Key.highPassHz),
      noiseReductionDb: value(_Key.noiseReductionDb),
      noiseSensitivity: value(_Key.noiseSensitivity),
      noiseProfileSeconds: value(_Key.noiseProfileSeconds),
      mudCutDb: value(_Key.mudCutDb),
      mudHz: value(_Key.mudHz),
      presenceDb: value(_Key.presenceDb),
      presenceHz: value(_Key.presenceHz),
      airDb: value(_Key.airDb),
      airHz: value(_Key.airHz),
      deEssDb: value(_Key.deEssDb),
      compressionRatio: value(_Key.compressionRatio),
      compressionThresholdDb: value(_Key.compressionThresholdDb),
      compressionAttackSeconds: value(_Key.compressionAttackS),
      compressionReleaseSeconds: value(_Key.compressionReleaseS),
      expanderRatio: value(_Key.expanderRatio),
      expanderBelowDb: value(_Key.expanderBelowDb),
      expanderFloorDb: value(_Key.expanderFloorDb),
      widenMono: value(_Key.widenMono) > 0,
      monoWidthDb: value(_Key.monoWidthDb),
      targetLufs: value(_Key.targetLufs),
      maxGainDb: value(_Key.maxGainDb),
      truePeakDb: value(_Key.truePeakDb),
      limiterReleaseSeconds: value(_Key.limiterReleaseS),
      trimSilence: value(_Key.trimSilence) > 0,
      trimPaddingSeconds: value(_Key.trimPaddingS),
      alignMaxLagSeconds: value(_Key.alignMaxLagS),
      toneNoBoostBelowHz: value(_Key.toneNoBoostBelowHz),
      noiseTransitionDb: value(_Key.noiseTransitionDb),
      deEssLowHz: value(_Key.deEssLowHz),
      deEssHighHz: value(_Key.deEssHighHz),
      deEssAboveVoiceDb: value(_Key.deEssAboveVoiceDb),
      deEssAttackSeconds: value(_Key.deEssAttackS),
      deEssReleaseSeconds: value(_Key.deEssReleaseS),
      compressionKneeDb: value(_Key.compressionKneeDb),
      expanderOpenSeconds: value(_Key.expanderOpenS),
      expanderCloseSeconds: value(_Key.expanderCloseS),
      monoWidthLowHz: value(_Key.monoWidthLowHz),
      monoWidthHighHz: value(_Key.monoWidthHighHz),
      limiterLookaheadSeconds: value(_Key.limiterLookaheadS),
      limiterMakeupMaxDb: value(_Key.limiterMakeupMaxDb),
      trimAboveNoiseDb: value(_Key.trimAboveNoiseDb),
      trimBelowLoudDb: value(_Key.trimBelowLoudDb),
      trimSilenceBelowLoudDb: value(_Key.trimSilenceBelowLoudDb),
      trimFadeSeconds: value(_Key.trimFadeS),
    );
  }

  /// [settings] under the engine's names, as the report lists them.
  static Map<String, double> _settingsMap(audio.EnhanceSettings settings) => <String, double>{
    _Key.alignStereo: settings.alignStereo ? 1 : 0,
    _Key.toneMaxBoostDb: settings.toneMaxBoostDb,
    _Key.toneMaxCutDb: settings.toneMaxCutDb,
    _Key.highPassHz: settings.highPassHz,
    _Key.noiseReductionDb: settings.noiseReductionDb,
    _Key.noiseSensitivity: settings.noiseSensitivity,
    _Key.noiseProfileSeconds: settings.noiseProfileSeconds,
    _Key.mudCutDb: settings.mudCutDb,
    _Key.mudHz: settings.mudHz,
    _Key.presenceDb: settings.presenceDb,
    _Key.presenceHz: settings.presenceHz,
    _Key.airDb: settings.airDb,
    _Key.airHz: settings.airHz,
    _Key.deEssDb: settings.deEssDb,
    _Key.compressionRatio: settings.compressionRatio,
    _Key.compressionThresholdDb: settings.compressionThresholdDb,
    _Key.compressionAttackS: settings.compressionAttackSeconds,
    _Key.compressionReleaseS: settings.compressionReleaseSeconds,
    _Key.expanderRatio: settings.expanderRatio,
    _Key.expanderBelowDb: settings.expanderBelowDb,
    _Key.expanderFloorDb: settings.expanderFloorDb,
    _Key.widenMono: settings.widenMono ? 1 : 0,
    _Key.monoWidthDb: settings.monoWidthDb,
    _Key.targetLufs: settings.targetLufs,
    _Key.maxGainDb: settings.maxGainDb,
    _Key.truePeakDb: settings.truePeakDb,
    _Key.limiterReleaseS: settings.limiterReleaseSeconds,
    _Key.trimSilence: settings.trimSilence ? 1 : 0,
    _Key.trimPaddingS: settings.trimPaddingSeconds,
    _Key.alignMaxLagS: settings.alignMaxLagSeconds,
    _Key.toneNoBoostBelowHz: settings.toneNoBoostBelowHz,
    _Key.noiseTransitionDb: settings.noiseTransitionDb,
    _Key.deEssLowHz: settings.deEssLowHz,
    _Key.deEssHighHz: settings.deEssHighHz,
    _Key.deEssAboveVoiceDb: settings.deEssAboveVoiceDb,
    _Key.deEssAttackS: settings.deEssAttackSeconds,
    _Key.deEssReleaseS: settings.deEssReleaseSeconds,
    _Key.compressionKneeDb: settings.compressionKneeDb,
    _Key.expanderOpenS: settings.expanderOpenSeconds,
    _Key.expanderCloseS: settings.expanderCloseSeconds,
    _Key.monoWidthLowHz: settings.monoWidthLowHz,
    _Key.monoWidthHighHz: settings.monoWidthHighHz,
    _Key.limiterLookaheadS: settings.limiterLookaheadSeconds,
    _Key.limiterMakeupMaxDb: settings.limiterMakeupMaxDb,
    _Key.trimAboveNoiseDb: settings.trimAboveNoiseDb,
    _Key.trimBelowLoudDb: settings.trimBelowLoudDb,
    _Key.trimSilenceBelowLoudDb: settings.trimSilenceBelowLoudDb,
    _Key.trimFadeS: settings.trimFadeSeconds,
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

/// The engine's snake_case setting names, as presets, overrides and reports use them.
abstract final class _Key {
  static const String airDb = 'air_db';
  static const String airHz = 'air_hz';
  static const String alignMaxLagS = 'align_max_lag_s';
  static const String alignStereo = 'align_stereo';
  static const String compressionAttackS = 'compression_attack_s';
  static const String compressionKneeDb = 'compression_knee_db';
  static const String compressionRatio = 'compression_ratio';
  static const String compressionReleaseS = 'compression_release_s';
  static const String compressionThresholdDb = 'compression_threshold_db';
  static const String deEssAboveVoiceDb = 'de_ess_above_voice_db';
  static const String deEssAttackS = 'de_ess_attack_s';
  static const String deEssDb = 'de_ess_db';
  static const String deEssHighHz = 'de_ess_high_hz';
  static const String deEssLowHz = 'de_ess_low_hz';
  static const String deEssReleaseS = 'de_ess_release_s';
  static const String expanderBelowDb = 'expander_below_db';
  static const String expanderCloseS = 'expander_close_s';
  static const String expanderFloorDb = 'expander_floor_db';
  static const String expanderOpenS = 'expander_open_s';
  static const String expanderRatio = 'expander_ratio';
  static const String highPassHz = 'high_pass_hz';
  static const String limiterLookaheadS = 'limiter_lookahead_s';
  static const String limiterMakeupMaxDb = 'limiter_makeup_max_db';
  static const String limiterReleaseS = 'limiter_release_s';
  static const String maxGainDb = 'max_gain_db';
  static const String monoWidthDb = 'mono_width_db';
  static const String monoWidthHighHz = 'mono_width_high_hz';
  static const String monoWidthLowHz = 'mono_width_low_hz';
  static const String mudCutDb = 'mud_cut_db';
  static const String mudHz = 'mud_hz';
  static const String noiseProfileSeconds = 'noise_profile_seconds';
  static const String noiseReductionDb = 'noise_reduction_db';
  static const String noiseSensitivity = 'noise_sensitivity';
  static const String noiseTransitionDb = 'noise_transition_db';
  static const String presenceDb = 'presence_db';
  static const String presenceHz = 'presence_hz';
  static const String targetLufs = 'target_lufs';
  static const String toneMaxBoostDb = 'tone_max_boost_db';
  static const String toneMaxCutDb = 'tone_max_cut_db';
  static const String toneNoBoostBelowHz = 'tone_no_boost_below_hz';
  static const String trimAboveNoiseDb = 'trim_above_noise_db';
  static const String trimBelowLoudDb = 'trim_below_loud_db';
  static const String trimFadeS = 'trim_fade_s';
  static const String trimPaddingS = 'trim_padding_s';
  static const String trimSilence = 'trim_silence';
  static const String trimSilenceBelowLoudDb = 'trim_silence_below_loud_db';
  static const String truePeakDb = 'true_peak_db';
  static const String widenMono = 'widen_mono';
}
