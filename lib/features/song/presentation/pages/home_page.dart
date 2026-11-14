import '../../../../core/presentation/widgets/accent_action_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../../history/domain/entities/usage_history.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../../practice/domain/entities/practice_session.dart';
import '../../../practice/domain/entities/practice_stats.dart';
import '../../../practice/presentation/di/practice_getters.dart';
import '../../../practice/presentation/widgets/practice_stats_widget.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/presentation/widgets/covers_list_widget.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import '../di/song_getters.dart';
import '../widgets/artist_switcher_title_widget.dart';
import '../widgets/delete_song_dialog_widget.dart';
import '../widgets/home_dashboard_widget.dart';
import '../widgets/search_field_widget.dart';
import '../widgets/songs_tab_widget.dart';
import 'add_song_page.dart';
import 'edit_song_page.dart';
import 'lyrics_page.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/song_failure.dart';
import '../l10n/song_texts.dart';

/// Main page with the bottom navigation: home (mini statistics, recent songs and covers),
/// songs (search and orders), covers (search) and statistics; plus backup and account actions.
///
/// Watches the songs, the covers, the practice, the history, the backup status, the session and
/// its [SongViewController]. After a sign-in it asks whether to move the songs left on the device
/// into the account.
final class HomePage extends WatchingWidget {
  /// Title of the home tab.
  static const String _homeTitle = 'hitwave.cover';

  /// Separator between a song and its artist.
  static const String _titleSeparator = ' — ';

  /// How many songs and covers the home tab shows.
  static const int _recentCount = 5;

  /// Separator between the title and the song count.
  static const String _countSeparator = '  ';

  /// Creates a new [HomePage].
  const HomePage({super.key});

  static SongViewController _createSongViewController() => SongViewController();

  static void _disposeSongViewController(SongViewController songViewController) => songViewController.dispose();

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final SongViewController songViewController = createOnce(
      _createSongViewController,
      dispose: _disposeSongViewController,
    );
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final HomeTab tab = watch(songViewController.homeTabController).value;
    final SongSort sort = watch(songViewController.songSortController).value;
    final String selectedArtist = watch(songViewController.selectedArtistController).value;
    final String songQuery = watch(songViewController.songSearchController).value.text;
    final String coverQuery = watch(songViewController.coverSearchController).value.text;
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final UsageHistory history = watch(watchUsageHistoryUseCase()).value;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Map<String, int> coverCounts = <String, int>{};
    for (final Recording recording in recordings) {
      coverCounts[recording.songId] = (coverCounts[recording.songId] ?? 0) + 1;
    }
    final Map<String, Song> songsById = <String, Song>{for (final Song song in songs) song.id: song};
    final List<Song> foundSongs = _orderSongs(_findSongs(songs, songQuery), sort, history, coverCounts);
    final bool isSongsTab = tab == HomeTab.songs;
    final bool hasSelectedArtist =
        isSongsTab &&
        sort == SongSort.artists &&
        songQuery.trim().isEmpty &&
        songs.any((Song song) => song.author == selectedArtist);
    final String? newSongAuthor = hasSelectedArtist ? selectedArtist : null;
    final DateTime now = DateTime.now();
    final PracticeStats stats = calculatePracticeStatsUseCase(sessions: sessions, recordings: recordings, now: now);

