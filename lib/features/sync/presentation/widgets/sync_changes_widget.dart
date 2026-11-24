import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../../../core/presentation/widgets/surface_widget.dart';
import '../../domain/entities/sync_change.dart';

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
          _GroupWidget(
            title: texts.toHereTitle,
            icon: Icons.south,
            changes: toHere,
            chosen: chosen,
            texts: texts,
            onChosenChanged: onChosenChanged,
            onAllChosenChanged: onAllChosenChanged,
          ),
        if (toThere.isNotEmpty)
          _GroupWidget(
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

/// The changes made on one device, under a heading with "all" checkbox.
final class _GroupWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<SyncChange> changes;
  final Set<String> chosen;
  final SyncChangesTexts texts;
  final void Function(SyncChange change, bool isChosen) onChosenChanged;
  final void Function(List<SyncChange> changes, bool isChosen) onAllChosenChanged;

  const _GroupWidget({
    required this.title,
    required this.icon,
    required this.changes,
    required this.chosen,
    required this.texts,
    required this.onChosenChanged,
    required this.onAllChosenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int ticked = changes.where((SyncChange change) => chosen.contains(change.id)).length;
    final bool? all = ticked == 0 ? false : (ticked == changes.length ? true : null);
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: AppTheme.spacingMedium + AppTheme.spacingTiny, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              Text(texts.allLabel, style: theme.textTheme.labelMedium),
              Checkbox(
                tristate: true,
                value: all,
                onChanged: (bool? value) => onAllChosenChanged(changes, all != true),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          for (final SyncChange change in changes)
            _ChangeWidget(
              change: change,
              isChosen: chosen.contains(change.id),
              texts: texts,
              onChanged: (bool? value) => onChosenChanged(change, value ?? false),
            ),
        ],
      ),
    );
  }
}

/// One change: its checkbox, its coloured badge, what it is about and its detail.
final class _ChangeWidget extends StatelessWidget {
  static const double _badgeAlpha = 0.16;
  static const double _stripeWidth = 4;

  final SyncChange change;
  final bool isChosen;
  final SyncChangesTexts texts;
  final ValueChanged<bool?> onChanged;

  const _ChangeWidget({required this.change, required this.isChosen, required this.texts, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = switch (change.kind) {
      SyncChangeKind.add => AppTheme.accentGreen,
      SyncChangeKind.delete => theme.colorScheme.error,
      SyncChangeKind.update => AppTheme.accentBlue,
    };
    final String? detail = texts.detailOf(change);
    return SurfaceWidget(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: EdgeInsets.zero,
      onTap: _onTapped,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ColoredBox(
              color: color,
              child: const SizedBox(width: _stripeWidth),
            ),
            Checkbox(value: isChosen, onChanged: onChanged),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: _badgeAlpha),
                        borderRadius: BorderRadius.circular(AppTheme.spacingSmall),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingTiny, vertical: 2),
                        child: Text(texts.badgeOf(change), style: theme.textTheme.labelSmall?.copyWith(color: color)),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingTiny),
                    Text(texts.titleOf(change), style: theme.textTheme.titleSmall),
                    if (detail != null)
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
          ],
        ),
      ),
    );
  }

  void _onTapped() => onChanged(!isChosen);
}
