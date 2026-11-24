import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/shared_song.dart';
import '../wrappers/song_recordings_wrapper.dart';
import 'recordings_list_page.dart';

/// Bottom sheet with the recordings of one song.
final class RecordingsSheetPage extends StatelessWidget {
  static const double _heightFactor = 0.7;

  /// The song whose recordings are shown.
  final String songId;

  /// The song, which shared recordings are named after.
  final SharedSong song;

  /// Creates a new [RecordingsSheetPage].
  const RecordingsSheetPage({super.key, required this.songId, required this.song});

  SharedSong _songOf(Recording recording) => song;

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * _heightFactor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.spacingLarge, 0, AppTheme.spacingLarge, AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(t.recordings.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacingMedium),
              Expanded(
                child: SongRecordingsWrapper(
                  songId: songId,
                  builder: (List<Recording> recordings) =>
                      RecordingsListPage(recordings: recordings, emptyText: t.recordings.noTakes, songOf: _songOf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
