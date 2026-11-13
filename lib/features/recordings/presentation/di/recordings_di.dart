import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../../../../core/presentation/di/core_di.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../../vocal_enhance/domain/repositories/vocal_enhance_repository.dart';
import '../../data/data_sources/audio_player_data_source.dart';
import '../../data/data_sources/hive_recording_preferences_service.dart';
import '../../data/data_sources/hive_recording_service.dart';
import '../../data/data_sources/just_audio_player_data_source.dart';
import '../../data/data_sources/record_recorder_data_source.dart';
import '../../data/data_sources/recorder_data_source.dart';
import '../../data/repositories/playback_repository_impl.dart';
import '../../data/repositories/recording_preferences_repository_impl.dart';
import '../../data/repositories/recordings_repository_impl.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/repositories/recording_preferences_repository.dart';
import '../../domain/repositories/recordings_repository.dart';
import '../../domain/use_cases/delete_recording_use_case.dart';
import '../../domain/use_cases/enhance_recording_again_use_case.dart';
import '../../domain/use_cases/play_recording_use_case.dart';
import '../../domain/use_cases/start_recording_use_case.dart';
import '../../domain/use_cases/stop_playback_use_case.dart';
import '../../domain/use_cases/stop_recording_use_case.dart';
import '../../domain/use_cases/toggle_playback_pause_use_case.dart';
import '../../domain/use_cases/update_recording_preferences_use_case.dart';
import '../../domain/use_cases/watch_playback_use_case.dart';
import '../../domain/use_cases/watch_recorder_use_case.dart';
import '../../domain/use_cases/watch_recording_preferences_use_case.dart';
import '../../domain/use_cases/watch_recordings_use_case.dart';

/// Registers the recordings feature; the library waits for Hive and the song repository.
void registerAndInitRecordings() {
  // 1. data sources
  di.registerSingletonAsync<HiveRecordingService>(
    () => HiveRecordingService(storage: di<LocalStorageService>()).init(),
    dependsOn: <Type>[LocalStorageService],
  );
  di.registerSingletonAsync<HiveRecordingPreferencesService>(
    () => HiveRecordingPreferencesService(storage: di<LocalStorageService>()).init(),
    dependsOn: <Type>[LocalStorageService],
  );
  di.registerLazySingleton<RecorderDataSource>(RecordRecorderDataSource.new);
  di.registerLazySingleton<AudioPlayerDataSource>(JustAudioPlayerDataSource.new);

  // 2. repositories
  di.registerSingletonAsync<RecordingsRepository>(
    () => RecordingsRepositoryImpl(
      store: di<HiveRecordingService>(),
      recorder: di<RecorderDataSource>(),
      engine: di<VocalEnhanceRepository>(),
      songs: di<SongRepository>(),
      logger: di<Logger>(),
    ).init(),
    dependsOn: <Type>[HiveRecordingService, SongRepository],
    dispose: disposeResource,
  );
  di.registerSingletonWithDependencies<RecordingPreferencesRepository>(
    () => RecordingPreferencesRepositoryImpl(store: di<HiveRecordingPreferencesService>(), logger: di<Logger>()).init(),
    dependsOn: <Type>[HiveRecordingPreferencesService],
    dispose: disposeResource,
  );
  di.registerLazySingleton<PlaybackRepository>(
    () => PlaybackRepositoryImpl(player: di<AudioPlayerDataSource>(), logger: di<Logger>()),
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<StartRecordingUseCase>(() => StartRecordingUseCase(di<RecordingsRepository>()));
  di.registerLazySingleton<StopRecordingUseCase>(() => StopRecordingUseCase(di<RecordingsRepository>()));
  di.registerLazySingleton<EnhanceRecordingAgainUseCase>(
    () => EnhanceRecordingAgainUseCase(di<RecordingsRepository>()),
  );
  di.registerLazySingleton<DeleteRecordingUseCase>(() => DeleteRecordingUseCase(di<RecordingsRepository>()));
  di.registerLazySingleton<WatchRecordingsUseCase>(() => WatchRecordingsUseCase(di<RecordingsRepository>()));
  di.registerLazySingleton<WatchRecorderUseCase>(() => WatchRecorderUseCase(di<RecordingsRepository>()));
  di.registerLazySingleton<PlayRecordingUseCase>(() => PlayRecordingUseCase(di<PlaybackRepository>()));
  di.registerLazySingleton<TogglePlaybackPauseUseCase>(() => TogglePlaybackPauseUseCase(di<PlaybackRepository>()));
  di.registerLazySingleton<StopPlaybackUseCase>(() => StopPlaybackUseCase(di<PlaybackRepository>()));
  di.registerLazySingleton<WatchPlaybackUseCase>(() => WatchPlaybackUseCase(di<PlaybackRepository>()));
  di.registerLazySingleton<WatchRecordingPreferencesUseCase>(
    () => WatchRecordingPreferencesUseCase(di<RecordingPreferencesRepository>()),
  );
  di.registerLazySingleton<UpdateRecordingPreferencesUseCase>(
    () => UpdateRecordingPreferencesUseCase(di<RecordingPreferencesRepository>()),
  );
}
