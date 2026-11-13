import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/shared_song.dart';
import '../di/recordings_getters.dart';
import 'recordings_list_widget.dart';

/// Bottom sheet with the recordings of one song.
final class RecordingsSheetWidget extends WatchingWidget {
  static const double _heightFactor = 0.7;

  /// The song whose recordings are shown.
  final String songId;

  /// The song, which shared recordings are named after.
  final SharedSong song;

  /// Creates a new [RecordingsSheetWidget].
  const RecordingsSheetWidget({super.key, required this.songId, required this.song});

  SharedSong _songOf(Recording recording) => song;

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final List<Recording> recordings = watch(
      watchRecordingsUseCase(),
    ).value.where((Recording recording) => recording.songId == songId).toList();

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
                child: RecordingsListWidget(recordings: recordings, emptyText: t.recordings.noTakes, songOf: _songOf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