    final Widget titleText = Text.rich(
      TextSpan(
        text: hasSelectedArtist ? selectedArtist : _titleOf(t, tab),
        children: <InlineSpan>[
          if (isSongsTab)
            TextSpan(
              text: '$_countSeparator${hasSelectedArtist ? _countOf(songs, selectedArtist) : foundSongs.length}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final bool useRail = MediaQuery.sizeOf(context).width >= AppTheme.railBreakpoint;
    final List<_Tab> tabs = <_Tab>[
      _Tab(Icons.home_outlined, Icons.home, t.song.tabHome),
      _Tab(Icons.queue_music_outlined, Icons.queue_music, t.song.tabSongs),
      _Tab(Icons.mic_none_outlined, Icons.mic, t.song.tabCovers),
      _Tab(Icons.insights_outlined, Icons.insights, t.song.statistics),
    ];
    final Widget body = switch (tab) {
      HomeTab.home => HomeDashboardWidget(
        stats: stats,
        today: PracticeStats.dayOf(now),
        recentSongs: _recentSongs(songsById, history),
        recentCovers: _recentCovers(recordings, history),
        coverCounts: coverCounts,
        coverTitleOf: (Recording recording) => _songTitle(t, songsById[recording.songId]),
        coverSongOf: (Recording recording) => _sharedSong(songsById[recording.songId]),
        onStatsPressed: () => _selectTab(songViewController, HomeTab.stats),
        onAllSongsPressed: () => _selectTab(songViewController, HomeTab.songs),
        onAllCoversPressed: () => _selectTab(songViewController, HomeTab.covers),
        onSongTap: (Song song) => _navigateToLyrics(context, song),
        onSongEdit: (Song song) => _showEditSongPage(context, song),
        onSongDelete: (Song song) => _onSongDeletePressed(context, song),
      ),
      HomeTab.songs => SongsTabWidget(
        isLibraryEmpty: songs.isEmpty,
        songs: foundSongs,
        coverCounts: coverCounts,
        searchController: songViewController.songSearchController,
        sort: sort,
        selectedArtist: selectedArtist,
        onSortSelected: songViewController.selectSort,
        onArtistSelected: songViewController.selectArtist,
        onSongTap: (Song song) => _navigateToLyrics(context, song),
        onSongEdit: (Song song) => _showEditSongPage(context, song),
        onSongDelete: (Song song) => _onSongDeletePressed(context, song),
        onAddPressed: () => _showAddSongPage(context, newSongAuthor),
      ),
      HomeTab.covers => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMedium,
                  AppTheme.spacingSmall,
                  AppTheme.spacingMedium,
                  0,
                ),
                child: SearchFieldWidget(
                  searchController: songViewController.coverSearchController,
                  hint: t.song.coverSearch,
                ),
              ),
            ),
          ),
          Expanded(child: CoversListWidget(query: coverQuery)),
        ],
      ),
      HomeTab.stats => const PracticeStatsWidget(),
    };

    return PopScope(
      canPop: !hasSelectedArtist,
      onPopInvokedWithResult: (bool didPop, Object? result) => _onBackInvoked(songViewController, didPop),
      child: Scaffold(
        appBar: AppBar(
          leading: hasSelectedArtist
              ? IconButton(
                  tooltip: t.song.allArtists,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: songViewController.clearArtist,
                )
              : null,
          title: hasSelectedArtist
              ? ArtistSwitcherTitleWidget(
                  title: titleText,
                  songs: songs,
                  selectedArtist: selectedArtist,
                  onArtistSelected: songViewController.selectArtist,
                )
              : titleText,
          actions: <Widget>[
            IconButton(
              tooltip: t.settings.open,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _openSettings(context),
            ),
          ],
        ),
        body: useRail
            ? Row(
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: tab.index,
                    onDestinationSelected: (int index) => _selectTab(songViewController, HomeTab.values[index]),
                    destinations: <NavigationRailDestination>[
                      for (final _Tab destination in tabs)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                selectedIndex: tab.index,
                onDestinationSelected: (int index) => _selectTab(songViewController, HomeTab.values[index]),
                destinations: <NavigationDestination>[
                  for (final _Tab destination in tabs)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
        floatingActionButton: songs.isEmpty || !isSongsTab
            ? null
            : AccentActionButtonWidget(
                onPressed: () => _showAddSongPage(context, newSongAuthor),
                icon: Icons.add,
                label: t.song.add,
              ),
      ),
    );
  }

  static String _titleOf(Translations t, HomeTab tab) => switch (tab) {
    HomeTab.home => _homeTitle,
    HomeTab.songs => t.song.mySongs,
    HomeTab.covers => t.song.myCovers,
    HomeTab.stats => t.song.statistics,
  };

  static int _countOf(List<Song> songs, String artist) => songs.where((Song song) => song.author == artist).length;

  static SharedSong? _sharedSong(Song? song) => song == null ? null : SharedSong(author: song.author, name: song.name);

  static String _songTitle(Translations t, Song? song) =>
      song == null ? t.common.songDeleted : '${song.name}$_titleSeparator${song.author}';

  /// The songs whose name, artist or album contain [query].
  static List<Song> _findSongs(List<Song> songs, String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return songs;
    return songs
        .where(
          (Song song) =>
              song.name.toLowerCase().contains(needle) ||
              song.author.toLowerCase().contains(needle) ||
              (song.album ?? '').toLowerCase().contains(needle),
        )
        .toList();
  }

  /// [songs] in the chosen order; ties and the artist order go by name.
  static List<Song> _orderSongs(List<Song> songs, SongSort sort, UsageHistory history, Map<String, int> coverCounts) {
    int byName(Song a, Song b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
    final DateTime never = DateTime.fromMillisecondsSinceEpoch(0);
    final List<Song> ordered = songs.toList();
    switch (sort) {
      case SongSort.name:
        ordered.sort(byName);
      case SongSort.artists:
        ordered.sort((Song a, Song b) {
          final int byArtist = a.author.toLowerCase().compareTo(b.author.toLowerCase());
          return byArtist != 0 ? byArtist : byName(a, b);
        });
      case SongSort.recent:
        ordered.sort((Song a, Song b) {
          final int byTime = (history.songsOpenedAt[b.id] ?? never).compareTo(history.songsOpenedAt[a.id] ?? never);
          return byTime != 0 ? byTime : byName(a, b);
        });
      case SongSort.covers:
        ordered.sort((Song a, Song b) {
          final int byCovers = (coverCounts[b.id] ?? 0).compareTo(coverCounts[a.id] ?? 0);
          return byCovers != 0 ? byCovers : byName(a, b);
        });
    }
    return ordered;
  }

  /// The songs opened last that still exist, newest first.
  static List<Song> _recentSongs(Map<String, Song> songsById, UsageHistory history) {
    final List<MapEntry<String, DateTime>> opened =
        history.songsOpenedAt.entries
            .where((MapEntry<String, DateTime> entry) => songsById.containsKey(entry.key))
            .toList()
          ..sort((MapEntry<String, DateTime> a, MapEntry<String, DateTime> b) => b.value.compareTo(a.value));
    return <Song>[for (final MapEntry<String, DateTime> entry in opened.take(_recentCount)) songsById[entry.key]!];
  }

  /// The covers played last that still exist, newest first.
  static List<Recording> _recentCovers(List<Recording> recordings, UsageHistory history) {
    final List<Recording> played =
        recordings.where((Recording recording) => history.coversPlayedAt.containsKey(recording.id)).toList()
          ..sort((Recording a, Recording b) => history.coversPlayedAt[b.id]!.compareTo(history.coversPlayedAt[a.id]!));
    return played.take(_recentCount).toList();
  }

  void _onBackInvoked(SongViewController songViewController, bool didPop) {
    if (!didPop) {
      songViewController.clearArtist();
    }
  }

  void _onSongDeletePressed(BuildContext context, Song song) {
    _confirmDelete(context, ScaffoldMessenger.of(context), song);
  }

  Future<void> _confirmDelete(BuildContext context, ScaffoldMessengerState messenger, Song song) async {
    final Translations t = context.t;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteSongDialogWidget(songName: song.name),
    );
    if (confirmed != true) {
      return;
    }

    final Result<void, SongFailure> result = await deleteSongUseCase(songId: song.id);
    _showMessage(
      messenger,
      result.when(success: (void _) => t.common.songDeleted, failure: (SongFailure failure) => failure.text(t)),
    );
  }

  static void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => const SettingsPage()));
  }

  void _navigateToLyrics(BuildContext context, Song song) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => LyricsPage(song: song)));
  }

  /// Shows [tab]; a cover playing on the tab left behind stops.
  void _selectTab(SongViewController songViewController, HomeTab tab) {
    if (tab == songViewController.homeTabController.value) return;
    stopPlaybackUseCase();
    songViewController.selectTab(tab);
  }

  /// Opens the form of a new song; on an artist's page its author is filled in.
  void _showAddSongPage(BuildContext context, String? author) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => AddSongPage(author: author)));
  }

  void _showEditSongPage(BuildContext context, Song song) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => EditSongPage(song: song)));
  }
}

/// A destination of the home tabs, shown in the bottom bar or in the rail.
final class _Tab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Tab(this.icon, this.selectedIcon, this.label);
}
