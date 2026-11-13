import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/data_sources/firebase_song_service.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/use_cases/add_cover_use_case.dart';
import '../../domain/use_cases/add_song_use_case.dart';
import '../../domain/use_cases/delete_cover_use_case.dart';
import '../../domain/use_cases/delete_song_use_case.dart';
import '../../domain/use_cases/update_cover_use_case.dart';
import '../../domain/use_cases/update_song_use_case.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';

/// Registers the song feature and starts its async initialization.
///
/// The repository waits for [AuthRepository], which initializes Firebase,
/// then subscribes to the songs of the signed-in user.
void registerAndInitSong() {
  // 1. data sources
  di.registerLazySingleton<FirebaseSongService>(
    () => FirebaseSongService(firestore: FirebaseFirestore.instance),
  );

  // 2. repositories — async init: subscribes to Firestore
  di.registerSingletonAsync<SongRepository>(
    () => SongRepositoryImpl(
      songService: di<FirebaseSongService>(),
      auth: firebase_auth.FirebaseAuth.instance,
      logger: di<Logger>(),
    ).init(),
    dependsOn: <Type>[AuthRepository],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<WatchListOfSongsUseCase>(() => WatchListOfSongsUseCase(di<SongRepository>()));
  di.registerLazySingleton<AddSongUseCase>(() => AddSongUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateSongUseCase>(() => UpdateSongUseCase(di<SongRepository>()));
  di.registerLazySingleton<DeleteSongUseCase>(() => DeleteSongUseCase(di<SongRepository>()));
  di.registerLazySingleton<AddCoverUseCase>(() => AddCoverUseCase(di<SongRepository>()));
  di.registerLazySingleton<UpdateCoverUseCase>(() => UpdateCoverUseCase(di<SongRepository>()));
  di.registerLazySingleton<DeleteCoverUseCase>(() => DeleteCoverUseCase(di<SongRepository>()));
}
