import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/import_choice.dart';
import '../../domain/entities/import_conflict.dart';

/// The answer of an [ImportConflictDialogWidget]: what to do, and whether for the other songs too.
final class ImportConflictAnswer {
  /// What to do with the song.
  final ImportChoice choice;

  /// Whether the same goes for the other songs that are already here.
  final bool isForOthers;

  /// Creates an [ImportConflictAnswer].
  const ImportConflictAnswer({required this.choice, required this.isForOthers});
}

/// Asks what to do with a song of a backup that is already in the library, like a file manager
/// asks about a file that exists: replace it, keep both or skip, and maybe the same for the others.
///
/// Pops an [ImportConflictAnswer], or `null` when the import is cancelled.
final class ImportConflictDialogWidget extends WatchingWidget {
  static const String _songSeparator = ' — ';

  /// The song that is already here.
  final ImportConflict conflict;

  /// How many other songs are already here after this one.
  final int othersCount;

  /// Creates a new [ImportConflictDialogWidget].
  const ImportConflictDialogWidget({super.key, required this.conflict, required this.othersCount});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final ValueNotifier<bool> forOthersController = createOnce(_createForOthersController, dispose: _disposeController);
    final bool isForOthers = watch(forOthersController).value;

    return AlertDialog(
      title: Text(t.backup.conflictTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(t.backup.conflictMessage(song: '${conflict.author}$_songSeparator${conflict.name}')),
            Text(
              conflict.hasSameLyrics ? t.backup.sameLyrics : t.backup.otherLyrics,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            if (othersCount > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: isForOthers,
                onChanged: (bool? value) => _onForOthersChanged(forOthersController, value),
                title: Text(t.backup.forOthers(n: othersCount)),
              ),
            _OptionWidget(
              icon: Icons.find_replace,
              title: t.backup.replace,
              hint: t.backup.replaceHint,
              onTap: () => _onChosen(context, ImportChoice.replace, isForOthers),
            ),
            _OptionWidget(
              icon: Icons.library_add_outlined,
              title: t.backup.keepBoth,
              hint: t.backup.keepBothHint,
              onTap: () => _onChosen(context, ImportChoice.keepBoth, isForOthers),
            ),
            _OptionWidget(
              icon: Icons.redo,
              title: t.backup.skip,
              hint: t.backup.skipHint,
              onTap: () => _onChosen(context, ImportChoice.skip, isForOthers),
            ),
          ],
        ),
      ),
      actions: <Widget>[TextButton(onPressed: () => _onCancelPressed(context), child: Text(t.backup.cancelImport))],
    );
  }

  static ValueNotifier<bool> _createForOthersController() => ValueNotifier<bool>(false);

  static void _disposeController(ValueNotifier<bool> forOthersController) => forOthersController.dispose();

  void _onForOthersChanged(ValueNotifier<bool> forOthersController, bool? value) {
    forOthersController.value = value ?? false;
  }

  void _onChosen(BuildContext context, ImportChoice choice, bool isForOthers) {
    Navigator.of(context).pop(ImportConflictAnswer(choice: choice, isForOthers: isForOthers));
  }

  void _onCancelPressed(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// One way to solve the conflict: an icon, its name and what it does.
final class _OptionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  const _OptionWidget({required this.icon, required this.title, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(hint),
      onTap: onTap,
    );
  }
}
