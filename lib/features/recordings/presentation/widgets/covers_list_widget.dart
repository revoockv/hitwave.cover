import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/shared_song.dart';
import '../di/recordings_getters.dart';
import 'recordings_list_widget.dart';

/// Every cover recorded on this device, grouped by song (songs by name, the newest take first);
/// with a [query], only the covers of the songs whose name or artist contain it.
final class CoversListWidget extends WatchingWidget {
  static const String _empty = 'Ще немає каверів. Відкрийте пісню, позначте «Запис» і натисніть «Старт».';
  static const String _unknownSong = 'Пісню видалено';
  static const String _titleSeparator = ' — ';
  static const String _nothingFound = 'Нічого не знайдено.';

  /// Search text; empty shows every cover.
  final String query;

  /// Creates a new [CoversListWidget].
  const CoversListWidget({super.key, this.query = ''});

  @override
  Widget build(BuildContext context) {
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final Map<String, String> titles = <String, String>{
      for (final Song song in songs) song.id: '${song.name}$_titleSeparator${song.author}',
    };
    final Map<String, SharedSong> sharedSongs = <String, SharedSong>{
      for (final Song song in songs) song.id: SharedSong(author: song.author, name: song.name),
    };
    final String needle = query.trim().toLowerCase();
    final List<Recording> grouped =
        recordings
            .where((Recording recording) => (titles[recording.songId] ?? _unknownSong).toLowerCase().contains(needle))
            .toList()
          ..sort((Recording a, Recording b) => _compare(a, b, titles));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: RecordingsListWidget(
          recordings: grouped,
          emptyText: needle.isEmpty ? _empty : _nothingFound,
          headerOf: (Recording recording) => titles[recording.songId] ?? _unknownSong,
          songOf: (Recording recording) => sharedSongs[recording.songId],
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
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
}
