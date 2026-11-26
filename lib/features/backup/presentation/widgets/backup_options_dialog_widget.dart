import 'package:flutter/material.dart';

/// Asks whether the recordings go with the export or the import.
///
/// Pops `true` (with recordings) or `false` (songs only) when confirmed, and `null` when cancelled. Dumb: it owns only
/// its checkbox's notifier (plain Flutter); the texts come from above.
final class BackupOptionsDialogWidget extends StatefulWidget {
  /// Dialog title.
  final String title;

  /// Text under the title.
  final String message;

  /// Label of the confirm button.
  final String confirmLabel;

  /// Label of the checkbox that adds the recordings.
  final String includeRecordingsLabel;

  /// What adding the recordings means.
  final String recordingsNote;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Creates a new [BackupOptionsDialogWidget].
  const BackupOptionsDialogWidget({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.includeRecordingsLabel,
    required this.recordingsNote,
    required this.cancelLabel,
  });

  @override
  State<BackupOptionsDialogWidget> createState() => _BackupOptionsDialogWidgetState();
}

final class _BackupOptionsDialogWidgetState extends State<BackupOptionsDialogWidget> {
  late final ValueNotifier<bool> _includeRecordingsController;

  @override
  void initState() {
    super.initState();
    _includeRecordingsController = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _includeRecordingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _includeRecordingsController,
      builder: (BuildContext context, bool includeRecordings, Widget? child) => AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.message),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: includeRecordings,
              onChanged: _onIncludeRecordingsChanged,
              title: Text(widget.includeRecordingsLabel),
              subtitle: Text(widget.recordingsNote),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: _onCancelPressed, child: Text(widget.cancelLabel)),
          FilledButton(onPressed: _onConfirmPressed, child: Text(widget.confirmLabel)),
        ],
      ),
    );
  }

  void _onIncludeRecordingsChanged(bool? value) {
    _includeRecordingsController.value = value ?? false;
  }

  void _onCancelPressed() {
    Navigator.of(context).pop();
  }

  void _onConfirmPressed() {
    Navigator.of(context).pop(_includeRecordingsController.value);
  }
}
