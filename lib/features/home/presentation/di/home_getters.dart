import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/build_song_order_use_case.dart';
import '../../domain/use_cases/find_recent_activity_use_case.dart';
import '../../domain/use_cases/find_songs_use_case.dart';

/// Finds the songs that match a search.
FindSongsUseCase get findSongsUseCase => di<FindSongsUseCase>();

/// Puts songs in the chosen order.
BuildSongOrderUseCase get buildSongOrderUseCase => di<BuildSongOrderUseCase>();

/// Finds the songs opened last and the covers played last.
FindRecentActivityUseCase get findRecentActivityUseCase => di<FindRecentActivityUseCase>();
