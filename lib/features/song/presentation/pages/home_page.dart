
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../backup/domain/use_cases/watch_backup_status_use_case.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../domain/entities/song.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';
import '../controllers/song_view_controller.dart';
import '../widgets/add_song_view_widget.dart';
import '../widgets/song_list_widget.dart';
import 'lyrics_page.dart';

/// View mode for the song list display.
enum SongViewMode {
  /// Show all songs in a vertical list sorted by name.
  list,

  /// Show songs grouped by artist in horizontal lists.
  artist,
}

/// Main home page with song management and backup controls.
///
/// Displays a list of songs with options to add, export, and import songs.
/// Uses [WatchingWidget] to reactively watch song list and backup status changes.
final class HomePage extends WatchingStatefulWidget {
  /// Semi-transparent black color for backup status overlay.
  static const Color _overlayColor = Colors.black54;

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

  /// Padding for backup status overlay.
  static const double _contentPadding = 16;

  /// Alpha value for song count text opacity.
  static const double _songCountAlpha = 0.6;

  /// Creates a new [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Manager for song view mode and selected artist state.
  late final SongViewController _songViewController;

  @override
  void initState() {
    super.initState();
    _songViewController = SongViewController();
  }

  @override
  void dispose() {
    _songViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Song> songs = watchValue(
      (WatchListOfSongsUseCase watchListOfSongs) => watchListOfSongs(),
    );
    final String status = watchValue(
      (WatchBackupStatusUseCase watchBackupStatus) => watchBackupStatus(),
    );

    return ValueListenableBuilder<SongViewMode>(
      valueListenable: _songViewController.viewMode,
      builder: (BuildContext buildContext, SongViewMode viewMode, Widget? child) {
        return ValueListenableBuilder<String>(
          valueListenable: _songViewController.selectedArtist,
          builder: (BuildContext buildContext, String selectedArtist, Widget? child) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      viewMode == SongViewMode.artist && selectedArtist.isNotEmpty
                          ? selectedArtist
                          : HomePage._homePageTitle,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '(${_getDisplayedSongCount(songs, viewMode, selectedArtist)})',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: HomePage._songCountAlpha),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(
                      viewMode == SongViewMode.artist
                          ? Icons.view_list
                          : Icons.view_agenda,
                    ),
                    onPressed: _handleToggleViewMode,
                    tooltip: HomePage._viewModeTooltip,
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: () => _handleImport(context),
                    tooltip: HomePage._importTooltip,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _handleExport(context),
                    tooltip: HomePage._exportTooltip,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddSongDialog(context),
                  ),
                ],
              ),
              body: SongListViewWidget(
                songs: songs,
                viewMode: viewMode,
                selectedArtist: selectedArtist,
                onArtistSelected: _songViewController.selectArtist,
                onSongTap: (Song song) => _navigateToLyrics(context, song),
              ),
              bottomSheet: status != HomePage._backupStatusIdle && status != HomePage._backupStatusSuccess
                  ? Container(
                      padding: EdgeInsets.all(HomePage._contentPadding),
                      color: HomePage._overlayColor,
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  void _handleToggleViewMode() {
    _songViewController.toggleViewMode();
  }

  int _getDisplayedSongCount(List<Song> songs, SongViewMode viewMode, String selectedArtist) {
    if (viewMode == SongViewMode.artist && selectedArtist.isNotEmpty) {
      return songs.where((Song song) => song.author == selectedArtist).length;
    }
    return songs.length;
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      await exportSongsUseCase();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(HomePage._exportCompletedMessage)),
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
          const SnackBar(content: Text(HomePage._importCompletedMessage)),
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
