
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../backup/domain/use_cases/watch_backup_status_use_case.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../domain/entities/song.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';
import '../widgets/add_song_view_widget.dart';
import '../widgets/song_list_widget.dart';
import 'lyrics_page.dart';

/// Main home page with song management and backup controls.
///
/// Displays a list of songs with options to add, export, and import songs.
/// Uses [WatchingWidget] to reactively watch song list and backup status changes.
final class HomePage extends WatchingWidget {
  /// Semi-transparent black color for backup status overlay.
  static const Color _overlayColor = Colors.black54;

  /// Page title text.
  static const String _homePageTitle = 'Мої пісні';

  /// Tooltip text for the import button.
  static const String _importTooltip = 'Імпортувати';

  /// Tooltip text for the export button.
  static const String _exportTooltip = 'Експортувати';

  /// Status string for idle backup state.
  static const String _backupStatusIdle = 'idle';

  /// Status string for successful backup state.
  static const String _backupStatusSuccess = 'success';

  /// Success message shown after export completes.
  static const String _exportCompletedMessage = 'Експорт завершено';

  /// Success message shown after import completes.
  static const String _importCompletedMessage = 'Імпорт завершено';

  /// Creates a new [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Song> songs = watchValue(
      (WatchListOfSongsUseCase watchListOfSongs) => watchListOfSongs(),
    );
    final String status = watchValue(
      (WatchBackupStatusUseCase watchBackupStatus) => watchBackupStatus(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(_homePageTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _handleImport(context),
            tooltip: _importTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _handleExport(context),
            tooltip: _exportTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSongDialog(context),
          ),
        ],
      ),
      body: SongListViewWidget(
        songs: songs,
        onSongTap: (Song song) => _navigateToLyrics(context, song),
      ),
      bottomSheet: status != _backupStatusIdle && status != _backupStatusSuccess
          ? Container(
              padding: const EdgeInsets.all(16),
              color: HomePage._overlayColor,
              child: Text(
                status,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      await exportSongsUseCase();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_exportCompletedMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка експорту: $e')),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      await importSongsUseCase();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_importCompletedMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка імпорту: $e')),
        );
      }
    }
  }

  void _navigateToLyrics(BuildContext context, Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => LyricsPage(song: song),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AddSongDialogWidget(),
    );
  }
}
