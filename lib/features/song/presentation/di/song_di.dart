import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/hive_song_service.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/use_cases/add_cover_use_case.dart';
import '../../domain/use_cases/add_song_use_case.dart';
import '../../domain/use_cases/delete_all_songs_use_case.dart';
import '../../domain/use_cases/delete_cover_use_case.dart';
import '../../domain/use_cases/delete_song_use_case.dart';
import '../../domain/use_cases/update_cover_use_case.dart';
import '../../domain/use_cases/update_song_lead_in_use_case.dart';
import '../../domain/use_cases/update_song_lyrics_use_case.dart';
import '../../domain/use_cases/update_song_scroll_speed_use_case.dart';
import '../../domain/use_cases/update_song_use_case.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';

/// Registers the song feature and starts its async initialization.
///
/// The repository waits for the songs on the device (Hive).
void registerAndInitSong() {
  // 1. data sources
  // async init: opens the Hive boxes of the songs on the device
  di.registerSingletonAsync<HiveSongService>(
    () => HiveSongService(storage: di<LocalStorageService>()).init(),
    dependsOn: <Type>[LocalStorageService],
  );

  // 2. repositories — async init: subscribes to the songs
  di.registerSingletonAsync<SongRepository>(
    () => SongRepositoryImpl(dataSource: di<HiveSongService>(), logger: di<Logger>()).init(),
    dependsOn: <Type>[HiveSongService],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchListOfSongsUseCase>(() => WatchListOfSongsUseCase(di<SongRepository>()));
  di.registerLazySingleton<AddSongUseCase>(() => AddSongUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateSongUseCase>(() => UpdateSongUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateSongScrollSpeedUseCase>(() => UpdateSongScrollSpeedUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateSongLeadInUseCase>(() => UpdateSongLeadInUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateSongLyricsUseCase>(() => UpdateSongLyricsUseCase(di<SongRepository>()));
  di.registerLazySingleton<DeleteSongUseCase>(() => DeleteSongUseCase(di<SongRepository>()));
  di.registerLazySingleton<DeleteAllSongsUseCase>(() => DeleteAllSongsUseCase(di<SongRepository>()));
  di.registerLazySingleton<AddCoverUseCase>(() => AddCoverUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateCoverUseCase>(() => UpdateCoverUseCase(di<SongRepository>()));
  di.registerLazySingleton<DeleteCoverUseCase>(() => DeleteCoverUseCase(di<SongRepository>()));
}
