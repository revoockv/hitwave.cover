import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/repositories/playback_repository.dart';
import '../data_sources/audio_player_data_source.dart';

/// [PlaybackRepository] on one audio player.
///
/// The original take is clipped to the part the enhanced file covers (the silence trimmed from
/// the enhanced one is skipped in the original too), so switching between them compares the
/// same singing.
final class PlaybackRepositoryImpl implements PlaybackRepository, DisposableResource {
  static const int _millisecondsPerSecond = 1000;
  static const String _playError = 'Не вдалося відтворити запис';
  static const String _playLog = 'PlayRecording: ';
  static const String _successLog = 'success — ';
  static const String _failureLog = 'failure — ';

  final AudioPlayerDataSource _player;
  final Logger _logger;

  final ValueNotifier<PlaybackState> _state = ValueNotifier<PlaybackState>(PlaybackState.stopped);
  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];

  /// Creates a [PlaybackRepositoryImpl] and follows the player.
  PlaybackRepositoryImpl({required this._player, required this._logger}) {
    _subscriptions
      ..add(_player.positions.listen(_onPosition))
      ..add(_player.playingChanges.listen(_onPlaying))
      ..add(_player.completions.listen(_onCompleted));
  }

  /// Stops listening, releases the player and the state.
  @override
  Future<void> dispose() async {
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    _state.dispose();
  }

  @override
  ValueListenable<PlaybackState> watchPlayback() => _state;

  @override
  Future<Result<void>> play({required Recording recording, required RecordingVersion version}) async {
    final String? enhanced = recording.enhancedPath;
    final bool playEnhanced = version == RecordingVersion.enhanced && enhanced != null;
    try {
      final Duration duration = playEnhanced
          ? await _player.open(enhanced)
          : await _player.open(
              recording.rawPath,
              start: _duration(recording.keptFromSeconds),
              end: recording.keptToSeconds == null ? null : _duration(recording.keptToSeconds!),
            );
      _state.value = PlaybackState(
        recordingId: recording.id,
        version: playEnhanced ? RecordingVersion.enhanced : RecordingVersion.original,
        isPlaying: true,
        position: Duration.zero,
        duration: duration,
      );
      await _player.play();
      _logger.i('$_playLog$_successLog${recording.id}');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_playLog$_failureLog$e');
      _state.value = PlaybackState.stopped;
      return const Result.failure(_playError);
    }
  }

  @override
  Future<Result<void>> togglePause() async {
    final PlaybackState state = _state.value;
    if (state.recordingId == null) return Result.ok;
    try {
      if (state.isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_playLog$_failureLog$e');
      return const Result.failure(_playError);
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _player.stop();
    } on Exception catch (e) {
      _logger.e('$_playLog$_failureLog$e');
    }
    _state.value = PlaybackState.stopped;
    return Result.ok;
  }

  void _onPosition(Duration position) {
    final PlaybackState state = _state.value;
    if (state.recordingId == null) return;
    _state.value = _copy(state, position: position);
  }

  void _onPlaying(bool isPlaying) {
    final PlaybackState state = _state.value;
    if (state.recordingId == null) return;
    _state.value = _copy(state, isPlaying: isPlaying);
  }

  void _onCompleted(void _) {
    unawaited(stop());
  }

  static PlaybackState _copy(PlaybackState state, {Duration? position, bool? isPlaying}) => PlaybackState(
    recordingId: state.recordingId,
    version: state.version,
    isPlaying: isPlaying ?? state.isPlaying,
    position: position ?? state.position,
    duration: state.duration,
  );

  static Duration _duration(double seconds) => Duration(milliseconds: (seconds * _millisecondsPerSecond).round());
}
