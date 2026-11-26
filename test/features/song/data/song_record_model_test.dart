import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/cover_counts.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/song/data/models/cover_model.dart';
import 'package:hitwave.cover/features/song/data/models/song_record_model.dart';
import 'package:hitwave.cover/features/song/domain/entities/lyrics_layout.dart';

void main() {
  test('a song stored before the models is read with its covers and written back the same', () {
    final Map<dynamic, dynamic> stored = <dynamic, dynamic>{
      'id': 's1',
      'author': 'The Beatles',
      'name': 'Norwegian Wood',
      'album': null,
      'lyrics': 'I once had a girl',
      'scrollSpeed': 0.6,
      'leadIn': null,
      'wideScrollSpeed': null,
      'wideLeadIn': null,
      'covers': <dynamic>[
        <dynamic, dynamic>{'id': 'c1', 'timestamp': 1000, 'notes': 'first'},
      ],
    };

    final SongRecordModel record = SongRecordModel.fromStored(stored);

    expect(record.toSongModel().coverIds, <String>['c1']);
    expect(record.covers.single.notes, 'first');
    expect(record.toMap(), stored);
  });

  test('a change keeps the other fields; the album may be cleared', () {
    const SongRecordModel record = SongRecordModel(
      id: 's1',
      author: 'A',
      name: 'N',
      album: 'Rubber Soul',
      lyrics: 'la',
      scrollSpeed: 0.3,
      covers: <CoverModel>[CoverModel(id: 'c1', timestamp: 1, audioBytes: <int>[])],
    );

    final SongRecordModel changed = record.withScrollSpeed(LyricsLayout.wide, 0.9).withLyrics('la la');

    expect(changed.scrollSpeed, 0.3);
    expect(changed.wideScrollSpeed, 0.9);
    expect(changed.lyrics, 'la la');
    expect(changed.album, 'Rubber Soul');
    expect(changed.covers, hasLength(1));
  });

  test('cover counts answer per song, 0 for a song without covers', () {
    Recording take(String id, String songId) =>
        Recording(
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

    final CoverCounts counts = CoverCounts.fromRecordings(<Recording>[take('r1', 's1'), take('r2', 's1'), take('r3', 's2')]);

    expect(counts.of('s1'), 2);
    expect(counts.of('s2'), 1);
    expect(counts.of('s3'), 0);
  });
}
