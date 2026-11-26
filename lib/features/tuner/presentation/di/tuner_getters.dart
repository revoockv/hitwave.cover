import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/start_tuner_use_case.dart';
import '../../domain/use_cases/stop_tuner_use_case.dart';
import '../../domain/use_cases/watch_tuner_use_case.dart';

/// The use case that watches the tuner; call it to get the [ValueListenable].
WatchTunerUseCase get watchTunerUseCase => di<WatchTunerUseCase>();

/// The use case that starts the tuner.
StartTunerUseCase get startTunerUseCase => di<StartTunerUseCase>();

/// The use case that stops the tuner.
StopTunerUseCase get stopTunerUseCase => di<StopTunerUseCase>();
