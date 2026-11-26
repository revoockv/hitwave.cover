import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// The covers tab: the search field above the timeline of covers.
///
/// Dumb: both come as widgets — the search field, and the timeline (a page that owns the actions on takes).
final class CoversTabWidget extends StatelessWidget {
  /// The search field of the covers.
  final Widget searchField;

  /// The timeline of covers.
  final Widget timeline;

  /// Creates a new [CoversTabWidget].
  const CoversTabWidget({super.key, required this.searchField, required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMedium,
                AppTheme.spacingSmall,
                AppTheme.spacingMedium,
                0,
              ),
              child: searchField,
            ),
          ),
        ),
        Expanded(child: timeline),
      ],
    );
  }
}
