import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/presentation/theme.dart';

/// The texts of [SyncQrWidget].
final class SyncQrTexts {
  /// How to use the code.
  final String hintText;

  /// Shown while waiting for the other device.
  final String waitingText;

  /// Label of the copy button.
  final String copyCodeLabel;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Creates the texts.
  const SyncQrTexts({
    required this.hintText,
    required this.waitingText,
    required this.copyCodeLabel,
    required this.cancelLabel,
  });
}

/// The QR code of this device with the code as text (to copy to a device that cannot scan).
final class SyncQrWidget extends StatelessWidget {
  static const double _qrSize = 240;
  static const Color _qrBackground = Color(0xFFFFFFFF);

  /// The sync code.
  final String code;

  /// The texts.
  final SyncQrTexts texts;

  /// Called by the copy button.
  final VoidCallback onCopyPressed;

  /// Called by the cancel button.
  final VoidCallback onCancelPressed;

  /// Creates a new [SyncQrWidget].
  const SyncQrWidget({
    super.key,
    required this.code,
    required this.texts,
    required this.onCopyPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: QrImageView(
            data: code,
            size: _qrSize,
            backgroundColor: _qrBackground,
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(texts.hintText, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(texts.waitingText, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingSmall),
        const LinearProgressIndicator(),
        const SizedBox(height: AppTheme.spacingMedium),
        Wrap(
          spacing: AppTheme.spacingSmall,
          alignment: WrapAlignment.center,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: onCopyPressed,
              icon: const Icon(Icons.copy),
              label: Text(texts.copyCodeLabel),
            ),
            TextButton(onPressed: onCancelPressed, child: Text(texts.cancelLabel)),
          ],
        ),
      ],
    );
  }
}
