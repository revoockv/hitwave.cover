import 'package:flutter/material.dart';

/// Asks after a sign-in whether to move the songs on the device into the account.
///
/// Pops `true` to move them and `false` to keep them on the device.
final class TransferLocalSongsDialogWidget extends StatelessWidget {
  /// Dialog title.
  static const String _title = 'Перенести пісні в акаунт?';

  /// Text before the number of songs.
  static const String _countPrefix = 'Пісень на цьому пристрої: ';

  /// Explanation after the number of songs.
  static const String _explanation =
      '.\n\nПеренесені пісні будуть в акаунті на всіх пристроях і зникнуть звідси. '
      'Якщо лишити, вони будуть доступні, коли ви продовжите без акаунта.';

  /// Label of the keep button.
  static const String _keepLabel = 'Лишити на пристрої';

  /// Label of the transfer button.
  static const String _transferLabel = 'Перенести';

  /// Number of songs on the device.
  final int songCount;

  /// Creates a new [TransferLocalSongsDialogWidget].
  const TransferLocalSongsDialogWidget({required this.songCount, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.cloud_upload_outlined),
      title: const Text(_title),
      content: Text('$_countPrefix$songCount$_explanation'),
      actions: <Widget>[
        TextButton(onPressed: () => _onKeepPressed(context), child: const Text(_keepLabel)),
        FilledButton(onPressed: () => _onTransferPressed(context), child: const Text(_transferLabel)),
      ],
    );
  }

  void _onKeepPressed(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  void _onTransferPressed(BuildContext context) {
    Navigator.of(context).pop(true);
  }
}
