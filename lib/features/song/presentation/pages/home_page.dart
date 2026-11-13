import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/di/auth_getters.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../../backup/presentation/widgets/backup_options_dialog_widget.dart';
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
import '../../../sync/presentation/di/sync_getters.dart';
import '../../../sync/presentation/pages/sync_page.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import '../di/song_getters.dart';
import '../widgets/artist_switcher_title_widget.dart';
import '../widgets/delete_song_dialog_widget.dart';
import '../widgets/home_dashboard_widget.dart';
import '../widgets/search_field_widget.dart';
import '../widgets/songs_tab_widget.dart';
import '../widgets/transfer_local_songs_dialog_widget.dart';
import 'add_song_page.dart';
import 'edit_song_page.dart';
import 'lyrics_page.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../auth/domain/entities/auth_failure.dart';
import '../../../auth/presentation/l10n/auth_texts.dart';
import '../../../backup/domain/entities/backup_failure.dart';
import '../../../backup/presentation/l10n/backup_texts.dart';
import '../../domain/entities/song_failure.dart';
import '../l10n/song_texts.dart';

/// Actions of the overflow menu on the home page.
enum _HomeMenuAction { importSongs, exportSongs, sync, signOut }

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

  /// Backup status while songs are exported.
  static const String _backupStatusExporting = 'exporting';

  /// Backup status while songs are imported.
  static const String _backupStatusImporting = 'importing';

  /// Height of the backup progress bar under the app bar.
  static const double _progressHeight = 4;

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
    final String status = watch(watchBackupStatusUseCase()).value;
    final bool isGuest = watch(watchCurrentSessionUseCase()).value is GuestAuthSession;
    final HomeTab tab = watch(songViewController.homeTabController).value;
    final SongSort sort = watch(songViewController.songSortController).value;
    final String selectedArtist = watch(songViewController.selectedArtistController).value;
    final String songQuery = watch(songViewController.songSearchController).value.text;
    final String coverQuery = watch(songViewController.coverSearchController).value.text;
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final UsageHistory history = watch(watchUsageHistoryUseCase()).value;
    registerHandler(
      target: watchLocalSongsToTransferUseCase(),
      handler: _onLocalSongsToTransferChanged,
      executeImmediately: true,
    );

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isBackupRunning = status == _backupStatusExporting || status == _backupStatusImporting;
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
            PopupMenuButton<_HomeMenuAction>(
              tooltip: t.song.more,
              enabled: !isBackupRunning,
              onSelected: (_HomeMenuAction action) => _onMenuSelected(context, action),
              itemBuilder: (BuildContext context) => _buildMenuItems(context, isGuest),
            ),
          ],
          bottom: isBackupRunning
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(_progressHeight),
                  child: LinearProgressIndicator(minHeight: _progressHeight),
                )
              : null,
        ),
        body: switch (tab) {
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
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (int index) => _selectTab(songViewController, HomeTab.values[index]),
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: t.song.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.queue_music_outlined),
              selectedIcon: const Icon(Icons.queue_music),
              label: t.song.tabSongs,
            ),
            NavigationDestination(
              icon: const Icon(Icons.mic_none_outlined),
              selectedIcon: const Icon(Icons.mic),
              label: t.song.tabCovers,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: t.song.statistics,
            ),
          ],
        ),
        floatingActionButton: songs.isEmpty || !isSongsTab
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddSongPage(context, newSongAuthor),
                icon: const Icon(Icons.add),
                label: Text(t.song.add),
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

  List<PopupMenuEntry<_HomeMenuAction>> _buildMenuItems(BuildContext context, bool isGuest) {
    final Translations t = context.t;
    return <PopupMenuEntry<_HomeMenuAction>>[
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.importSongs,
        child: ListTile(leading: const Icon(Icons.file_upload_outlined), title: Text(t.song.importSongs)),
      ),
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.exportSongs,
        child: ListTile(leading: const Icon(Icons.file_download_outlined), title: Text(t.song.exportSongs)),
      ),
      if (isSyncSupportedUseCase())
        PopupMenuItem<_HomeMenuAction>(
          value: _HomeMenuAction.sync,
          child: ListTile(leading: const Icon(Icons.sync), title: Text(t.song.sync)),
        ),
      const PopupMenuDivider(),
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.signOut,
        child: ListTile(
          leading: Icon(isGuest ? Icons.login : Icons.logout),
          title: Text(isGuest ? t.song.signInAccount : t.auth.signOut),
        ),
      ),
    ];
  }

  void _onBackInvoked(SongViewController songViewController, bool didPop) {
    if (!didPop) {
      songViewController.clearArtist();
    }
  }

  /// Asks about the songs on the device once there are some to move into the account.
  void _onLocalSongsToTransferChanged(BuildContext context, int songCount, void Function() cancel) {
    if (songCount == 0) return;
    _askToTransfer(context, songCount);
  }

  void _onSongDeletePressed(BuildContext context, Song song) {
    _confirmDelete(context, ScaffoldMessenger.of(context), song);
  }

  void _onMenuSelected(BuildContext context, _HomeMenuAction action) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _HomeMenuAction.importSongs:
        _handleImport(context, messenger);
      case _HomeMenuAction.exportSongs:
        _handleExport(context, messenger);
      case _HomeMenuAction.sync:
        _openSync(context);
      case _HomeMenuAction.signOut:
        _handleSignOut(messenger, context.t);
    }
  }

  Future<void> _handleExport(BuildContext context, ScaffoldMessengerState messenger) async {
    final Translations t = context.t;
    final bool? includeRecordings = await _askIncludeRecordings(context, t.song.exportSongs, t.song.exportQuestion);
    if (includeRecordings == null) return;
    final Result<void, BackupFailure> result = await exportSongsUseCase(
      includeRecordings: includeRecordings,
      pickerTitle: t.backup.exportDialogTitle,
    );
    _showMessage(
      messenger,
      result.when(success: (void _) => t.song.exportDone, failure: (BackupFailure failure) => failure.text(t)),
    );
  }

  Future<void> _handleImport(BuildContext context, ScaffoldMessengerState messenger) async {
    final Translations t = context.t;
    final bool? includeRecordings = await _askIncludeRecordings(context, t.song.importSongs, t.song.importQuestion);
    if (includeRecordings == null) return;
    final Result<void, BackupFailure> result = await importSongsUseCase(includeRecordings: includeRecordings);
    _showMessage(
      messenger,
      result.when(success: (void _) => t.song.importDone, failure: (BackupFailure failure) => failure.text(t)),
    );
  }

  /// Asks whether the recordings go too; `null` when cancelled. The web keeps no recordings.
  Future<bool?> _askIncludeRecordings(BuildContext context, String title, String message) async {
    if (kIsWeb) return false;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => BackupOptionsDialogWidget(title: title, message: message, confirmLabel: title),
    );
  }

  Future<void> _handleSignOut(ScaffoldMessengerState messenger, Translations t) async {
    final Result<void, AuthFailure> result = await signOutUseCase();
    result.when(success: _ignore, failure: (AuthFailure failure) => _showMessage(messenger, failure.text(t)));
  }

  /// Shows the question after the current frame (the handler may run during a build).
  Future<void> _askToTransfer(BuildContext context, int songCount) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Translations t = context.t;

    final bool? transfer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => TransferLocalSongsDialogWidget(songCount: songCount),
    );

    final Result<void, SongFailure> result = transfer == true
        ? await transferLocalSongsUseCase()
        : await keepLocalSongsUseCase();
    if (transfer == true && result.isSuccess) _showMessage(messenger, t.song.transferred);
    result.when(success: _ignore, failure: (SongFailure failure) => _showMessage(messenger, failure.text(t)));
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

  static void _ignore(void _) {}

  void _openSync(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => const SyncPage()));
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
