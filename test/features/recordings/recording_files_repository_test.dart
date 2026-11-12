import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/recordings/data/repositories/recording_files_repository_impl.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/shared_song.dart';

void main() {
  test('a shared cover is named "yyyy-MM-dd-HH-mm Artist-Song.wav" and sent with "Artist - Song"', () {
    final Recording recording = Recording(
      id: 'r',
      songId: 's',
      recordedAt: DateTime(2026, 3, 7, 19, 5),
      durationSeconds: 30,
      rawPath: '/r_raw.wav',
      enhancedPath: null,
      keptFromSeconds: 0,
      keptToSeconds: null,
      status: RecordingStatus.enhanced,
      enhanceError: null,
    );
    const SharedSong song = SharedSong(author: 'Океан Ельзи', name: 'Обійми');

    expect(RecordingFilesRepositoryImpl.fileName(recording, song), '2026-03-07-19-05 Океан Ельзи-Обійми.wav');
    expect(
      RecordingFilesRepositoryImpl.fileName(recording, const SharedSong(author: 'AC/DC', name: 'T.N.T.')),
      '2026-03-07-19-05 AC DC-T.N.T..wav',
    );
    expect(RecordingFilesRepositoryImpl.message(song), 'Океан Ельзи - Обійми');
    expect(RecordingFilesRepositoryImpl.message(null), isNull);
  });
}
