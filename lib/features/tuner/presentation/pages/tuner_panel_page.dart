import 'dart:async';

import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/tuner_failure.dart';
import '../controllers/tuner_controller.dart';
import '../di/tuner_getters.dart';
import '../wrappers/tuner_panel_wrapper.dart';

/// The tuner wherever it is placed (the home tab, the tuner page): owns the [TunerController], opens the microphone
/// when shown and frees it when it goes away or the app is hidden (listening again when the app is shown). Never rebuilds — its wrappers follow the state.
final class TunerPanelPage extends WatchingWidget {
  /// Creates a [TunerPanelPage].
  const TunerPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TunerController tunerController = createOnce(TunerController.new, dispose: _disposeTunerController);
    callOnceAfterThisBuild((BuildContext context) => _start(tunerController));
    // A hidden app loses the microphone: the tuner frees it and listens again when the app is shown.
    createOnce(
      () => AppLifecycleListener(
        onHide: () => unawaited(stopTunerUseCase()),
        onShow: () => unawaited(_start(tunerController)),
      ),
      dispose: _disposeLifecycleListener,
    );
    return TunerPanelWrapper(tunerController: tunerController, onRetryPressed: () => _start(tunerController));
  }

  /// Starts the tuner and records the outcome; ignored while a start runs.
  Future<void> _start(TunerController tunerController) async {
    final ValueNotifier<ResultState<void, TunerFailure>> startStateController = tunerController.startStateController;
    if (tunerController.isDisposed || startStateController.value.isLoading) return;
    startStateController.value = ResultState.loading;
    final Result<void, TunerFailure> result = await startTunerUseCase();
    if (tunerController.isDisposed) return;
    startStateController.value = ResultState.of(result);
  }

  static void _disposeLifecycleListener(AppLifecycleListener listener) => listener.dispose();

  /// Frees the microphone when the tuner goes away.
  static void _disposeTunerController(TunerController tunerController) {
    unawaited(stopTunerUseCase());
    tunerController.dispose();
  }
}
