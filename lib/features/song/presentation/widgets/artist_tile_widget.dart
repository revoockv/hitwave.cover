import 'package:flutter/material.dart';
import '../../../../core/presentation/l10n/app_translations.dart';

/// One artist in the artist list: initial avatar, name and song count.
///
/// Tapping it calls [onTap] with the artist name.
final class ArtistTileWidget extends StatelessWidget {
  /// Shown in the avatar when the artist has no name.
  static const String _fallbackInitial = '?';

  /// Separator between the count and the word "songs".

  /// Name of the artist.
  final String artist;

  /// Number of the artist's songs.
  final int songCount;

  /// Whether this is the artist being shown.
  final bool selected;

  /// Called with [artist] when the tile is tapped.
  final void Function(String artist) onTap;

  /// Creates a new [ArtistTileWidget].
  const ArtistTileWidget({
    required this.artist,
    required this.songCount,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String trimmed = artist.trim();

    return ListTile(
      selected: selected,
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        child: Text(trimmed.isEmpty ? _fallbackInitial : trimmed.characters.first.toUpperCase()),
      ),
      title: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(context.t.song.songsCount(n: songCount)),
      trailing: const Icon(Icons.chevron_right),
      onTap: _onTilePressed,
    );
  }

  void _onTilePressed() {
    onTap(artist);
  }
}
