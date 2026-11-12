import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'audio_player_data_source.dart';

/// [AudioPlayerDataSource] on `just_audio`.
final class JustAudioPlayerDataSource implements AudioPlayerDataSource {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positions => _player.positionStream;

  @override
  Stream<bool> get playingChanges => _player.playingStream;

  @override
  Stream<void> get completions =>
      _player.processingStateStream.where((ProcessingState state) => state == ProcessingState.completed);

  @override
  Future<Duration> open(String path, {Duration? start, Duration? end}) async {
    final UriAudioSource file = AudioSource.file(path);
    final AudioSource source = start == null && end == null
        ? file
        : ClippingAudioSource(child: file, start: start, end: end);
    final Duration? duration = await _player.setAudioSource(source);
    return duration ?? Duration.zero;
  }

  @override
  Future<void> play() async {
    // `play()` completes when playback ends; only wait until it has started.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
