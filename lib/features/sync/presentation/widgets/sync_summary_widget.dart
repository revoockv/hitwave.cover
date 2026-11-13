import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_summary.dart';

/// What a synchronisation added on this and on the other device.
final class SyncSummaryWidget extends StatelessWidget {
  static const String _title = 'Синхронізовано';
  static const String _received = 'Додано сюди';
  static const String _sent = 'Додано на інший пристрій';
  static const String _songs = 'пісень: ';
  static const String _covers = 'каверів: ';
  static const String _sessions = 'тренувань: ';
  static const String _separator = ', ';
  static const double _iconSize = 64;

  /// The result.
  final SyncSummary summary;

  /// Called by the done button.
  final VoidCallback onDonePressed;

  /// Label of the done button.
  final String doneLabel;

  /// Creates a new [SyncSummaryWidget].
  const SyncSummaryWidget({super.key, required this.summary, required this.onDonePressed, required this.doneLabel});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: _iconSize, color: theme.colorScheme.primary),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(_title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(_received, style: theme.textTheme.titleSmall),
        Text(_counts(summary.songsReceived, summary.coversReceived, summary.sessionsReceived)),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(_sent, style: theme.textTheme.titleSmall),
        Text(_counts(summary.songsSent, summary.coversSent, summary.sessionsSent)),
        const SizedBox(height: AppTheme.spacingLarge),
        FilledButton(onPressed: onDonePressed, child: Text(doneLabel)),
      ],
    );
  }

  static String _counts(int songs, int covers, int sessions) =>
      '$_songs$songs$_separator$_covers$covers$_separator$_sessions$sessions';
}
