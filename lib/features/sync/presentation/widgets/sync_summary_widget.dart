import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// The texts of [SyncSummaryWidget], with the numbers already in them.
final class SyncSummaryTexts {
  /// Title ("Synced").
  final String titleText;

  /// Heading of what this device received.
  final String receivedTitle;

  /// What this device received, counted.
  final String receivedText;

  /// Heading of what the other device received.
  final String sentTitle;

  /// What the other device received, counted.
  final String sentText;

  /// Label of the done button.
  final String doneLabel;

  /// Creates the texts.
  const SyncSummaryTexts({
    required this.titleText,
    required this.receivedTitle,
    required this.receivedText,
    required this.sentTitle,
    required this.sentText,
    required this.doneLabel,
  });
}

/// What a synchronisation added on this and on the other device. Dumb: the counted texts come from above.
final class SyncSummaryWidget extends StatelessWidget {
  static const double _iconSize = 64;

  /// The texts.
  final SyncSummaryTexts texts;

  /// Called by the done button.
  final VoidCallback onDonePressed;

  /// Creates a new [SyncSummaryWidget].
  const SyncSummaryWidget({super.key, required this.texts, required this.onDonePressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: _iconSize, color: theme.colorScheme.primary),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(texts.titleText, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(texts.receivedTitle, style: theme.textTheme.titleSmall),
        Text(texts.receivedText),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(texts.sentTitle, style: theme.textTheme.titleSmall),
        Text(texts.sentText),
        const SizedBox(height: AppTheme.spacingLarge),
        FilledButton(onPressed: onDonePressed, child: Text(texts.doneLabel)),
      ],
    );
  }
}
