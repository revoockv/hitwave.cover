import 'package:flutter/material.dart';
import '../../../../core/presentation/theme.dart';
import '../../../../core/presentation/widgets/surface_widget.dart';
import '../../domain/entities/sync_change.dart';
import 'sync_changes_widget.dart';

/// One change: its checkbox, its coloured badge, what it is about and its detail.
final class SyncChangeWidget extends StatelessWidget {
  static const double _badgeAlpha = 0.16;
  static const double _stripeWidth = 4;

  /// The change.
  final SyncChange change;

  /// Whether the change will be applied.
  final bool isChosen;

  /// The texts.
  final SyncChangesTexts texts;

  /// Called with whether the change is now chosen.
  final ValueChanged<bool?> onChanged;

  /// Creates a new [SyncChangeWidget].
  const SyncChangeWidget({
    super.key,
    required this.change,
    required this.isChosen,
    required this.texts,
    required this.onChanged,
  });

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
