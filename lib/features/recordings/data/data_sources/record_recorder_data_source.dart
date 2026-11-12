import 'package:record/record.dart';

import '../../domain/entities/microphone.dart';
import 'recorder_data_source.dart';

/// [RecorderDataSource] on the `record` package.
///
/// Sung vocals need the microphone as it is: the voice-call effects of the system (automatic
/// gain, noise suppression, echo cancellation) are off, and on Android the `voiceRecognition`
/// source is used, which the Android compatibility rules require to be unprocessed. On iOS the
/// Bluetooth hands-free microphone (8–16 kHz) is not allowed; Bluetooth stays only for output.
final class RecordRecorderDataSource implements RecorderDataSource {
  static const int _sampleRate = 48000;
  static const int _channels = 1;
  static const double _silenceDb = -60;

  static const RecordConfig _config = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: _sampleRate,
    numChannels: _channels,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    androidConfig: AndroidRecordConfig(audioSource: AndroidAudioSource.voiceRecognition, manageBluetooth: false),
    iosConfig: IosRecordConfig(
      categoryOptions: <IosAudioCategoryOption>[
        IosAudioCategoryOption.defaultToSpeaker,
        IosAudioCategoryOption.allowBluetoothA2DP,
      ],
    ),
  );

  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<List<Microphone>> microphones() async => <Microphone>[
    for (final InputDevice device in await _recorder.listInputDevices()) Microphone(id: device.id, label: device.label),
  ];

  @override
  Future<void> start(String path, {String? microphoneId}) async {
    InputDevice? device;
    if (microphoneId != null) {
      for (final InputDevice input in await _recorder.listInputDevices()) {
        if (input.id == microphoneId) device = input;
      }
    }
    await _recorder.start(_config.copyWith(device: (value: device)), path: path);
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<double> level() async {
    final Amplitude amplitude = await _recorder.getAmplitude();
    return ((amplitude.current - _silenceDb) / -_silenceDb).clamp(0.0, 1.0);
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
