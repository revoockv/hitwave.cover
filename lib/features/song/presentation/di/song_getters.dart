import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/add_cover_use_case.dart';
import '../../domain/use_cases/add_song_use_case.dart';
import '../../domain/use_cases/delete_cover_use_case.dart';
import '../../domain/use_cases/delete_song_use_case.dart';
import '../../domain/use_cases/update_cover_use_case.dart';
import '../../domain/use_cases/update_song_scroll_speed_use_case.dart';
import '../../domain/use_cases/update_song_use_case.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';

/// The use case that watches the list of songs; call it to get the [ValueListenable].
WatchListOfSongsUseCase get watchListOfSongsUseCase => di<WatchListOfSongsUseCase>();

/// The use case that adds a song.
AddSongUseCase get addSongUseCase => di<AddSongUseCase>();

/// The use case that updates a song.
UpdateSongUseCase get updateSongUseCase => di<UpdateSongUseCase>();

/// The use case that saves the auto-scroll speed of a song.
UpdateSongScrollSpeedUseCase get updateSongScrollSpeedUseCase => di<UpdateSongScrollSpeedUseCase>();

/// The use case that deletes a song.
DeleteSongUseCase get deleteSongUseCase => di<DeleteSongUseCase>();

/// The use case that adds a cover to a song.
AddCoverUseCase get addCoverUseCase => di<AddCoverUseCase>();

/// The use case that updates a cover.
UpdateCoverUseCase get updateCoverUseCase => di<UpdateCoverUseCase>();

/// The use case that deletes a cover.
DeleteCoverUseCase get deleteCoverUseCase => di<DeleteCoverUseCase>();
