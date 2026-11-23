import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_summary.dart';

/// What a synchronisation added on this and on the other device.
final class SyncSummaryWidget extends StatelessWidget {
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
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: _iconSize, color: theme.colorScheme.primary),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(t.sync.synced, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(t.sync.received, style: theme.textTheme.titleSmall),
        Text(
          _counts(t, summary.songsReceived, summary.coversReceived, summary.sessionsReceived) +
              _changes(t, summary.deletedHere, summary.updatedHere),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(t.sync.sent, style: theme.textTheme.titleSmall),
        Text(
          _counts(t, summary.songsSent, summary.coversSent, summary.sessionsSent) +
              _changes(t, summary.deletedThere, summary.updatedThere),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        FilledButton(onPressed: onDonePressed, child: Text(doneLabel)),
      ],
    );
  }

  static String _changes(Translations t, int deleted, int updated) =>
      '$_separator${t.sync.deletedCount(n: deleted)}$_separator${t.sync.updatedCount(n: updated)}';

  static String _counts(Translations t, int songs, int covers, int sessions) =>
      '${t.sync.songsCount(n: songs)}$_separator${t.sync.coversCount(n: covers)}$_separator${t.sync.sessionsCount(n: sessions)}';
}
