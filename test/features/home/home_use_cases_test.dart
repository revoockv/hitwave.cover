import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/history/domain/entities/usage_history.dart';
import 'package:hitwave.cover/features/home/domain/entities/recent_activity.dart';
import 'package:hitwave.cover/features/home/domain/use_cases/build_song_order_use_case.dart';
import 'package:hitwave.cover/features/home/domain/use_cases/find_recent_activity_use_case.dart';
import 'package:hitwave.cover/features/home/domain/use_cases/find_songs_use_case.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/cover_counts.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_sort.dart';

Song _song(String id, String author, String name, {String? album}) =>
    Song(id: id, author: author, name: name, album: album, lyrics: '', covers: const <Cover>[]);

Recording _take(String id, String songId) => Recording(
  id: id,
  songId: songId,
  recordedAt: DateTime(2026),
  durationSeconds: 1,
  rawPath: '/$id.wav',
  enhancedPath: null,
  keptFromSeconds: 0,
  keptToSeconds: null,
  status: RecordingStatus.recorded,
  enhanceFailure: null,
);

void main() {
  final Song obiimy = _song('a', 'Океан Ельзи', 'Обійми', album: 'Модель');
  final Song stefania = _song('b', 'Kalush', 'Stefania');
  final Song vona = _song('c', 'Океан Ельзи', 'Вона');
  final List<Song> songs = <Song>[obiimy, stefania, vona];

  test('a search finds songs by name, artist or album, ignoring case and spaces', () {
    const FindSongsUseCase findSongs = FindSongsUseCase();
    expect(findSongs(songs: songs, query: '  '), songs);
    expect(findSongs(songs: songs, query: 'океан'), <Song>[obiimy, vona]);
    expect(findSongs(songs: songs, query: 'МОДЕЛЬ'), <Song>[obiimy]);
    expect(findSongs(songs: songs, query: 'stef'), <Song>[stefania]);
  });

  test('songs are ordered by name, artist, last opened or covers; ties go by name', () {
    const BuildSongOrderUseCase order = BuildSongOrderUseCase();
    final UsageHistory history = UsageHistory(
      songsOpened: <UsageTime>[UsageTime(id: 'b', at: DateTime(2026, 2))],
    );
    final CoverCounts counts = CoverCounts.fromRecordings(<Recording>[_take('1', 'c'), _take('2', 'c')]);
    List<Song> by(SongSort sort) => order(songs: songs, sort: sort, history: history, coverCounts: counts);

    expect(by(SongSort.name), <Song>[stefania, vona, obiimy]);
    expect(by(SongSort.artists), <Song>[stefania, vona, obiimy]);
    expect(by(SongSort.recent), <Song>[stefania, vona, obiimy]);
    expect(by(SongSort.covers), <Song>[vona, stefania, obiimy]);
  });

  test('the recent activity is the songs and covers used last that still exist, newest first', () {
    const FindRecentActivityUseCase findRecent = FindRecentActivityUseCase();
    final UsageHistory history = UsageHistory(
      songsOpened: <UsageTime>[
        UsageTime(id: 'a', at: DateTime(2026, 1)),
        UsageTime(id: 'gone', at: DateTime(2026, 3)),
        UsageTime(id: 'c', at: DateTime(2026, 2)),
      ],
      coversPlayed: <UsageTime>[
        UsageTime(id: '1', at: DateTime(2026, 1)),
        UsageTime(id: '2', at: DateTime(2026, 2)),
      ],
    );
    final List<Recording> takes = <Recording>[_take('1', 'a'), _take('2', 'c'), _take('3', 'c')];

    final RecentActivity recent = findRecent(songs: songs, recordings: takes, history: history);

    expect(recent.songs, <Song>[vona, obiimy]);
    expect(recent.covers.map((Recording take) => take.id), <String>['2', '1']);
  });
}
