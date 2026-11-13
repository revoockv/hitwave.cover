import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:glint_audio_pure/glint_audio_pure.dart';

import '../models/wav_pcm_model.dart';

/// Turns a WAV file into an MP3 file (192 kbit/s) with a pure-Dart encoder, in a background
/// isolate so the interface keeps moving. Works the same on every platform.
class Mp3EncoderService {
  static const int _bitrate = 192;
  static const String _rateError = 'MP3 does not support the sample rate ';
  static const String _hertz = ' Hz';
  static const String _partSuffix = '.part';
  static const String _wavSuffix = '.wav';
  static const String _mp3Suffix = '.mp3';

  /// Where the MP3 of the WAV file at [wavPath] is kept: beside it, `.mp3` for `.wav`.
  static String mp3PathOf(String wavPath) => '${wavPath.substring(0, wavPath.length - _wavSuffix.length)}$_mp3Suffix';

  /// Writes the MP3 of the WAV file at [wavPath] to [mp3Path].
  Future<void> encode({required String wavPath, required String mp3Path}) =>
      Isolate.run(() => _encode(wavPath, mp3Path));

  static Future<void> _encode(String wavPath, String mp3Path) async {
    final WavPcmModel wav = WavPcmModel.fromBytes(await File(wavPath).readAsBytes());
    if (!kMp3SampleRates.contains(wav.sampleRate)) {
      throw FormatException('$_rateError${wav.sampleRate}$_hertz');
    }
    final Uint8List mp3 = wav.channels.length == 1
        ? mp3EncodeMono(wav.channels.first, sampleRate: wav.sampleRate, bitrate: _bitrate)
        : mp3EncodeJointStereo(wav.channels[0], wav.channels[1], sampleRate: wav.sampleRate, bitrate: _bitrate);
    final File temporary = File('$mp3Path$_partSuffix');
    await temporary.writeAsBytes(mp3, flush: true);
    await temporary.rename(mp3Path);
  }
}
