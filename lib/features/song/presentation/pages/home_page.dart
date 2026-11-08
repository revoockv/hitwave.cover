import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../auth/presentation/di/auth_getters.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import '../di/song_getters.dart';
import '../widgets/artist_switcher_title_widget.dart';
import '../widgets/delete_song_dialog_widget.dart';
import '../widgets/songs_widget.dart';
import 'add_song_page.dart';
import 'edit_song_page.dart';
import 'lyrics_page.dart';

/// Actions of the overflow menu on the home page.
enum _HomeMenuAction { importSongs, exportSongs, signOut }

/// Main home page with the song list, backup and account actions.
///
/// Watches the song list, the backup status and the view mode of its
/// [SongViewController].
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

  /// Tooltip of the overflow menu.
  static const String _menuTooltip = 'Ще';

  /// Label of the import menu item.
  static const String _importLabel = 'Імпортувати';

  /// Label of the export menu item.
  static const String _exportLabel = 'Експортувати';

  /// Label of the sign-out menu item.
  static const String _signOutLabel = 'Вийти';

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

  static SongViewController _createController() => SongViewController();

  static void _disposeController(SongViewController controller) => controller.dispose();

  @override
  Widget build(BuildContext context) {
    final SongViewController controller = createOnce(_createController, dispose: _disposeController);
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final String status = watch(watchBackupStatusUseCase()).value;
    final SongViewMode viewMode = watch(controller.viewMode).value;
    final String selectedArtist = watch(controller.selectedArtist).value;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isBackupRunning = status == _backupStatusExporting || status == _backupStatusImporting;
    final bool isArtistMode = viewMode == SongViewMode.artist;
    final String title = isArtistMode && selectedArtist.isNotEmpty ? selectedArtist : _homePageTitle;

    final bool hasSelectedArtist = isArtistMode && songs.any((Song song) => song.author == selectedArtist);

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
      onPopInvokedWithResult: (bool didPop, Object? result) => _onBackInvoked(controller, didPop),
      child: Scaffold(
        appBar: AppBar(
          leading: hasSelectedArtist
              ? IconButton(
                  tooltip: _allArtistsTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.clearArtist,
                )
              : null,
          title: hasSelectedArtist
              ? ArtistSwitcherTitleWidget(
                  title: titleText,
                  songs: songs,
                  selectedArtist: selectedArtist,
                  onArtistSelected: controller.selectArtist,
                )
              : titleText,
          actions: <Widget>[
            IconButton(
              icon: Icon(isArtistMode ? Icons.view_list_outlined : Icons.people_outline),
              onPressed: controller.toggleViewMode,
              tooltip: isArtistMode ? _listModeTooltip : _artistModeTooltip,
            ),
            PopupMenuButton<_HomeMenuAction>(
              tooltip: _menuTooltip,
              enabled: !isBackupRunning,
              onSelected: (_HomeMenuAction action) => _onMenuSelected(context, action),
              itemBuilder: _buildMenuItems,
            ),
          ],
          bottom: isBackupRunning
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(_progressHeight),
                  child: LinearProgressIndicator(minHeight: _progressHeight),
                )
              : null,
        ),
        body: SongsWidget(
          songs: songs,
          viewMode: viewMode,
          selectedArtist: selectedArtist,
          onArtistSelected: controller.selectArtist,
          onSongTap: (Song song) => _navigateToLyrics(context, song),
          onSongEdit: (Song song) => _showEditSongPage(context, song),
          onSongDelete: (Song song) => _onSongDeletePressed(context, song),
          onAddPressed: () => _showAddSongPage(context),
        ),
        floatingActionButton: songs.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddSongPage(context),
                icon: const Icon(Icons.add),
                label: const Text(_addLabel),
              ),
      ),
    );
  }

  List<PopupMenuEntry<_HomeMenuAction>> _buildMenuItems(BuildContext context) {
    return const <PopupMenuEntry<_HomeMenuAction>>[
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.importSongs,
        child: ListTile(leading: Icon(Icons.file_upload_outlined), title: Text(_importLabel)),
      ),
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.exportSongs,
        child: ListTile(leading: Icon(Icons.file_download_outlined), title: Text(_exportLabel)),
      ),
      PopupMenuDivider(),
      PopupMenuItem<_HomeMenuAction>(
        value: _HomeMenuAction.signOut,
        child: ListTile(leading: Icon(Icons.logout), title: Text(_signOutLabel)),
      ),
    ];
  }

  int _getDisplayedSongCount(List<Song> songs, SongViewMode viewMode, String selectedArtist) {
    if (viewMode == SongViewMode.artist && selectedArtist.isNotEmpty) {
      return songs.where((Song song) => song.author == selectedArtist).length;
    }
    return songs.length;
  }

  void _onBackInvoked(SongViewController controller, bool didPop) {
    if (!didPop) {
      controller.clearArtist();
    }
  }

  void _onSongDeletePressed(BuildContext context, Song song) {
    _confirmDelete(context, ScaffoldMessenger.of(context), song);
  }

  void _onMenuSelected(BuildContext context, _HomeMenuAction action) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _HomeMenuAction.importSongs:
        _handleImport(messenger);
      case _HomeMenuAction.exportSongs:
        _handleExport(messenger);
      case _HomeMenuAction.signOut:
        _handleSignOut(messenger);
    }
  }

  Future<void> _handleExport(ScaffoldMessengerState messenger) async {
    final Result<void> result = await exportSongsUseCase();
    _showMessage(messenger, result.when(success: _exportCompleted, failure: _exportFailed));
  }

  Future<void> _handleImport(ScaffoldMessengerState messenger) async {
    final Result<void> result = await importSongsUseCase();
    _showMessage(messenger, result.when(success: _importCompleted, failure: _importFailed));
  }

  Future<void> _handleSignOut(ScaffoldMessengerState messenger) async {
    final Result<void> result = await signOutUseCase();
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

  void _showAddSongPage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => const AddSongPage()));
  }

  void _showEditSongPage(BuildContext context, Song song) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => EditSongPage(song: song)));
  }
}
