import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/build_song_order_use_case.dart';
import '../../domain/use_cases/find_recent_activity_use_case.dart';
import '../../domain/use_cases/find_songs_use_case.dart';

/// Registers the home feature: it owns no data — the home page composes the other features — only the use cases that
/// search, order and pick the recent songs and covers.
void registerAndInitHome() {
  // 3. use cases
  di.registerLazySingleton<FindSongsUseCase>(FindSongsUseCase.new);
  di.registerLazySingleton<BuildSongOrderUseCase>(BuildSongOrderUseCase.new);
  di.registerLazySingleton<FindRecentActivityUseCase>(FindRecentActivityUseCase.new);
}
