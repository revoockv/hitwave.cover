import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/clear_history_use_case.dart';
import '../../domain/use_cases/mark_cover_played_use_case.dart';
import '../../domain/use_cases/mark_song_opened_use_case.dart';
import '../../domain/use_cases/watch_usage_history_use_case.dart';

/// The use case that watches when songs were opened and covers played; call it to get the
/// [ValueListenable].
WatchUsageHistoryUseCase get watchUsageHistoryUseCase => di<WatchUsageHistoryUseCase>();

/// The use case that remembers a song was opened.
MarkSongOpenedUseCase get markSongOpenedUseCase => di<MarkSongOpenedUseCase>();

/// The use case that remembers a cover was played.
MarkCoverPlayedUseCase get markCoverPlayedUseCase => di<MarkCoverPlayedUseCase>();

/// The use case that forgets which songs were opened and which covers played.
ClearHistoryUseCase get clearHistoryUseCase => di<ClearHistoryUseCase>();
