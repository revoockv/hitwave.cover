import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../domain/entities/recording.dart';
import '../di/recordings_getters.dart';
import '../widgets/recordings_list_widget.dart';

/// Every cover recorded on this device, grouped by song (songs by name, the newest take first).
///
/// Playback stops when the page closes.
final class CoversPage extends WatchingWidget {
  static const String _title = 'Мої кавери';
  static const String _empty = 'Ще немає каверів. Відкрийте пісню, позначте «Запис» і натисніть «Старт».';
  static const String _unknownSong = 'Пісню видалено';
  static const String _titleSeparator = ' — ';

  /// Creates a new [CoversPage].
  const CoversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final Map<String, String> titles = <String, String>{
      for (final Song song in songs) song.id: '${song.name}$_titleSeparator${song.author}',
    };
    final List<Recording> grouped = recordings.toList()..sort((Recording a, Recording b) => _compare(a, b, titles));

    return PopScope(
      onPopInvokedWithResult: _onPopped,
      child: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: RecordingsListWidget(
              recordings: grouped,
              emptyText: _empty,
              headerOf: (Recording recording) => titles[recording.songId] ?? _unknownSong,
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
            ),
          ),
        ),
      ),
    );
  }

  /// Songs by title, then the newest take first.
  static int _compare(Recording a, Recording b, Map<String, String> titles) {
    final int bySong = (titles[a.songId] ?? _unknownSong).toLowerCase().compareTo(
      (titles[b.songId] ?? _unknownSong).toLowerCase(),
    );
    return bySong != 0 ? bySong : b.recordedAt.compareTo(a.recordedAt);
  }

  static void _onPopped(bool didPop, Object? result) {
    stopPlaybackUseCase();
  }
}
