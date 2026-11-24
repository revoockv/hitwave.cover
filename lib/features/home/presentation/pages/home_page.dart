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
import '../../../practice/domain/entities/practice_entry_filter.dart';
import '../../../practice/presentation/widgets/practice_stats_widget.dart';
import '../../../practice/presentation/widgets/practice_timeline_widget.dart';
import '../../../recordings/domain/entities/cover_counts.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/entities/song_sort.dart';
import '../controllers/song_view_controller.dart';
import '../controllers/home_controller.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../../song/presentation/widgets/artist_switcher_title_widget.dart';
import '../../../song/presentation/widgets/delete_song_dialog_widget.dart';
import '../widgets/home_dashboard_widget.dart';
import '../../../song/presentation/widgets/search_field_widget.dart';
import '../../../song/presentation/widgets/songs_tab_widget.dart';
import '../../../song/presentation/pages/add_song_page.dart';
import '../../../song/presentation/pages/edit_song_page.dart';
import '../../../lyrics/presentation/pages/lyrics_page.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../../song/presentation/l10n/song_texts.dart';
import '../../../tuner/presentation/widgets/tuner_widget.dart';

/// Main page with the bottom navigation: home (mini statistics, recent songs and covers),
/// songs (search and orders), covers (search) and statistics; plus backup and account actions.
///
/// Watches only what it shows itself — the songs (title, count, add button), the tab, the order, the artist and
/// whether the search is empty; every tab watches its own data. After a sign-in it asks whether to move the songs
/// left on the device into the account.
final class HomePage extends WatchingWidget {
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

  static HomeController _createHomeController() => HomeController();

  static void _disposeHomeController(HomeController homeController) => homeController.dispose();

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final SongViewController songViewController = createOnce(
      _createSongViewController,
      dispose: _disposeSongViewController,
    );
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final HomeController homeController = createOnce(_createHomeController, dispose: _disposeHomeController);
    final HomeTab tab = watch(homeController.homeTabController).value;
    final SongSort sort = watch(songViewController.songSortController).value;
    final String selectedArtist = watch(songViewController.selectedArtistController).value;
    // Only whether the search is empty: typing rebuilds the found count and the songs tab, not the page.
    final bool isSongSearchEmpty = watchPropertyValue(_isEmptyOf, target: songViewController.songSearchController);

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isSongsTab = tab == HomeTab.songs;
    final bool hasSelectedArtist =
        isSongsTab &&
        sort == SongSort.artists &&
        isSongSearchEmpty &&
        songs.any((Song song) => song.author == selectedArtist);
    final String? newSongAuthor = hasSelectedArtist ? selectedArtist : null;
    final TextStyle countStyle = TextStyle(color: colorScheme.onSurfaceVariant);

