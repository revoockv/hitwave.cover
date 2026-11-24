import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/note.dart';

/// The strings of an instrument from the lowest one, the one being tuned marked.
///
/// Pure: [strings] and the [target] among them.
final class InstrumentStringsWidget extends StatelessWidget {
  /// The strings, lowest first.
  final List<Note> strings;

  /// The string being tuned, `null` while nothing clear sounds.
  final Note? target;

  /// Creates an [InstrumentStringsWidget].
  const InstrumentStringsWidget({required this.strings, required this.target, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppTheme.spacingSmall,
      runSpacing: AppTheme.spacingSmall,
      children: <Widget>[
        for (final Note string in strings)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingTiny),
            label: Text('${string.name}${string.octave}'),
            backgroundColor: string == target ? colors.primaryContainer : null,
            side: BorderSide(color: string == target ? colors.primary : colors.outlineVariant),
          ),
      ],
    );
  }
}
