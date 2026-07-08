import 'package:flutter/material.dart';

/// Cancel button for the add song dialog.
///
/// Pops the navigator when pressed.
final class AddSongCancelButtonWidget extends StatelessWidget {
  /// Creates a new [AddSongCancelButtonWidget].
  const AddSongCancelButtonWidget({super.key});

  /// Cancel button text.
  static const String _cancelButtonText = 'Скасувати';

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _onCancel(context),
      child: const Text(_cancelButtonText),
    );
  }

  /// Pops the navigator.
  VoidCallback _onCancel(BuildContext context) {
    return () {
      Navigator.pop(context);
    };
  }
}
