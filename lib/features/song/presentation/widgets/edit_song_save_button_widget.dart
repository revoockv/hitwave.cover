import 'package:flutter/material.dart';

/// Save button for the edit song dialog.
///
/// Shows a loading indicator while the update operation is in progress.
final class EditSongSaveButtonWidget extends StatelessWidget {
  /// Icon size for the loading indicator.
  static const double _loadingIconSize = 20;

  /// Save button text.
  static const String _saveButtonText = 'Зберегти';

  /// Creates a new [EditSongSaveButtonWidget].
  const EditSongSaveButtonWidget({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  /// The [ValueNotifier] for loading state.
  final ValueNotifier<bool> isLoading;

  /// The save callback.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoading,
      builder: (BuildContext context, bool loading, Widget? child) {
        return ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: loading
              ? SizedBox(
                  width: EditSongSaveButtonWidget._loadingIconSize,
                  height: EditSongSaveButtonWidget._loadingIconSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(_saveButtonText),
        );
      },
    );
  }
}
