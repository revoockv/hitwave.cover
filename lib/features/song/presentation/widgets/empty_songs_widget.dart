import 'package:flutter/material.dart';
import '../../../../core/presentation/theme.dart';

/// The texts of [EmptySongsWidget].
final class EmptySongsTexts {
  /// Title of the empty state.
  final String titleText;

  /// Hint under the title.
  final String messageText;

  /// Label of the add button.
  final String addLabel;

  /// Creates the texts.
  const EmptySongsTexts({required this.titleText, required this.messageText, required this.addLabel});
}

/// Empty state shown when there are no songs yet.
///
/// An icon, a title, a hint and a button that calls [onAddPressed].
final class EmptySongsWidget extends StatelessWidget {
  /// Size of the music icon.
  static const double _iconSize = 72;

  /// The texts.
  final EmptySongsTexts texts;

  /// Called when the add button is pressed.
  final VoidCallback onAddPressed;

  /// Creates a new [EmptySongsWidget].
  const EmptySongsWidget({required this.texts, required this.onAddPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.library_music_outlined, size: _iconSize, color: theme.colorScheme.primary),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(texts.titleText, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              texts.messageText,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            FilledButton.icon(onPressed: onAddPressed, icon: const Icon(Icons.add), label: Text(texts.addLabel)),
          ],
        ),
      ),
    );
  }
}
