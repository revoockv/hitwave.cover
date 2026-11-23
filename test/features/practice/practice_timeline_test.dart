import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_entry.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_entry_filter.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_session.dart';
import 'package:hitwave.cover/features/practice/domain/use_cases/build_practice_timeline_use_case.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';

Recording take(String id, String songId, DateTime at) => Recording(
  id: id,
  songId: songId,
  recordedAt: at,
  durationSeconds: 30,
  rawPath: '',
  enhancedPath: null,
  keptFromSeconds: 0,
  keptToSeconds: null,
  status: RecordingStatus.recorded,
  enhanceFailure: null,
);

void main() {
  final DateTime morning = DateTime(2026, 11, 17, 9);
  final DateTime noon = DateTime(2026, 11, 17, 12);
  final List<PracticeSession> sessions = <PracticeSession>[
    PracticeSession(id: 'scroll', songId: 'a', startedAt: morning, duration: const Duration(minutes: 4)),
    PracticeSession(id: 'sung', songId: 'b', startedAt: noon, duration: const Duration(minutes: 10)),
  ];
  final List<Recording> recordings = <Recording>[
    take('first', 'b', noon.subtract(const Duration(seconds: 2))),
    take('second', 'b', noon.add(const Duration(minutes: 5))),
    take('other song', 'a', noon.add(const Duration(minutes: 1))),
    take('old', 'a', DateTime(2026, 11, 1)),
  ];
  const BuildPracticeTimelineUseCase build = BuildPracticeTimelineUseCase();

  test('sessions carry the takes recorded during them; other takes stand alone; the newest first', () {
    final List<PracticeEntry> entries = build(
      sessions: sessions,
      recordings: recordings,
      filter: PracticeEntryFilter.all,
    );

    expect(
      entries.map((PracticeEntry e) => '${e.songId} ${e.startedAt} ${e.recordings.map((Recording r) => r.id)}'),
      <String>[
        'a ${noon.add(const Duration(minutes: 1))} (other song)',
        'b $noon (second, first)',
        'a $morning ()',
        'a ${DateTime(2026, 11, 1)} (old)',
      ],
    );
    expect(entries.first.duration, isNull);
    expect(entries[2].duration, const Duration(minutes: 4));
  });

  test('the filter shows only the practice without takes, or only the items with takes', () {
    List<String> songsOf(PracticeEntryFilter filter) => <String>[
      for (final PracticeEntry e in build(sessions: sessions, recordings: recordings, filter: filter))
        '${e.songId} ${e.recordings.length}',
    ];

    expect(songsOf(PracticeEntryFilter.practiceOnly), <String>['a 0']);
    expect(songsOf(PracticeEntryFilter.withTakes), <String>['a 1', 'b 2', 'a 1']);
  });
}
