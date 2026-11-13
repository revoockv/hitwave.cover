import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';

/// Asks after a sign-in whether to move the songs on the device into the account.
///
/// Pops `true` to move them and `false` to keep them on the device.
final class TransferLocalSongsDialogWidget extends StatelessWidget {
  /// Number of songs on the device.
  final int songCount;

  /// Creates a new [TransferLocalSongsDialogWidget].
  const TransferLocalSongsDialogWidget({required this.songCount, super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    return AlertDialog(
      icon: const Icon(Icons.cloud_upload_outlined),
      title: Text(t.song.transferTitle),
      content: Text(t.song.transferMessage(n: songCount)),
      actions: <Widget>[
        TextButton(onPressed: () => _onKeepPressed(context), child: Text(t.song.keepOnDevice)),
        FilledButton(onPressed: () => _onTransferPressed(context), child: Text(t.song.transfer)),
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
