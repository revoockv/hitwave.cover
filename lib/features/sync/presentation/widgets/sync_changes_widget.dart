import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../../../core/presentation/widgets/surface_widget.dart';
import '../../domain/entities/sync_change.dart';
import '../l10n/sync_texts.dart';

/// The changes of a synchronisation, in two groups (to this device, to the other one), each with a
/// checkbox and a coloured badge (add, delete, change), and the buttons that go on or cancel.
/// Knows nothing about use cases.
final class SyncChangesWidget extends StatelessWidget {
  /// Every change.
  final List<SyncChange> changes;

  /// Ids of the ticked changes.
  final Set<String> chosen;

  /// Name of the other device.
  final String peerName;

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
    required this.peerName,
    required this.onChosenChanged,
    required this.onAllChosenChanged,
    required this.onApplyPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final List<SyncChange> toHere = changes.where(_isToHere).toList();
    final List<SyncChange> toThere = changes.where(_isToThere).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.sync.reviewTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(t.sync.reviewMessage, style: theme.textTheme.bodyMedium),
        if (toHere.isNotEmpty)
          _GroupWidget(
            title: t.sync.toHere(device: peerName),
            icon: Icons.south,
            changes: toHere,
            chosen: chosen,
            peerName: peerName,
            allLabel: t.sync.all,
            onChosenChanged: onChosenChanged,
            onAllChosenChanged: onAllChosenChanged,
          ),
        if (toThere.isNotEmpty)
          _GroupWidget(
            title: t.sync.toThere(device: peerName),
            icon: Icons.north,
            changes: toThere,
            chosen: chosen,
            peerName: peerName,
            allLabel: t.sync.all,
            onChosenChanged: onChosenChanged,
            onAllChosenChanged: onAllChosenChanged,
          ),
        const SizedBox(height: AppTheme.spacingMedium),
        FilledButton(
          onPressed: onApplyPressed,
          child: Text(t.sync.applyChosen(n: chosen.length)),
        ),
        TextButton(onPressed: onCancelPressed, child: Text(t.common.cancel)),
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
  final String peerName;
  final String allLabel;
  final void Function(SyncChange change, bool isChosen) onChosenChanged;
  final void Function(List<SyncChange> changes, bool isChosen) onAllChosenChanged;

  const _GroupWidget({
    required this.title,
    required this.icon,
    required this.changes,
    required this.chosen,
    required this.peerName,
    required this.allLabel,
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
              Text(allLabel, style: theme.textTheme.labelMedium),
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
              peerName: peerName,
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
  final String peerName;
  final ValueChanged<bool?> onChanged;

  const _ChangeWidget({required this.change, required this.isChosen, required this.peerName, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final Color color = switch (change.kind) {
      SyncChangeKind.add => AppTheme.accentGreen,
      SyncChangeKind.delete => theme.colorScheme.error,
      SyncChangeKind.update => AppTheme.accentBlue,
    };
    final String? detail = change.detail(t, peerName);
    return SurfaceWidget(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: EdgeInsets.zero,
      onTap: () => onChanged(!isChosen),
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
                        child: Text(change.badge(t), style: theme.textTheme.labelSmall?.copyWith(color: color)),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingTiny),
                    Text(change.title(t), style: theme.textTheme.titleSmall),
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
}
