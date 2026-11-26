import 'dart:typed_data';

import 'package:record/record.dart';

import 'pcm_pitch_framer.dart';
import 'pitch_data_source.dart';
import 'yin_pitch_detector.dart';

/// [PitchDataSource] on the `record` package: 16-bit PCM from the microphone in small chunks, analyzed by
/// [YinPitchDetector] every [_hopSize] samples (about 47 pitches a second).
final class RecordPitchDataSource implements PitchDataSource {
  static const int _sampleRate = 48000;
  static const int _hopSize = 1024;

  /// Small chunks, so a pitch is not held back: without it Android sends ~100 ms at once, macOS 100 ms.
  /// Bytes on Android (512 samples), frames on iOS and macOS.
  static const int _streamBufferSize = 1024;

  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: _sampleRate,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    // A call or another app takes the microphone for a while: the tuner listens again after it.
    audioInterruption: AudioInterruptionMode.pauseResume,
    streamBufferSize: _streamBufferSize,
    androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.unprocessed, manageBluetooth: false),
  );

  final AudioRecorder _recorder = AudioRecorder();
  final YinPitchDetector _detector = const YinPitchDetector(sampleRate: _sampleRate * 1.0);

  /// Creates a [RecordPitchDataSource].
  RecordPitchDataSource();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<double?>> listen() async {
    final Stream<Uint8List> bytes = await _recorder.startStream(_config);
    final PcmPitchFramer framer = PcmPitchFramer(_detector, hopSize: _hopSize);
    return bytes.expand(framer.add);
  }

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
