import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import '../di/song_getters.dart';
import '../widgets/songs_widget.dart';
import 'add_song_page.dart';
import 'lyrics_page.dart';

/// Main home page with song management and backup controls.
///
/// Displays a list of songs with options to add, export, and import songs.
/// Watches the song list, the backup status and the view mode of its
/// [SongViewController].
final class HomePage extends WatchingWidget {
  /// Semi-transparent black color for backup status overlay.
  static const Color _overlayColor = Colors.black54;

  /// Text color of the backup status overlay.
  static const Color _overlayTextColor = Colors.white;

  /// Page title text.
  static const String _homePageTitle = 'Мої пісні';

  /// Tooltip text for the import button.
  static const String _importTooltip = 'Імпортувати';

  /// Tooltip text for the export button.
  static const String _exportTooltip = 'Експортувати';

  /// Tooltip text for the view mode toggle button.
  static const String _viewModeTooltip = 'Змінити вигляд';

  /// Status string for idle backup state.
  static const String _backupStatusIdle = 'idle';

  /// Status string for successful backup state.
  static const String _backupStatusSuccess = 'success';

  /// Success message shown after export completes.
  static const String _exportCompletedMessage = 'Експорт завершено';

  /// Success message shown after import completes.
  static const String _importCompletedMessage = 'Імпорт завершено';

  /// Prefix of the message shown when the export fails.
  static const String _exportErrorPrefix = 'Помилка експорту: ';

  /// Prefix of the message shown when the import fails.
  static const String _importErrorPrefix = 'Помилка імпорту: ';

  /// Opens the song count in the title.
  static const String _countOpen = '(';

  /// Closes the song count in the title.
  static const String _countClose = ')';

  /// Alpha value for song count text opacity.
  static const double _songCountAlpha = 0.6;

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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              viewMode == SongViewMode.artist && selectedArtist.isNotEmpty ? selectedArtist : _homePageTitle,
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacingSmall),
              child: Text(
                '$_countOpen${_getDisplayedSongCount(songs, viewMode, selectedArtist)}$_countClose',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: _songCountAlpha),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(viewMode == SongViewMode.artist ? Icons.view_list : Icons.view_agenda),
            onPressed: controller.toggleViewMode,
            tooltip: _viewModeTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _onImportPressed(context),
            tooltip: _importTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _onExportPressed(context),
            tooltip: _exportTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSongPage(context),
          ),
        ],
      ),
      body: SongsWidget(
        songs: songs,
        viewMode: viewMode,
        selectedArtist: selectedArtist,
        onArtistSelected: controller.selectArtist,
        onSongTap: (Song song) => _navigateToLyrics(context, song),
      ),
      bottomSheet: status != _backupStatusIdle && status != _backupStatusSuccess
          ? Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              color: _overlayColor,
              child: Text(
                status,
                style: const TextStyle(color: _overlayTextColor),
              ),
            )
          : null,
    );
  }

  int _getDisplayedSongCount(List<Song> songs, SongViewMode viewMode, String selectedArtist) {
    if (viewMode == SongViewMode.artist && selectedArtist.isNotEmpty) {
      return songs.where((Song song) => song.author == selectedArtist).length;
    }
    return songs.length;
  }

  void _onExportPressed(BuildContext context) {
    _handleExport(ScaffoldMessenger.of(context));
  }

  void _onImportPressed(BuildContext context) {
    _handleImport(ScaffoldMessenger.of(context));
  }

  Future<void> _handleExport(ScaffoldMessengerState messenger) async {
    final Result<void> result = await exportSongsUseCase();
    final String message = result.when(success: _exportCompleted, failure: _exportFailed);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleImport(ScaffoldMessengerState messenger) async {
    final Result<void> result = await importSongsUseCase();
    final String message = result.when(success: _importCompleted, failure: _importFailed);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static String _exportCompleted(void _) => _exportCompletedMessage;

  static String _exportFailed(String error) => '$_exportErrorPrefix$error';

  static String _importCompleted(void _) => _importCompletedMessage;

  static String _importFailed(String error) => '$_importErrorPrefix$error';

  void _navigateToLyrics(BuildContext context, Song song) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => LyricsPage(song: song),
      ),
    );
  }

  void _showAddSongPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AddSongPage(),
      ),
    );
  }
}