    final Widget titleText = Text.rich(
      TextSpan(
        text: hasSelectedArtist ? selectedArtist : _titleOf(t, tab),
        children: <InlineSpan>[
          if (hasSelectedArtist)
            TextSpan(text: '$_countSeparator${_countOf(songs, selectedArtist)}', style: countStyle)
          else if (isSongsTab)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _FoundCountWidget(
                songs: songs,
                searchController: songViewController.songSearchController,
                separator: _countSeparator,
                style: countStyle,
              ),
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
      _Tab(Icons.graphic_eq_outlined, Icons.graphic_eq, t.tuner.title),
    ];
    // Every tab watches the data it shows itself, so a change of it does not rebuild the page and the other tabs.
    final Widget body = switch (tab) {
      HomeTab.home => _HomeTabWidget(
        songs: songs,
        onStatsPressed: () => _selectTab(homeController, HomeTab.stats),
        onAllSongsPressed: () => _selectTab(homeController, HomeTab.songs),
        onAllCoversPressed: () => _selectTab(homeController, HomeTab.covers),
        onSongTap: (Song song) => _navigateToLyrics(context, song),
        onSongEdit: (Song song) => _showEditSongPage(context, song),
        onSongDelete: (Song song) => _onSongDeletePressed(context, song),
      ),
      HomeTab.songs => _SongsTabWidget(
        songs: songs,
        songViewController: songViewController,
        sort: sort,
        selectedArtist: selectedArtist,
        onSongTap: (Song song) => _navigateToLyrics(context, song),
        onSongEdit: (Song song) => _showEditSongPage(context, song),
        onSongDelete: (Song song) => _onSongDeletePressed(context, song),
        onAddPressed: () => _showAddSongPage(context, newSongAuthor),
      ),
      HomeTab.covers => _CoversTabWidget(
        homeController: homeController,
        onSongPressed: (Song song) => _navigateToLyrics(context, song),
      ),
      HomeTab.stats => PracticeStatsWidget(onSongPressed: (Song song) => _navigateToLyrics(context, song)),
      HomeTab.tuner => const TunerWidget(),
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
                // Full height: a scroll view shorter than the window would sit in the middle.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: tab.index,
                    onDestinationSelected: (int index) => _selectTab(homeController, HomeTab.values[index]),
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
                onDestinationSelected: (int index) => _selectTab(homeController, HomeTab.values[index]),
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
    HomeTab.home => t.appTitle,
    HomeTab.songs => t.song.mySongs,
    HomeTab.covers => t.song.myCovers,
    HomeTab.stats => t.song.statistics,
    HomeTab.tuner => t.tuner.title,
  };

  static String _textOf(TextEditingController searchController) => searchController.text;

  static bool _isEmptyOf(TextEditingController searchController) => searchController.text.trim().isEmpty;

  static int _countOf(List<Song> songs, String artist) => songs.where((Song song) => song.author == artist).length;

  static SharedSong? _sharedSong(Song? song) => song == null ? null : SharedSong(author: song.author, name: song.name);

  static String _songTitle(Translations t, Song? song) =>
      song == null ? t.common.songDeleted : '${song.author}$_titleSeparator${song.name}';

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
  static List<Song> _orderSongs(List<Song> songs, SongSort sort, UsageHistory history, CoverCounts coverCounts) {
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
          final int byTime = (history.songOpenedAt(b.id) ?? never).compareTo(history.songOpenedAt(a.id) ?? never);
          return byTime != 0 ? byTime : byName(a, b);
        });
      case SongSort.covers:
        ordered.sort((Song a, Song b) {
          final int byCovers = coverCounts.of(b.id).compareTo(coverCounts.of(a.id));
          return byCovers != 0 ? byCovers : byName(a, b);
        });
    }
    return ordered;
  }

  /// The songs opened last that still exist, newest first.
  static List<Song> _recentSongs(Map<String, Song> songsById, UsageHistory history) {
    final List<UsageTime> opened =
        history.songsOpened.where((UsageTime time) => songsById.containsKey(time.id)).toList()
          ..sort((UsageTime a, UsageTime b) => b.at.compareTo(a.at));
    return <Song>[for (final UsageTime time in opened.take(_recentCount)) songsById[time.id]!];
  }

  /// The covers played last that still exist, newest first.
  static List<Recording> _recentCovers(List<Recording> recordings, UsageHistory history) {
    final List<Recording> played =
        recordings.where((Recording recording) => history.coverPlayedAt(recording.id) != null).toList()
          ..sort((Recording a, Recording b) => history.coverPlayedAt(b.id)!.compareTo(history.coverPlayedAt(a.id)!));
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
  void _selectTab(HomeController homeController, HomeTab tab) {
    if (tab == homeController.homeTabController.value) return;
    stopPlaybackUseCase();
    homeController.selectTab(tab);
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

/// The number of songs the search finds, after the title of the songs tab; the only part that rebuilds while typing.
final class _FoundCountWidget extends WatchingWidget {
  final List<Song> songs;
  final TextEditingController searchController;
  final String separator;
  final TextStyle style;

  const _FoundCountWidget({
    required this.songs,
    required this.searchController,
    required this.separator,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final String query = watchPropertyValue(HomePage._textOf, target: searchController);
    return Text('$separator${HomePage._findSongs(songs, query).length}', style: style);
  }
}

/// The home tab: mini statistics, recent songs and covers. Watches the practice, the covers and the history itself.
final class _HomeTabWidget extends WatchingWidget {
  final List<Song> songs;
  final VoidCallback onStatsPressed;
  final VoidCallback onAllSongsPressed;
  final VoidCallback onAllCoversPressed;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onSongEdit;
  final ValueChanged<Song> onSongDelete;

  const _HomeTabWidget({
    required this.songs,
    required this.onStatsPressed,
    required this.onAllSongsPressed,
    required this.onAllCoversPressed,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final UsageHistory history = watch(watchUsageHistoryUseCase()).value;

    final Map<String, Song> songsById = <String, Song>{for (final Song song in songs) song.id: song};
    final DateTime now = DateTime.now();

    return HomeDashboardWidget(
      stats: calculatePracticeStatsUseCase(sessions: sessions, recordings: recordings, now: now),
      today: PracticeStats.dayOf(now),
      recentSongs: HomePage._recentSongs(songsById, history),
      recentCovers: HomePage._recentCovers(recordings, history),
      coverCounts: CoverCounts.fromRecordings(recordings),
      coverTitleOf: (Recording recording) => HomePage._songTitle(t, songsById[recording.songId]),
      coverSongPressedOf: (Recording recording) => _openerOf(songsById[recording.songId]),
      coverSongOf: (Recording recording) => HomePage._sharedSong(songsById[recording.songId]),
      onStatsPressed: onStatsPressed,
      onAllSongsPressed: onAllSongsPressed,
      onAllCoversPressed: onAllCoversPressed,
      onSongTap: onSongTap,
      onSongEdit: onSongEdit,
      onSongDelete: onSongDelete,
    );
  }

  /// Opens the lyrics of [song]; `null` when the song is gone.
  VoidCallback? _openerOf(Song? song) => song == null ? null : () => onSongTap(song);
}

/// The songs tab: search, order and artists. Watches the search text, the covers and the history itself.
final class _SongsTabWidget extends WatchingWidget {
  final List<Song> songs;
  final SongViewController songViewController;
  final SongSort sort;
  final String selectedArtist;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onSongEdit;
  final ValueChanged<Song> onSongDelete;
  final VoidCallback onAddPressed;

  const _SongsTabWidget({
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
    final String query = watchPropertyValue(HomePage._textOf, target: songViewController.songSearchController);
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final UsageHistory history = watch(watchUsageHistoryUseCase()).value;

    final CoverCounts coverCounts = CoverCounts.fromRecordings(recordings);

    return SongsTabWidget(
      isLibraryEmpty: songs.isEmpty,
      songs: HomePage._orderSongs(HomePage._findSongs(songs, query), sort, history, coverCounts),
      coverCountOf: coverCounts.of,
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
}

/// The covers tab: the search field and the practice timeline. Watches the search text and the filter itself.
final class _CoversTabWidget extends WatchingWidget {
  final HomeController homeController;
  final ValueChanged<Song> onSongPressed;

  const _CoversTabWidget({required this.homeController, required this.onSongPressed});

  @override
  Widget build(BuildContext context) {
    final String query = watchPropertyValue(HomePage._textOf, target: homeController.coverSearchController);
    final PracticeEntryFilter filter = watch(homeController.coverFilterController).value;

    return Column(
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
                searchController: homeController.coverSearchController,
                hint: context.t.song.coverSearch,
              ),
            ),
          ),
        ),
        Expanded(
          child: PracticeTimelineWidget(
            query: query,
            filter: filter,
            onFilterChanged: _onFilterChanged,
            onSongPressed: onSongPressed,
          ),
        ),
      ],
    );
  }

  void _onFilterChanged(PracticeEntryFilter filter) {
    homeController.coverFilterController.value = filter;
  }
}
