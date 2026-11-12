import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/di/auth_getters.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../../backup/presentation/widgets/backup_options_dialog_widget.dart';
import '../../../practice/domain/entities/practice_session.dart';
import '../../../practice/domain/entities/practice_stats.dart';
import '../../../practice/presentation/di/practice_getters.dart';
import '../../../practice/presentation/pages/practice_page.dart';
import '../../../practice/presentation/widgets/practice_overview_widget.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/presentation/widgets/covers_list_widget.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import '../di/song_getters.dart';
import '../widgets/artist_switcher_title_widget.dart';
import '../widgets/delete_song_dialog_widget.dart';
import '../widgets/songs_widget.dart';
import '../widgets/transfer_local_songs_dialog_widget.dart';
import 'add_song_page.dart';
import 'edit_song_page.dart';
import 'lyrics_page.dart';

/// Actions of the overflow menu on the home page.
enum _HomeMenuAction { importSongs, exportSongs, signOut }

/// Main home page with the song list, backup and account actions.
///
/// Watches the song list, the backup status, the session and the view mode of
/// its [SongViewController]. After a sign-in it asks whether to move the songs
/// left on the device into the account.
final class HomePage extends WatchingWidget {
  /// Page title text.
  static const String _homePageTitle = 'Мої пісні';

  /// Separator between the title and the song count.
  static const String _countSeparator = '  ';

  /// Tooltip of the switch to the plain list.
  static const String _listModeTooltip = 'Показати списком';

  /// Tooltip of the switch to the artist view.
  static const String _artistModeTooltip = 'Групувати за виконавцями';

  /// Tooltip of the back button to the artist list.
  static const String _allArtistsTooltip = 'Усі виконавці';

  /// Label of the songs tab.
  static const String _songsTab = 'Пісні';

  /// Label of the covers tab.
  static const String _coversTab = 'Кавери';

  /// Tooltip of the overflow menu.
  static const String _menuTooltip = 'Ще';

  /// Label of the import menu item.
  static const String _importLabel = 'Імпортувати';

  /// Label of the export menu item.
  static const String _exportLabel = 'Експортувати';

  /// Text of the export question.
  static const String _exportQuestion = 'Пісні буде збережено у файл у вибраній папці.';

  /// Text of the import question.
  static const String _importQuestion = 'Пісні з файлу буде додано до ваших. Записи беруться лише з ZIP-архіву.';

  /// Label of the sign-out menu item.
  static const String _signOutLabel = 'Вийти';

  /// Label of the menu item that leaves the guest mode for the sign-in screen.
  static const String _signInLabel = 'Увійти в акаунт';

  /// Message shown after the songs on the device moved into the account.
  static const String _transferredMessage = 'Пісні перенесено в акаунт';

  /// Label of the add button.
  static const String _addLabel = 'Додати';

  /// Backup status while songs are exported.
  static const String _backupStatusExporting = 'exporting';

  /// Backup status while songs are imported.
  static const String _backupStatusImporting = 'importing';

  /// Success message shown after export completes.
  static const String _exportCompletedMessage = 'Експорт завершено';

  /// Success message shown after import completes.
  static const String _importCompletedMessage = 'Імпорт завершено';

  /// Prefix of the message shown when the export fails.
  static const String _exportErrorPrefix = 'Помилка експорту: ';

  /// Prefix of the message shown when the import fails.
  static const String _importErrorPrefix = 'Помилка імпорту: ';

  /// Message shown after a song is deleted.
  static const String _deletedMessage = 'Пісню видалено';

  /// Height of the backup progress bar under the app bar.
  static const double _progressHeight = 4;

  /// Creates a new [HomePage].
  const HomePage({super.key});

  static SongViewController _createSongViewController() => SongViewController();

  static void _disposeSongViewController(SongViewController songViewController) => songViewController.dispose();

