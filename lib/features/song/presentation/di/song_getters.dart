import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/add_cover_use_case.dart';
import '../../domain/use_cases/add_song_use_case.dart';
import '../../domain/use_cases/delete_all_songs_use_case.dart';
import '../../domain/use_cases/delete_cover_use_case.dart';
import '../../domain/use_cases/delete_song_use_case.dart';
import '../../domain/use_cases/find_tab_blocks_use_case.dart';
import '../../domain/use_cases/update_cover_use_case.dart';
import '../../domain/use_cases/update_song_lead_in_use_case.dart';
import '../../domain/use_cases/update_song_lyrics_use_case.dart';
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

/// The use case that saves the space above the lyrics of a song.
UpdateSongLeadInUseCase get updateSongLeadInUseCase => di<UpdateSongLeadInUseCase>();

/// The use case that saves the lyrics of a song edited on the lyrics page.
UpdateSongLyricsUseCase get updateSongLyricsUseCase => di<UpdateSongLyricsUseCase>();

/// The use case that deletes a song.
DeleteSongUseCase get deleteSongUseCase => di<DeleteSongUseCase>();

/// The use case that adds a cover to a song.
AddCoverUseCase get addCoverUseCase => di<AddCoverUseCase>();

/// The use case that updates a cover.
UpdateCoverUseCase get updateCoverUseCase => di<UpdateCoverUseCase>();

/// The use case that deletes a cover.
DeleteCoverUseCase get deleteCoverUseCase => di<DeleteCoverUseCase>();

/// The use case that deletes every song of the library with its covers.
DeleteAllSongsUseCase get deleteAllSongsUseCase => di<DeleteAllSongsUseCase>();

/// The use case that finds the tablatures in the lyrics of a song.
FindTabBlocksUseCase get findTabBlocksUseCase => di<FindTabBlocksUseCase>();
