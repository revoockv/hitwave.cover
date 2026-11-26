import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// Search field with a clear button.
final class SearchFieldWidget extends StatelessWidget {
  /// Text of the field.
  final TextEditingController searchController;

  /// Hint inside the empty field.
  final String hintText;

  /// Tooltip of the clear button.
  final String clearTooltip;

  /// Creates a new [SearchFieldWidget].
  const SearchFieldWidget({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.clearTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(tooltip: clearTooltip, onPressed: searchController.clear, icon: const Icon(Icons.close)),
      ),
    );
  }
}
