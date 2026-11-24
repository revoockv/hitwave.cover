import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/tuner_failure.dart';
import '../../domain/entities/tuner_state.dart';
import '../../domain/repositories/tuner_repository.dart';
import '../data_sources/pitch_data_source.dart';

/// [TunerRepository] over a [PitchDataSource]: steadies the heard pitch with the median of the last
/// [_steadyCount] pitches and keeps it for [_holdCount] pieces without a clear one, so the needle does
/// not jump while a string fades.
final class TunerRepositoryImpl implements TunerRepository, DisposableResource {
  static const int _steadyCount = 3;
  static const int _holdCount = 4;
  static const String _startFailureLog = 'tuner: could not start: ';
  static const String _stopFailureLog = 'tuner: could not stop: ';

  final PitchDataSource _dataSource;
  final Logger _logger;

  final ValueNotifier<TunerState> _state = ValueNotifier<TunerState>(TunerState.off);
  final List<double> _recent = <double>[];
  StreamSubscription<double?>? _pitches;
  int _missed = 0;

  /// Creates a [TunerRepositoryImpl].
  TunerRepositoryImpl({required this._dataSource, required this._logger});

  @override
  ValueListenable<TunerState> watchTuner() => _state;

  @override
  Future<Result<void, TunerFailure>> start() async {
    if (_pitches != null) return Result.ok;
    try {
      if (!await _dataSource.hasPermission()) return const Result.failure(TunerFailure.microphonePermission);
      final Stream<double?> pitches = await _dataSource.listen();
      _recent.clear();
      _missed = 0;
      _state.value = const ListeningTunerState(null);
      _pitches = pitches.listen(_onPitch);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_startFailureLog$e');
      return const Result.failure(TunerFailure.start);
    }
  }

  @override
  Future<void> stop() async {
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

  void _onPitch(double? hertz) {
    if (hertz == null) {
      if (++_missed < _holdCount) return;
      _recent.clear();
      _state.value = const ListeningTunerState(null);
      return;
    }
    _missed = 0;
    _recent.add(hertz);
    if (_recent.length > _steadyCount) _recent.removeAt(0);
    final List<double> sorted = List<double>.of(_recent)..sort();
    _state.value = ListeningTunerState(sorted[sorted.length ~/ 2]);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _dataSource.dispose();
    _state.dispose();
  }
}
