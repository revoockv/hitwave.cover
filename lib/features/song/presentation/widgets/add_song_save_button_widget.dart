import 'package:flutter/material.dart';

/// Save button for the add song dialog.
///
/// Shows a loading indicator while the add operation is in progress.
final class AddSongSaveButtonWidget extends StatelessWidget {
  /// Icon size for the loading indicator.
  static const double _loadingIconSize = 20;

  /// Add button text.
  static const String _addButtonText = 'Додати';

  /// Creates a new [AddSongSaveButtonWidget].
  const AddSongSaveButtonWidget({
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
                  width: AddSongSaveButtonWidget._loadingIconSize,
                  height: AddSongSaveButtonWidget._loadingIconSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(_addButtonText),
        );
      },
    );
  }
}
