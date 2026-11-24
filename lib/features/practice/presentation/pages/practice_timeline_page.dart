import 'package:flutter/material.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/recordings_failure.dart';
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/presentation/l10n/recordings_texts.dart';
import '../../../recordings/presentation/widgets/recordings_list_widget.dart';
import '../../../song/domain/entities/song.dart';
import '../../domain/entities/practice_entry.dart';
import '../../domain/entities/practice_entry_filter.dart';
import '../../domain/entities/practice_failure.dart';
import '../di/practice_getters.dart';
import '../l10n/practice_texts.dart';
import '../widgets/delete_practice_dialog_widget.dart';
import '../wrappers/practice_timeline_wrapper.dart';

/// The covers tab's timeline: deletes a session (and, when chosen, its takes) after asking, and places the takes list
/// of the recordings feature into every entry. Never rebuilds — its wrapper builds the entries.
final class PracticeTimelinePage extends StatelessWidget {
  /// Search text; empty shows every item.
  final String query;

  /// Which items are shown.
  final PracticeEntryFilter filter;

  /// Called with the filter chosen.
  final ValueChanged<PracticeEntryFilter> onFilterChanged;

  /// Opens a song (tapping its title).
  final ValueChanged<Song> onSongPressed;

  /// Creates a new [PracticeTimelinePage].
  const PracticeTimelinePage({
    super.key,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.onSongPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    return PracticeTimelineWrapper(
      query: query,
      filter: filter,
      texts: t.practiceTexts,
      takesBuilder: (PracticeEntry entry, Song? song) => RecordingsListWidget(
        recordings: entry.recordings,
        emptyText: t.recordings.noTakes,
        songOf: (Recording recording) => song == null ? null : SharedSong(author: song.author, name: song.name),
        shrinkWrap: true,
      ),
      onFilterChanged: onFilterChanged,
      onSongPressed: onSongPressed,
      onDeletePressed: (PracticeEntry entry) => _onDeletePressed(context, entry),
    );
  }

  /// Asks, then deletes the session of [entry] and — when chosen — its takes.
  Future<void> _onDeletePressed(BuildContext context, PracticeEntry entry) async {
    final String? sessionId = entry.sessionId;
    if (sessionId == null) return;
    final bool? withTakes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          DeletePracticeDialogWidget(takeCount: entry.recordings.length, texts: context.t.practiceTexts),
    );
    if (withTakes == null) return;
    if (!context.mounted) return;
    final Translations t = context.t;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (withTakes) {
      if (entry.recordings.any((Recording r) => r.id == watchPlaybackUseCase().value.recordingId)) {
        await stopPlaybackUseCase();
      }
      for (final Recording recording in entry.recordings) {
        final Result<void, RecordingsFailure> deleted = await deleteRecordingUseCase(recording.id);
        if (deleted case FailureResult<void, RecordingsFailure>(:final RecordingsFailure failure)) {
          messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
          return;
        }
      }
    }
    final Result<void, PracticeFailure> result = await deletePracticeSessionUseCase(sessionId);
    if (result case FailureResult<void, PracticeFailure>(:final PracticeFailure failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
    }
  }
}
