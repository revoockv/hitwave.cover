import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';

/// Search field with a clear button.
final class SearchFieldWidget extends StatelessWidget {
  /// Text of the field.
  final TextEditingController searchController;

  /// Hint inside the empty field.
  final String hint;

  /// Creates a new [SearchFieldWidget].
  const SearchFieldWidget({super.key, required this.searchController, required this.hint});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
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
            : IconButton(tooltip: t.common.clear, onPressed: searchController.clear, icon: const Icon(Icons.close)),
      ),
    );
  }
}
