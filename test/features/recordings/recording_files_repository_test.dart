import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/recordings/data/repositories/recording_files_repository_impl.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';

void main() {
  test('a shared cover is named "yyyy-MM-dd-HH-mm Artist-Song.wav"', () {
    final Recording recording = Recording(
      id: 'r',
      songId: 's',
      recordedAt: DateTime(2026, 3, 7, 9, 5),
      durationSeconds: 30,
      rawPath: '/r_raw.wav',
      enhancedPath: null,
      keptFromSeconds: 0,
      keptToSeconds: null,
      status: RecordingStatus.enhanced,
      enhanceError: null,
    );

    expect(
      RecordingFilesRepositoryImpl.fileName(recording, 'Океан Ельзи-Обійми'),
      '2026-03-07-09-05 Океан Ельзи-Обійми.wav',
    );
    expect(RecordingFilesRepositoryImpl.fileName(recording, 'AC/DC-T.N.T.'), '2026-03-07-09-05 AC DC-T.N.T..wav');
  });
}
