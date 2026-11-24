import 'dart:typed_data';

import 'package:record/record.dart';

import 'pcm_pitch_framer.dart';
import 'pitch_data_source.dart';
import 'yin_pitch_detector.dart';

/// [PitchDataSource] on the `record` package: 16-bit PCM from the microphone, halved to 24 kHz
/// and analyzed by [YinPitchDetector] every [_hopSize] samples.
final class RecordPitchDataSource implements PitchDataSource {
  static const int _sampleRate = 48000;
  static const int _decimation = 2;
  static const int _hopSize = 2048;

  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: _sampleRate,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.unprocessed, manageBluetooth: false),
  );

  final AudioRecorder _recorder = AudioRecorder();
  final YinPitchDetector _detector = const YinPitchDetector(sampleRate: _sampleRate / _decimation);

  /// Creates a [RecordPitchDataSource].
  RecordPitchDataSource();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<double?>> listen() async {
    final Stream<Uint8List> bytes = await _recorder.startStream(_config);
    final PcmPitchFramer framer = PcmPitchFramer(_detector, decimation: _decimation, hopSize: _hopSize);
    return bytes.expand(framer.add);
  }

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
