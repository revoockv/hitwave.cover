import '../../../../core/presentation/widgets/accent_action_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../../practice/presentation/pages/practice_stats_page.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/entities/song_sort.dart';
import '../controllers/song_view_controller.dart';
import '../controllers/home_controller.dart';
import '../wrappers/covers_tab_wrapper.dart';
import '../wrappers/found_count_wrapper.dart';
import '../wrappers/home_dashboard_wrapper.dart';
import '../wrappers/songs_tab_wrapper.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../../song/presentation/widgets/artist_switcher_title_widget.dart';
import '../../../song/presentation/widgets/delete_song_dialog_widget.dart';
import '../../../song/presentation/pages/add_song_page.dart';
import '../../../song/presentation/pages/edit_song_page.dart';
import '../../../lyrics/presentation/pages/lyrics_page.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../../song/presentation/l10n/song_texts.dart';
import '../../../tuner/presentation/pages/tuner_panel_page.dart';
import '../../../../core/presentation/widgets/fade_in_switcher_widget.dart';
import '../../../song/presentation/l10n/song_widget_texts.dart';

/// Main page with the bottom navigation: home (mini statistics, recent songs and covers),
/// songs (search and orders), covers (search) and statistics; plus backup and account actions.
///
/// Watches only what it shows itself — the songs (title, count, add button), the tab, the order, the artist and
/// whether the search is empty; every tab watches its own data. After a sign-in it asks whether to move the songs
/// left on the device into the account.
final class HomePage extends WatchingWidget {
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
              child: FoundCountWrapper(
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
      _Tab(Icons.insights_outlined, Icons.insights, t.song.tabStatistics),
      _Tab(Icons.graphic_eq_outlined, Icons.graphic_eq, t.tuner.title),
    ];
    // Every tab watches the data it shows itself, so a change of it does not rebuild the page and the other tabs.
    final Widget page = switch (tab) {
      HomeTab.home => HomeDashboardWrapper(
        songs: songs,
        onStatsPressed: () => _selectTab(homeController, HomeTab.stats),
        onAllSongsPressed: () => _selectTab(homeController, HomeTab.songs),
        onAllCoversPressed: () => _selectTab(homeController, HomeTab.covers),
        onSongTap: (Song song) => _navigateToLyrics(context, song),
        onSongEdit: (Song song) => _showEditSongPage(context, song),
        onSongDelete: (Song song) => _onSongDeletePressed(context, song),
      ),
      HomeTab.songs => SongsTabWrapper(
        songs: songs,
        songViewController: songViewController,
        sort: sort,
        selectedArtist: selectedArtist,
        onSongTap: (Song song) => _navigateToLyrics(context, song),
        onSongEdit: (Song song) => _showEditSongPage(context, song),
        onSongDelete: (Song song) => _onSongDeletePressed(context, song),
        onAddPressed: () => _showAddSongPage(context, newSongAuthor),
      ),
      HomeTab.covers => CoversTabWrapper(
        homeController: homeController,
        onSongPressed: (Song song) => _navigateToLyrics(context, song),
      ),
      HomeTab.stats => PracticeStatsPage(onSongPressed: (Song song) => _navigateToLyrics(context, song)),
      HomeTab.tuner => const TunerPanelPage(),
    };
    // Another tab fades in; the old one goes at once.
    final Widget body = FadeInSwitcherWidget(switchKey: tab, child: page);

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
                  tooltip: t.song.otherArtist,
                  pickerTexts: t.artistPicker,
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

  static bool _isEmptyOf(TextEditingController searchController) => searchController.text.trim().isEmpty;

  static int _countOf(List<Song> songs, String artist) => songs.where((Song song) => song.author == artist).length;

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
      builder: (BuildContext context) => DeleteSongDialogWidget(texts: context.t.deleteSongDialog(song.name)),
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
