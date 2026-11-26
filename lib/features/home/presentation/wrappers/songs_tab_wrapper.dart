import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../history/domain/entities/usage_history.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../../recordings/domain/entities/cover_counts.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/entities/song_sort.dart';
import '../../../song/presentation/l10n/song_widget_texts.dart';
import '../../../song/presentation/widgets/songs_tab_widget.dart';
import '../controllers/song_view_controller.dart';
import '../di/home_getters.dart';

/// The songs tab: gives [SongsTabWidget] the found songs in the chosen order. Watches the search text, the covers and
/// the history, so typing rebuilds only this tab.
final class SongsTabWrapper extends WatchingWidget {
  /// All the songs.
  final List<Song> songs;

  /// The search, the order and the artist, owned by the page.
  final SongViewController songViewController;

  /// The chosen order.
  final SongSort sort;

  /// The artist whose songs are shown, or an empty string for all.
  final String selectedArtist;

  /// Called when a song is tapped.
  final ValueChanged<Song> onSongTap;

  /// Called when "edit" is chosen for a song.
  final ValueChanged<Song> onSongEdit;

  /// Called when "delete" is chosen for a song.
  final ValueChanged<Song> onSongDelete;

  /// Called by the add button of the empty library.
  final VoidCallback onAddPressed;

  /// Creates the wrapper.
  const SongsTabWrapper({
    super.key,
    required this.songs,
    required this.songViewController,
    required this.sort,
    required this.selectedArtist,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String query = watchPropertyValue(_textOf, target: songViewController.songSearchController);
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final UsageHistory history = watch(watchUsageHistoryUseCase()).value;
    final CoverCounts coverCounts = CoverCounts.fromRecordings(recordings);
    final List<Song> found = findSongsUseCase(songs: songs, query: query);

    return SongsTabWidget(
      isLibraryEmpty: songs.isEmpty,
      songs: buildSongOrderUseCase(songs: found, sort: sort, history: history, coverCounts: coverCounts),
      coverCountOf: coverCounts.of,
      texts: context.t.songList,
      searchController: songViewController.songSearchController,
      sort: sort,
      selectedArtist: selectedArtist,
      onSortSelected: songViewController.selectSort,
      onArtistSelected: songViewController.selectArtist,
      onSongTap: onSongTap,
      onSongEdit: onSongEdit,
      onSongDelete: onSongDelete,
      onAddPressed: onAddPressed,
    );
  }

  static String _textOf(TextEditingController searchController) => searchController.text;
}
