import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/add_cover_use_case.dart';
import '../../domain/use_cases/add_song_use_case.dart';
import '../../domain/use_cases/delete_cover_use_case.dart';
import '../../domain/use_cases/delete_song_use_case.dart';
import '../../domain/use_cases/keep_local_songs_use_case.dart';
import '../../domain/use_cases/transfer_local_songs_use_case.dart';
import '../../domain/use_cases/update_cover_use_case.dart';
import '../../domain/use_cases/update_song_lead_in_use_case.dart';
import '../../domain/use_cases/update_song_lyrics_use_case.dart';
import '../../domain/use_cases/update_song_scroll_speed_use_case.dart';
import '../../domain/use_cases/update_song_use_case.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';
import '../../domain/use_cases/watch_local_songs_to_transfer_use_case.dart';

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

/// The use case that watches how many songs on the device may be moved into the account.
WatchLocalSongsToTransferUseCase get watchLocalSongsToTransferUseCase => di<WatchLocalSongsToTransferUseCase>();

/// The use case that moves the songs on the device into the account.
TransferLocalSongsUseCase get transferLocalSongsUseCase => di<TransferLocalSongsUseCase>();

/// The use case that keeps the songs on the device.
KeepLocalSongsUseCase get keepLocalSongsUseCase => di<KeepLocalSongsUseCase>();

/// The use case that adds a cover to a song.
AddCoverUseCase get addCoverUseCase => di<AddCoverUseCase>();

/// The use case that updates a cover.
UpdateCoverUseCase get updateCoverUseCase => di<UpdateCoverUseCase>();

/// The use case that deletes a cover.
DeleteCoverUseCase get deleteCoverUseCase => di<DeleteCoverUseCase>();
