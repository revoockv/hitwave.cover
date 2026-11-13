import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// Search field with a clear button.
final class SearchFieldWidget extends StatelessWidget {
  static const String _clearLabel = 'Очистити';

  /// Text of the field.
  final TextEditingController searchController;

  /// Hint inside the empty field.
  final String hint;

  /// Creates a new [SearchFieldWidget].
  const SearchFieldWidget({super.key, required this.searchController, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(tooltip: _clearLabel, onPressed: searchController.clear, icon: const Icon(Icons.close)),
      ),
    );
  }
}
