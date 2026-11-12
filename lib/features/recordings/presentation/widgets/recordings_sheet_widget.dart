import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';
import '../di/recordings_getters.dart';
import 'recordings_list_widget.dart';

/// Bottom sheet with the recordings of one song.
final class RecordingsSheetWidget extends WatchingWidget {
  static const String _title = 'Записи';
  static const String _empty = 'Ще немає записів. Позначте «Запис» і натисніть «Старт».';
  static const double _heightFactor = 0.7;

  /// The song whose recordings are shown.
  final String songId;

  /// `Artist-Song`: the name a shared recording is sent under.
  final String shareName;

  /// Creates a new [RecordingsSheetWidget].
  const RecordingsSheetWidget({super.key, required this.songId, required this.shareName});

  String _shareName(Recording recording) => shareName;

  @override
  Widget build(BuildContext context) {
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
              Text(_title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.spacingMedium),
              Expanded(
                child: RecordingsListWidget(recordings: recordings, emptyText: _empty, shareNameOf: _shareName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
