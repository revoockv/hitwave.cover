import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/is_sync_supported_use_case.dart';
import '../../domain/use_cases/resolve_sync_conflicts_use_case.dart';
import '../../domain/use_cases/start_sync_hosting_use_case.dart';
import '../../domain/use_cases/stop_sync_use_case.dart';
import '../../domain/use_cases/sync_with_device_use_case.dart';
import '../../domain/use_cases/watch_sync_state_use_case.dart';

/// The use case that watches the synchronisation; call it to get the [ValueListenable].
WatchSyncStateUseCase get watchSyncStateUseCase => di<WatchSyncStateUseCase>();

/// The use case that tells whether this platform can synchronise.
IsSyncSupportedUseCase get isSyncSupportedUseCase => di<IsSyncSupportedUseCase>();

/// The use case that makes this device wait for another one.
StartSyncHostingUseCase get startSyncHostingUseCase => di<StartSyncHostingUseCase>();

/// The use case that synchronises with the device showing a code.
SyncWithDeviceUseCase get syncWithDeviceUseCase => di<SyncWithDeviceUseCase>();

/// The use case that stops the synchronisation.
StopSyncUseCase get stopSyncUseCase => di<StopSyncUseCase>();

/// The use case that goes on with a synchronisation after the conflicts are decided.
ResolveSyncConflictsUseCase get resolveSyncConflictsUseCase => di<ResolveSyncConflictsUseCase>();
