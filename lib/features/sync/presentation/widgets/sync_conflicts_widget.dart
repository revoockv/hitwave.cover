import '../../../../core/presentation/widgets/surface_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_conflict.dart';
import '../l10n/sync_texts.dart';

/// The conflicts of a synchronisation with a choice for each, choices for all at once, and the
/// buttons that go on or cancel. Knows nothing about use cases.
final class SyncConflictsWidget extends StatelessWidget {
  /// The conflicts.
  final List<SyncConflict> conflicts;

  /// The choice of every conflict by id.
  final Map<String, SyncChoice> choices;

  /// Called with a conflict and its new choice.
  final void Function(SyncConflict conflict, SyncChoice choice) onChoiceChanged;

  /// Called with a choice for every deletion conflict.
  final ValueChanged<SyncChoice> onAllDeletionsChosen;

  /// Called with a choice for every changed song.
  final ValueChanged<SyncChoice> onAllChangesChosen;

  /// Called by the continue button.
  final VoidCallback onContinuePressed;

  /// Called by the cancel button.
  final VoidCallback onCancelPressed;

  /// Creates a new [SyncConflictsWidget].
  const SyncConflictsWidget({
    super.key,
    required this.conflicts,
    required this.choices,
    required this.onChoiceChanged,
    required this.onAllDeletionsChosen,
    required this.onAllChangesChosen,
    required this.onContinuePressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final bool hasDeletions = conflicts.any(_isDeletion);
    final bool hasChanges = conflicts.any(_isChange);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.sync.conflictsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(t.sync.conflictsMessage, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingMedium),
        if (hasDeletions)
          _BulkRowWidget(
            label: t.sync.allDeletions,
            choices: const <SyncChoice>[SyncChoice.restore, SyncChoice.delete],
            labels: _bulkLabels(t),
            onChosen: onAllDeletionsChosen,
          ),
        if (hasChanges)
          _BulkRowWidget(
            label: t.sync.allChanges,
            choices: const <SyncChoice>[SyncChoice.keepThis, SyncChoice.takeOther],
            labels: _bulkLabels(t),
            onChosen: onAllChangesChosen,
          ),
        const SizedBox(height: AppTheme.spacingSmall),
        for (final SyncConflict conflict in conflicts)
          SurfaceWidget(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _kindLabel(t, conflict.kind),
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(conflict.title(t), style: theme.textTheme.titleSmall),
                  if (conflict.detail(t) case final String detail) Text(detail, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppTheme.spacingSmall),
                  SegmentedButton<SyncChoice>(
                    showSelectedIcon: false,
                    segments: <ButtonSegment<SyncChoice>>[
                      for (final SyncChoice choice in conflict.choices)
                        ButtonSegment<SyncChoice>(value: choice, label: Text(choiceLabel(t, conflict.kind, choice))),
                    ],
                    selected: <SyncChoice>{choices[conflict.id] ?? conflict.choices.first},
                    onSelectionChanged: (Set<SyncChoice> selected) => onChoiceChanged(conflict, selected.first),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppTheme.spacingMedium),
        FilledButton(onPressed: onContinuePressed, child: Text(t.sync.continueSync)),
        TextButton(onPressed: onCancelPressed, child: Text(t.common.cancel)),
      ],
    );
  }

  /// What [choice] does for a conflict of [kind], from the point of view of this device.
  static String choiceLabel(Translations t, SyncConflictKind kind, SyncChoice choice) => switch ((kind, choice)) {
    (SyncConflictKind.songDeletedHere || SyncConflictKind.coverDeletedHere, SyncChoice.restore) => t.sync.restoreHere,
    (SyncConflictKind.songDeletedHere || SyncConflictKind.coverDeletedHere, _) => t.sync.deleteThere,
    (SyncConflictKind.songDeletedThere || SyncConflictKind.coverDeletedThere, SyncChoice.restore) =>
      t.sync.restoreThere,
    (SyncConflictKind.songDeletedThere || SyncConflictKind.coverDeletedThere, _) => t.sync.deleteHere,
    (SyncConflictKind.songChanged, SyncChoice.takeOther) => t.sync.takeOther,
    (SyncConflictKind.songChanged, _) => t.sync.keepThis,
  };

  static bool _isDeletion(SyncConflict conflict) => conflict.kind != SyncConflictKind.songChanged;

  static bool _isChange(SyncConflict conflict) => conflict.kind == SyncConflictKind.songChanged;

  static String _kindLabel(Translations t, SyncConflictKind kind) => switch (kind) {
    SyncConflictKind.songDeletedHere => t.sync.kind.songDeletedHere,
    SyncConflictKind.songDeletedThere => t.sync.kind.songDeletedThere,
    SyncConflictKind.songChanged => t.sync.kind.songChanged,
    SyncConflictKind.coverDeletedHere => t.sync.kind.coverDeletedHere,
    SyncConflictKind.coverDeletedThere => t.sync.kind.coverDeletedThere,
  };

  static Map<SyncChoice, String> _bulkLabels(Translations t) => <SyncChoice, String>{
    SyncChoice.restore: t.sync.bulk.restore,
    SyncChoice.delete: t.sync.bulk.delete,
    SyncChoice.keepThis: t.sync.bulk.keepThis,
    SyncChoice.takeOther: t.sync.bulk.takeOther,
  };
}

/// "All deletions: restore / delete".
final class _BulkRowWidget extends StatelessWidget {
  final String label;
  final List<SyncChoice> choices;
  final Map<SyncChoice, String> labels;
  final ValueChanged<SyncChoice> onChosen;

  const _BulkRowWidget({required this.label, required this.choices, required this.labels, required this.onChosen});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(label),
        for (final SyncChoice choice in choices)
          _BulkButtonWidget(choice: choice, label: labels[choice]!, onChosen: onChosen),
      ],
    );
  }
}

/// One choice for all conflicts of a kind.
final class _BulkButtonWidget extends StatelessWidget {
  final SyncChoice choice;
  final String label;
  final ValueChanged<SyncChoice> onChosen;

  const _BulkButtonWidget({required this.choice, required this.label, required this.onChosen});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: _onPressed, child: Text(label));
  }

  void _onPressed() => onChosen(choice);
}
