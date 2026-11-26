import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/import_choice.dart';

/// The answer of an [ImportConflictDialogWidget]: what to do, and whether for the other songs too.
final class ImportConflictAnswer {
  /// What to do with the song.
  final ImportChoice choice;

  /// Whether the same goes for the other songs that are already here.
  final bool isForOthers;

  /// Creates an [ImportConflictAnswer].
  const ImportConflictAnswer({required this.choice, required this.isForOthers});
}

/// The texts of [ImportConflictDialogWidget], with the song and the numbers already in them.
final class ImportConflictTexts {
  /// Title of the dialog.
  final String titleText;

  /// Which song is already here.
  final String messageText;

  /// Whether its lyrics are the same.
  final String lyricsText;

  /// Label of the checkbox that answers for the other songs too ("Do the same for 5 others").
  final String forOthersLabel;

  /// Name and hint of replacing the song.
  final String replaceLabel;

  /// What replacing does.
  final String replaceHint;

  /// Name of keeping both.
  final String keepBothLabel;

  /// What keeping both does.
  final String keepBothHint;

  /// Name of skipping the song.
  final String skipLabel;

  /// What skipping does.
  final String skipHint;

  /// Label of the button that cancels the import.
  final String cancelLabel;

  /// Creates the texts.
  const ImportConflictTexts({
    required this.titleText,
    required this.messageText,
    required this.lyricsText,
    required this.forOthersLabel,
    required this.replaceLabel,
    required this.replaceHint,
    required this.keepBothLabel,
    required this.keepBothHint,
    required this.skipLabel,
    required this.skipHint,
    required this.cancelLabel,
  });
}

/// Asks what to do with a song of a backup that is already in the library, like a file manager asks about a file that
/// exists: replace it, keep both or skip, and maybe the same for the others.
///
/// Pops an [ImportConflictAnswer], or `null` when the import is cancelled. Dumb: it owns only its checkbox's notifier
/// (plain Flutter); the texts come from above.
final class ImportConflictDialogWidget extends StatefulWidget {
  /// How many other songs are already here after this one.
  final int othersCount;

  /// The texts.
  final ImportConflictTexts texts;

  /// Creates a new [ImportConflictDialogWidget].
  const ImportConflictDialogWidget({super.key, required this.othersCount, required this.texts});

  @override
  State<ImportConflictDialogWidget> createState() => _ImportConflictDialogWidgetState();
}

final class _ImportConflictDialogWidgetState extends State<ImportConflictDialogWidget> {
  late final ValueNotifier<bool> _forOthersController;

  @override
  void initState() {
    super.initState();
    _forOthersController = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _forOthersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ImportConflictTexts texts = widget.texts;
    return ValueListenableBuilder<bool>(
      valueListenable: _forOthersController,
      builder: (BuildContext context, bool isForOthers, Widget? child) => AlertDialog(
        title: Text(texts.titleText),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(texts.messageText),
              Text(
                texts.lyricsText,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              if (widget.othersCount > 0)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: isForOthers,
                  onChanged: _onForOthersChanged,
                  title: Text(texts.forOthersLabel),
                ),
              _OptionWidget(
                icon: Icons.find_replace,
                title: texts.replaceLabel,
                hint: texts.replaceHint,
                onTap: () => _onChosen(ImportChoice.replace, isForOthers),
              ),
              _OptionWidget(
                icon: Icons.library_add_outlined,
                title: texts.keepBothLabel,
                hint: texts.keepBothHint,
                onTap: () => _onChosen(ImportChoice.keepBoth, isForOthers),
              ),
              _OptionWidget(
                icon: Icons.redo,
                title: texts.skipLabel,
                hint: texts.skipHint,
                onTap: () => _onChosen(ImportChoice.skip, isForOthers),
              ),
            ],
          ),
        ),
        actions: <Widget>[TextButton(onPressed: _onCancelPressed, child: Text(texts.cancelLabel))],
      ),
    );
  }

  void _onForOthersChanged(bool? value) {
    _forOthersController.value = value ?? false;
  }

  void _onChosen(ImportChoice choice, bool isForOthers) {
    Navigator.of(context).pop(ImportConflictAnswer(choice: choice, isForOthers: isForOthers));
  }

  void _onCancelPressed() {
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
