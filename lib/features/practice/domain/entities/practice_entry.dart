import '../../../recordings/domain/entities/recording.dart';
import 'practice_session.dart';

/// One item of the practice timeline: a session of a song with the takes recorded during it, or
/// a take recorded outside every session (an older or imported one).
final class PracticeEntry {
  /// A take starts a moment before its session and is stopped just before it ends.
  static const Duration takeSlack = Duration(seconds: 5);

  /// Id of the session; `null` for a take outside every session.
  final String? sessionId;

  /// The song practised.
  final String songId;

  /// When the session started, or when the take was recorded.
  final DateTime startedAt;

  /// How long the session lasted; `null` for a take outside every session.
  final Duration? duration;

  /// The takes recorded during the session, the newest first.
  final List<Recording> recordings;

  /// Creates a [PracticeEntry].
  const PracticeEntry({
    required this.sessionId,
    required this.songId,
    required this.startedAt,
    required this.duration,
    required this.recordings,
  });

  /// Whether takes were recorded.
  bool get hasTakes => recordings.isNotEmpty;

  /// The timeline of [sessions] and [recordings], the newest first.
  static List<PracticeEntry> listOf({required List<PracticeSession> sessions, required List<Recording> recordings}) {
    final Map<String, List<Recording>> takesBySession = <String, List<Recording>>{
      for (final PracticeSession session in sessions) session.id: <Recording>[],
    };
    final List<PracticeEntry> entries = <PracticeEntry>[];
    for (final Recording recording in recordings) {
      final PracticeSession? session = _sessionOf(recording, sessions);
      if (session != null) {
        takesBySession[session.id]!.add(recording);
      } else {
        entries.add(
          PracticeEntry(
            sessionId: null,
            songId: recording.songId,
            startedAt: recording.recordedAt,
            duration: null,
            recordings: <Recording>[recording],
          ),
        );
      }
    }
    for (final PracticeSession session in sessions) {
      entries.add(
        PracticeEntry(
          sessionId: session.id,
          songId: session.songId,
          startedAt: session.startedAt,
          duration: session.duration,
          recordings: takesBySession[session.id]!..sort(_newerFirst),
        ),
      );
    }
    return entries..sort(_newerEntryFirst);
  }

  /// The session of the same song during which [recording] was recorded, if any.
  static PracticeSession? _sessionOf(Recording recording, List<PracticeSession> sessions) {
    for (final PracticeSession session in sessions) {
      if (session.songId != recording.songId) continue;
      final DateTime from = session.startedAt.subtract(takeSlack);
      final DateTime to = session.startedAt.add(session.duration + takeSlack);
      if (!recording.recordedAt.isBefore(from) && !recording.recordedAt.isAfter(to)) return session;
    }
    return null;
  }

  static int _newerFirst(Recording a, Recording b) => b.recordedAt.compareTo(a.recordedAt);

  static int _newerEntryFirst(PracticeEntry a, PracticeEntry b) => b.startedAt.compareTo(a.startedAt);
}
