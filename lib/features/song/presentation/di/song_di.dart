import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get_it/get_it.dart';

import '../../data/datasources/firebase_song_service.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../../domain/use_cases/add_cover_use_case.dart';
import '../../domain/use_cases/add_song_use_case.dart';
import '../../domain/use_cases/delete_cover_use_case.dart';
import '../../domain/use_cases/delete_song_use_case.dart';
import '../../domain/use_cases/update_cover_use_case.dart';
import '../../domain/use_cases/update_song_use_case.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';

/// Registers all song feature dependencies in GetIt.
///
/// Creates singleton instances for the Firebase song service and the song
/// repository implementation, then registers the songs ValueNotifier with
/// the instance key `song.songs`. Registers all use cases as singletons.
Future<void> registerSongFeature() async {
  final getIt = GetIt.instance;

  getIt.registerSingleton<FirebaseSongService>(
    FirebaseSongService(
      firestore: FirebaseFirestore.instance,
    ),
  );

  final repository = SongRepositoryImpl(
    songService: getIt<FirebaseSongService>(),
    auth: firebase_auth.FirebaseAuth.instance,
    logger: getIt.get(),
  );

  getIt.registerSingleton<SongRepository>(
    repository,
  );

  getIt.registerSingleton<ValueNotifier<List<Song>>>(
    repository.songs,
    instanceName: 'song.songs',
  );

  getIt.registerSingleton<WatchListOfSongsUseCase>(WatchListOfSongsUseCase(repository));
  getIt.registerSingleton<AddSongUseCase>(AddSongUseCase(repository));
  getIt.registerSingleton<UpdateSongUseCase>(UpdateSongUseCase(repository));
  getIt.registerSingleton<DeleteSongUseCase>(DeleteSongUseCase(repository));
  getIt.registerSingleton<AddCoverUseCase>(AddCoverUseCase(repository));
  getIt.registerSingleton<UpdateCoverUseCase>(UpdateCoverUseCase(repository));
  getIt.registerSingleton<DeleteCoverUseCase>(DeleteCoverUseCase(repository));
}

/// Initializes the song feature after registration.
///
/// Starts the repository's subscription to Firestore, which feeds the
/// songs [ValueNotifier].
Future<void> initSongFeature() async {
  final repository = GetIt.instance<SongRepository>();
  await repository.init();
}
