import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_conflict.dart';

/// The conflicts of a synchronisation with a choice for each, choices for all at once, and the
/// buttons that go on or cancel. Knows nothing about use cases.
final class SyncConflictsWidget extends StatelessWidget {
  static const String _title = 'Що робити з розбіжностями?';
  static const String _hint =
      'Ці пісні й кавери видалили або змінили лише на одному з пристроїв. Оберіть для кожного, що зробити на обох.';
  static const String _allDeletionsLabel = 'Усі видалення:';
  static const String _allChangesLabel = 'Усі зміни:';
  static const String _continueLabel = 'Продовжити';
  static const String _cancelLabel = 'Скасувати';
  static const String _restoreHere = 'Відновити тут';
  static const String _deleteThere = 'Видалити й там';
  static const String _restoreThere = 'Відновити там';
  static const String _deleteHere = 'Видалити й тут';
  static const String _takeOther = 'Взяти з іншого';
  static const String _keepThis = 'Залишити цю';
  static const Map<SyncConflictKind, String> _kindLabels = <SyncConflictKind, String>{
    SyncConflictKind.songDeletedHere: 'Пісню видалено на цьому пристрої',
    SyncConflictKind.songDeletedThere: 'Пісню видалено на іншому пристрої',
    SyncConflictKind.songChanged: 'Пісня відрізняється',
    SyncConflictKind.coverDeletedHere: 'Кавер видалено на цьому пристрої',
    SyncConflictKind.coverDeletedThere: 'Кавер видалено на іншому пристрої',
  };
  static const Map<SyncChoice, String> _bulkLabels = <SyncChoice, String>{
    SyncChoice.restore: 'відновити',
    SyncChoice.delete: 'видалити',
    SyncChoice.keepThis: 'залишити ці',
    SyncChoice.takeOther: 'взяти з іншого',
  };

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
    final ThemeData theme = Theme.of(context);
    final bool hasDeletions = conflicts.any(_isDeletion);
    final bool hasChanges = conflicts.any(_isChange);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(_title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(_hint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingMedium),
        if (hasDeletions)
          _BulkRowWidget(
            label: _allDeletionsLabel,
            choices: const <SyncChoice>[SyncChoice.restore, SyncChoice.delete],
            labels: _bulkLabels,
            onChosen: onAllDeletionsChosen,
          ),
        if (hasChanges)
          _BulkRowWidget(
            label: _allChangesLabel,
            choices: const <SyncChoice>[SyncChoice.keepThis, SyncChoice.takeOther],
            labels: _bulkLabels,
            onChosen: onAllChangesChosen,
          ),
        const SizedBox(height: AppTheme.spacingSmall),
        for (final SyncConflict conflict in conflicts)
          Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _kindLabels[conflict.kind]!,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(conflict.title, style: theme.textTheme.titleSmall),
                  if (conflict.detail case final String detail) Text(detail, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppTheme.spacingSmall),
                  SegmentedButton<SyncChoice>(
                    showSelectedIcon: false,
                    segments: <ButtonSegment<SyncChoice>>[
                      for (final SyncChoice choice in conflict.choices)
                        ButtonSegment<SyncChoice>(value: choice, label: Text(choiceLabel(conflict.kind, choice))),
                    ],
                    selected: <SyncChoice>{choices[conflict.id] ?? conflict.choices.first},
                    onSelectionChanged: (Set<SyncChoice> selected) => onChoiceChanged(conflict, selected.first),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppTheme.spacingMedium),
        FilledButton(onPressed: onContinuePressed, child: const Text(_continueLabel)),
        TextButton(onPressed: onCancelPressed, child: const Text(_cancelLabel)),
      ],
    );
  }

  /// What [choice] does for a conflict of [kind], from the point of view of this device.
  static String choiceLabel(SyncConflictKind kind, SyncChoice choice) => switch ((kind, choice)) {
    (SyncConflictKind.songDeletedHere || SyncConflictKind.coverDeletedHere, SyncChoice.restore) => _restoreHere,
    (SyncConflictKind.songDeletedHere || SyncConflictKind.coverDeletedHere, _) => _deleteThere,
    (SyncConflictKind.songDeletedThere || SyncConflictKind.coverDeletedThere, SyncChoice.restore) => _restoreThere,
    (SyncConflictKind.songDeletedThere || SyncConflictKind.coverDeletedThere, _) => _deleteHere,
    (SyncConflictKind.songChanged, SyncChoice.takeOther) => _takeOther,
    (SyncConflictKind.songChanged, _) => _keepThis,
  };

  static bool _isDeletion(SyncConflict conflict) => conflict.kind != SyncConflictKind.songChanged;

  static bool _isChange(SyncConflict conflict) => conflict.kind == SyncConflictKind.songChanged;
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
