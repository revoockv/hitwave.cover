import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/presentation/theme.dart';

/// The QR code of this device with the code as text (to copy to a device that cannot scan).
final class SyncQrWidget extends StatelessWidget {
  static const String _hint =
      'На іншому пристрої відкрийте «Синхронізація» → «Сканувати QR-код». Обидва пристрої мають бути в одній мережі Wi‑Fi.';
  static const String _copyLabel = 'Скопіювати код';
  static const String _cancelLabel = 'Скасувати';
  static const double _qrSize = 240;
  static const Color _qrBackground = Color(0xFFFFFFFF);

  /// The sync code.
  final String code;

  /// Called by the copy button.
  final VoidCallback onCopyPressed;

  /// Called by the cancel button.
  final VoidCallback onCancelPressed;

  /// Creates a new [SyncQrWidget].
  const SyncQrWidget({super.key, required this.code, required this.onCopyPressed, required this.onCancelPressed});

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
        Text(_hint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingSmall),
        const LinearProgressIndicator(),
        const SizedBox(height: AppTheme.spacingMedium),
        Wrap(
          spacing: AppTheme.spacingSmall,
          alignment: WrapAlignment.center,
          children: <Widget>[
            OutlinedButton.icon(onPressed: onCopyPressed, icon: const Icon(Icons.copy), label: const Text(_copyLabel)),
            TextButton(onPressed: onCancelPressed, child: const Text(_cancelLabel)),
          ],
        ),
      ],
    );
  }
}
