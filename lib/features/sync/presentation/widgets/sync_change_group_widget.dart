import 'package:flutter/material.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_change.dart';
import 'sync_change_widget.dart';
import 'sync_changes_widget.dart';

/// The changes made on one device, under a heading with "all" checkbox.
final class SyncChangeGroupWidget extends StatelessWidget {
  /// Title of the group ("to here", "to there").
  final String title;

  /// Icon before the title.
  final IconData icon;

  /// The changes of the group.
  final List<SyncChange> changes;

  /// The ids of the chosen changes.
  final Set<String> chosen;

  /// The texts.
  final SyncChangesTexts texts;

  /// Called with a change and whether it is now chosen.
  final void Function(SyncChange change, bool isChosen) onChosenChanged;

  /// Called with the changes of the group and whether they are all chosen now.
  final void Function(List<SyncChange> changes, bool isChosen) onAllChosenChanged;

  /// Creates a new [SyncChangeGroupWidget].
  const SyncChangeGroupWidget({
    super.key,
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
            SyncChangeWidget(
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
