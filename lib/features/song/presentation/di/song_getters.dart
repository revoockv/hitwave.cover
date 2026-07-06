import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get_it/get_it.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/add_cover_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/add_song_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/delete_cover_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/delete_song_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/update_cover_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/update_song_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/watch_list_of_songs_use_case.dart';
import 'package:watch_it/watch_it.dart';

/// Returns the watch list of songs use case.
ValueNotifier<List<Song>> get watchListOfSongsUseCase {
  return GetIt.instance<WatchListOfSongsUseCase>()();
}

/// Returns the add song use case.
AddSongUseCase get addSongUseCase {
  return GetIt.instance<AddSongUseCase>();
}

/// Returns the update song use case.
UpdateSongUseCase get updateSongUseCase {
  return GetIt.instance<UpdateSongUseCase>();
}

/// Returns the delete song use case.
DeleteSongUseCase get deleteSongUseCase {
  return GetIt.instance<DeleteSongUseCase>();
}

/// Returns the add cover use case.
AddCoverUseCase get addCoverUseCase {
  return GetIt.instance<AddCoverUseCase>();
}

/// Returns the update cover use case.
UpdateCoverUseCase get updateCoverUseCase {
  return GetIt.instance<UpdateCoverUseCase>();
}

/// Returns the delete cover use case.
DeleteCoverUseCase get deleteCoverUseCase {
  return GetIt.instance<DeleteCoverUseCase>();
}
