import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_change.dart';
import 'sync_change_group_widget.dart';

/// The texts of [SyncChangesWidget], with the other device's name already in them.
final class SyncChangesTexts {
  /// Title of the review.
  final String titleText;

  /// What to do.
  final String messageText;

  /// Heading of the changes that come to this device.
  final String toHereTitle;

  /// Heading of the changes that go to the other device.
  final String toThereTitle;

  /// Label of the "all" checkbox of a group.
  final String allLabel;

  /// Label of the apply button with the number of chosen changes.
  final String Function(int count) applyLabel;

  /// Label of the cancel button.
  final String cancelLabel;

  /// The badge of a change ("new", "deleted", "changed").
  final String Function(SyncChange change) badgeOf;

  /// What a change is about.
  final String Function(SyncChange change) titleOf;

  /// More about a change, or `null`.
  final String? Function(SyncChange change) detailOf;

  /// Creates the texts.
  const SyncChangesTexts({
    required this.titleText,
    required this.messageText,
    required this.toHereTitle,
    required this.toThereTitle,
    required this.allLabel,
    required this.applyLabel,
    required this.cancelLabel,
    required this.badgeOf,
    required this.titleOf,
    required this.detailOf,
  });
}

/// The changes of a synchronisation, in two groups (to this device, to the other one), each with a
/// checkbox and a coloured badge (add, delete, change), and the buttons that go on or cancel.
/// Knows nothing about use cases.
final class SyncChangesWidget extends StatelessWidget {
  /// Every change.
  final List<SyncChange> changes;

  /// Ids of the ticked changes.
  final Set<String> chosen;

  /// The texts.
  final SyncChangesTexts texts;

  /// Called with a change and whether it is now ticked.
  final void Function(SyncChange change, bool isChosen) onChosenChanged;

  /// Called with the changes of a group and whether they are all ticked now.
  final void Function(List<SyncChange> changes, bool isChosen) onAllChosenChanged;

  /// Called by the button that makes the ticked changes.
  final VoidCallback onApplyPressed;

  /// Called by the cancel button.
  final VoidCallback onCancelPressed;

  /// Creates a new [SyncChangesWidget].
  const SyncChangesWidget({
    super.key,
    required this.changes,
    required this.chosen,
    required this.texts,
    required this.onChosenChanged,
    required this.onAllChosenChanged,
    required this.onApplyPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<SyncChange> toHere = changes.where(_isToHere).toList();
    final List<SyncChange> toThere = changes.where(_isToThere).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(texts.titleText, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(texts.messageText, style: theme.textTheme.bodyMedium),
        if (toHere.isNotEmpty)
          SyncChangeGroupWidget(
            title: texts.toHereTitle,
            icon: Icons.south,
            changes: toHere,
            chosen: chosen,
            texts: texts,
            onChosenChanged: onChosenChanged,
            onAllChosenChanged: onAllChosenChanged,
          ),
        if (toThere.isNotEmpty)
          SyncChangeGroupWidget(
            title: texts.toThereTitle,
            icon: Icons.north,
            changes: toThere,
            chosen: chosen,
            texts: texts,
            onChosenChanged: onChosenChanged,
            onAllChosenChanged: onAllChosenChanged,
          ),
        const SizedBox(height: AppTheme.spacingMedium),
        FilledButton(onPressed: onApplyPressed, child: Text(texts.applyLabel(chosen.length))),
        TextButton(onPressed: onCancelPressed, child: Text(texts.cancelLabel)),
      ],
    );
  }

  static bool _isToHere(SyncChange change) => change.direction == SyncDirection.toHere;

  static bool _isToThere(SyncChange change) => change.direction == SyncDirection.toThere;
}
