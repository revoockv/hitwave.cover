import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';

/// A list of recordings, or [emptyText] when there are none. With [headerOf], a header (the song) is shown above
/// every run of recordings with the same one.
///
/// Dumb: the recordings, the texts and one tile per recording ([tileBuilder], a wrapper keyed by its id) come from
/// above.
final class RecordingsListWidget extends StatelessWidget {
  /// The recordings, in the order to show.
  final List<Recording> recordings;

  /// Builds the tile of a recording; give it a key of the recording id.
  final Widget Function(Recording recording) tileBuilder;

  /// Header of a recording, or `null` for none.
  final String? Function(Recording recording)? headerOf;

  /// What tapping the header of a recording does (opens its song), or `null` when it does nothing.
  final VoidCallback? Function(Recording recording)? onHeaderPressedOf;

  /// Shown when there are no recordings.
  final String emptyText;

  /// Padding of the list.
  final EdgeInsets padding;

  /// Whether the list takes only the height of its tiles (inside another scrolling list).
  final bool shrinkWrap;

  /// Creates a new [RecordingsListWidget].
  const RecordingsListWidget({
    super.key,
    required this.recordings,
    required this.tileBuilder,
    required this.emptyText,
    this.headerOf,
    this.onHeaderPressedOf,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: padding,
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      itemCount: recordings.length,
      itemBuilder: (BuildContext context, int index) {
        final Recording recording = recordings[index];
        final String? header = headerOf?.call(recording);
        final bool showHeader = header != null && (index == 0 || headerOf?.call(recordings[index - 1]) != header);
        final Widget tile = tileBuilder(recording);
        if (!showHeader) return tile;
        return Column(
          key: ValueKey<String>(recording.id),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : AppTheme.spacingMedium, bottom: AppTheme.spacingSmall),
              child: _HeaderWidget(title: header, onPressed: onHeaderPressedOf?.call(recording)),
            ),
            tile,
          ],
        );
      },
    );
  }
}

/// The song above its recordings; with [onPressed], tapping it opens the song.
final class _HeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const _HeaderWidget({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Text text = Text(title, style: theme.textTheme.titleMedium);
    final VoidCallback? pressed = onPressed;
    if (pressed == null) return text;
    return InkWell(
      onTap: pressed,
      borderRadius: BorderRadius.circular(AppTheme.spacingSmall),
      child: Row(
        children: <Widget>[
          Flexible(child: text),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
