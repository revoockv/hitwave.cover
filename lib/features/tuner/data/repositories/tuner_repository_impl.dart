import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/tuner_failure.dart';
import '../../domain/entities/tuner_state.dart';
import '../../domain/repositories/tuner_repository.dart';
import '../data_sources/pitch_data_source.dart';

/// [TunerRepository] over a [PitchDataSource]. Steadies the heard pitch: the median of the last [_steadyCount]
/// pitches outvotes a stray one, then a small step from the shown pitch is smoothed ([_smoothing]) while a jump
/// (another string) is shown at once; a pitch is kept for [_holdCount] pieces without a clear one, so the needle
/// does not jump while a string fades.
///
/// Starting and stopping run one after another, so hiding and showing the app quickly never opens the microphone
/// while it still closes.
final class TunerRepositoryImpl implements TunerRepository, DisposableResource {
  static const int _steadyCount = 3;

  /// About a third of a second at the pace of the data source.
  static const int _holdCount = 15;

  /// The share of a small step taken at once; the rest comes with the next pitches.
  static const double _smoothing = 0.35;

  /// A step from the shown pitch above this many cents is a new note: no smoothing.
  static const double _jumpCents = 30;

  static const double _centsPerOctave = 1200;
  static const String _startFailureLog = 'tuner: could not start: ';
  static const String _stopFailureLog = 'tuner: could not stop: ';
  static const String _streamFailureLog = 'tuner: the microphone failed: ';

  final PitchDataSource _dataSource;
  final Logger _logger;

  final ValueNotifier<TunerState> _state = ValueNotifier<TunerState>(TunerState.off);
  final List<double> _recent = <double>[];
  StreamSubscription<double?>? _pitches;
  Future<void> _queue = Future<void>.value();
  double? _shown;
  int _missed = 0;

  /// Creates a [TunerRepositoryImpl].
  TunerRepositoryImpl({required this._dataSource, required this._logger});

  @override
  ValueListenable<TunerState> watchTuner() => _state;

  @override
  Future<Result<void, TunerFailure>> start() => _serially(_start);

  @override
  Future<void> stop() => _serially(_stop);

  /// Runs [action] after the start or stop that runs now.
  Future<T> _serially<T>(Future<T> Function() action) {
    final Future<T> result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Result<void, TunerFailure>> _start() async {
    if (_pitches != null) return Result.ok;
    try {
      if (!await _dataSource.hasPermission()) return const Result.failure(TunerFailure.microphonePermission);
      final Stream<double?> pitches = await _dataSource.listen();
      _recent.clear();
      _shown = null;
      _missed = 0;
      _state.value = const ListeningTunerState(null);
      late final StreamSubscription<double?> subscription;
      subscription = pitches.listen(
        _onPitch,
        onError: (Object error) => _logger.w('$_streamFailureLog$error'),
        onDone: () => _onDone(subscription),
      );
      _pitches = subscription;
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_startFailureLog$e');
      return const Result.failure(TunerFailure.start);
    }
  }

  Future<void> _stop() async {
    final StreamSubscription<double?>? pitches = _pitches;
    if (pitches == null) return;
    _pitches = null;
    _state.value = TunerState.off;
    try {
      await pitches.cancel();
      await _dataSource.stop();
    } on Exception catch (e) {
      _logger.w('$_stopFailureLog$e');
    }
  }

  /// The system ended the microphone stream: the tuner is off, and the next start opens it again.
  void _onDone(StreamSubscription<double?> subscription) {
    if (!identical(_pitches, subscription)) return;
    _pitches = null;
    _state.value = TunerState.off;
  }

  void _onPitch(double? hertz) {
    if (hertz == null) {
      if (++_missed < _holdCount) return;
      _recent.clear();
      _shown = null;
      _state.value = const ListeningTunerState(null);
      return;
    }
    _missed = 0;
    _recent.add(hertz);
    if (_recent.length > _steadyCount) _recent.removeAt(0);
    final List<double> sorted = List<double>.of(_recent)..sort();
    final double steady = sorted[sorted.length ~/ 2];
    final double? shown = _shown;
    final double next = shown == null || _centsBetween(shown, steady).abs() > _jumpCents
        ? steady
        : shown * math.pow(steady / shown, _smoothing);
    _shown = next;
    _state.value = ListeningTunerState(next);
  }

  static double _centsBetween(double from, double to) => _centsPerOctave * math.log(to / from) / math.ln2;

  @override
  Future<void> dispose() async {
    await stop();
    await _dataSource.dispose();
    _state.dispose();
  }
}