  @override
  Widget build(BuildContext context) {
    final SongViewController songViewController = createOnce(
      _createSongViewController,
      dispose: _disposeSongViewController,
    );
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final String status = watch(watchBackupStatusUseCase()).value;
    final SongViewMode viewMode = watch(songViewController.viewModeController).value;
    final String selectedArtist = watch(songViewController.selectedArtistController).value;
    final bool isGuest = watch(watchCurrentSessionUseCase()).value is GuestAuthSession;
    final HomeTab tab = watch(songViewController.homeTabController).value;
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    registerHandler(
      target: watchLocalSongsToTransferUseCase(),
      handler: _onLocalSongsToTransferChanged,
      executeImmediately: true,
    );

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isBackupRunning = status == _backupStatusExporting || status == _backupStatusImporting;
    final bool isSongsTab = tab == HomeTab.songs;
    final bool isArtistMode = viewMode == SongViewMode.artist;
    final String title = isArtistMode && selectedArtist.isNotEmpty ? selectedArtist : _homePageTitle;

    final bool hasSelectedArtist =
        isSongsTab && isArtistMode && songs.any((Song song) => song.author == selectedArtist);
    final DateTime now = DateTime.now();
    final PracticeStats stats = calculatePracticeStatsUseCase(sessions: sessions, recordings: recordings, now: now);
    final String? newSongAuthor = hasSelectedArtist ? selectedArtist : null;

    final Widget titleText = Text.rich(
      TextSpan(
        text: title,
        children: <InlineSpan>[
          TextSpan(
            text: '$_countSeparator${_getDisplayedSongCount(songs, viewMode, selectedArtist)}',
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
                  tooltip: _allArtistsTooltip,
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
            if (isSongsTab)
              IconButton(
                icon: Icon(isArtistMode ? Icons.view_list_outlined : Icons.people_outline),
                onPressed: songViewController.toggleViewMode,
                tooltip: isArtistMode ? _listModeTooltip : _artistModeTooltip,
              ),
            PopupMenuButton<_HomeMenuAction>(
              tooltip: _menuTooltip,
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!hasSelectedArtist)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMedium,
                      AppTheme.spacingSmall,
                      AppTheme.spacingMedium,
                      AppTheme.spacingSmall,
                    ),
                    child: PracticeOverviewWidget(
                      stats: stats,
                      today: PracticeStats.dayOf(now),
                      onOpenPressed: () => _openPractice(context),
                    ),
                  ),
                ),
              ),
            if (!hasSelectedArtist)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: SegmentedButton<HomeTab>(
                    segments: const <ButtonSegment<HomeTab>>[
                      ButtonSegment<HomeTab>(
                        value: HomeTab.songs,
                        icon: Icon(Icons.queue_music_outlined),
                        label: Text(_songsTab),
                      ),
                      ButtonSegment<HomeTab>(
                        value: HomeTab.covers,
                        icon: Icon(Icons.mic_none_outlined),
                        label: Text(_coversTab),
                      ),
                    ],
                    selected: <HomeTab>{tab},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<HomeTab> selected) => _onTabSelected(songViewController, selected),
                  ),
                ),
              ),
            Expanded(
              child: isSongsTab
                  ? SongsWidget(
                      songs: songs,
                      viewMode: viewMode,
                      selectedArtist: selectedArtist,
                      onArtistSelected: songViewController.selectArtist,
                      onSongTap: (Song song) => _navigateToLyrics(context, song),
                      onSongEdit: (Song song) => _showEditSongPage(context, song),
                      onSongDelete: (Song song) => _onSongDeletePressed(context, song),
                      onAddPressed: () => _showAddSongPage(context, newSongAuthor),
                    )
                  : const CoversListWidget(),
            ),
          ],
        ),
        floatingActionButton: songs.isEmpty || !isSongsTab
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddSongPage(context, newSongAuthor),
                icon: const Icon(Icons.add),
                label: const Text(_addLabel),
              ),
      ),
    );
  }

  List<PopupMenuEntry<_HomeMenuAction>> _buildMenuItems(BuildContext context, bool isGuest) {
    return <PopupMenuEntry<_HomeMenuAction>>[
      const PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.importSongs,
        child: ListTile(leading: Icon(Icons.file_upload_outlined), title: Text(_importLabel)),
      ),
      const PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.exportSongs,
        child: ListTile(leading: Icon(Icons.file_download_outlined), title: Text(_exportLabel)),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.signOut,
        child: ListTile(
          leading: Icon(isGuest ? Icons.login : Icons.logout),
          title: Text(isGuest ? _signInLabel : _signOutLabel),
        ),
      ),
    ];
  }

  int _getDisplayedSongCount(List<Song> songs, SongViewMode viewMode, String selectedArtist) {
    if (viewMode == SongViewMode.artist && selectedArtist.isNotEmpty) {
      return songs.where((Song song) => song.author == selectedArtist).length;
    }
    return songs.length;
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
      case _HomeMenuAction.signOut:
        _handleSignOut(messenger);
    }
  }

  Future<void> _handleExport(BuildContext context, ScaffoldMessengerState messenger) async {
    final bool? includeRecordings = await _askIncludeRecordings(context, _exportLabel, _exportQuestion);
    if (includeRecordings == null) return;
    final Result<void> result = await exportSongsUseCase(includeRecordings: includeRecordings);
    _showMessage(messenger, result.when(success: _exportCompleted, failure: _exportFailed));
  }

  Future<void> _handleImport(BuildContext context, ScaffoldMessengerState messenger) async {
    final bool? includeRecordings = await _askIncludeRecordings(context, _importLabel, _importQuestion);
    if (includeRecordings == null) return;
    final Result<void> result = await importSongsUseCase(includeRecordings: includeRecordings);
    _showMessage(messenger, result.when(success: _importCompleted, failure: _importFailed));
  }

  /// Asks whether the recordings go too; `null` when cancelled. The web keeps no recordings.
  Future<bool?> _askIncludeRecordings(BuildContext context, String title, String message) async {
    if (kIsWeb) return false;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => BackupOptionsDialogWidget(title: title, message: message, confirmLabel: title),
    );
  }

  Future<void> _handleSignOut(ScaffoldMessengerState messenger) async {
    final Result<void> result = await signOutUseCase();
    result.when(success: _ignore, failure: (String error) => _showMessage(messenger, error));
  }

  /// Shows the question after the current frame (the handler may run during a build).
  Future<void> _askToTransfer(BuildContext context, int songCount) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool? transfer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => TransferLocalSongsDialogWidget(songCount: songCount),
    );

    final Result<void> result = transfer == true ? await transferLocalSongsUseCase() : await keepLocalSongsUseCase();
    if (transfer == true && result.isSuccess) _showMessage(messenger, _transferredMessage);
    result.when(success: _ignore, failure: (String error) => _showMessage(messenger, error));
  }

  Future<void> _confirmDelete(BuildContext context, ScaffoldMessengerState messenger, Song song) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteSongDialogWidget(songName: song.name),
    );
    if (confirmed != true) {
      return;
    }

    final Result<void> result = await deleteSongUseCase(songId: song.id);
    _showMessage(messenger, result.when(success: _deleted, failure: _identity));
  }

  static void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void _ignore(void _) {}

  static String _identity(String error) => error;

  static String _deleted(void _) => _deletedMessage;

  static String _exportCompleted(void _) => _exportCompletedMessage;

  static String _exportFailed(String error) => '$_exportErrorPrefix$error';

  static String _importCompleted(void _) => _importCompletedMessage;

  static String _importFailed(String error) => '$_importErrorPrefix$error';

  void _navigateToLyrics(BuildContext context, Song song) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => LyricsPage(song: song)));
  }

  /// Shows the chosen tab; leaving the covers stops their playback.
  void _onTabSelected(SongViewController songViewController, Set<HomeTab> selected) {
    final HomeTab tab = selected.first;
    if (tab != HomeTab.covers) stopPlaybackUseCase();
    songViewController.selectTab(tab);
  }

  void _openPractice(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => const PracticePage()));
  }

  /// Opens the form of a new song; on an artist's page its author is filled in.
  void _showAddSongPage(BuildContext context, String? author) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => AddSongPage(author: author)));
  }

  void _showEditSongPage(BuildContext context, Song song) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => EditSongPage(song: song)));
  }
}
