import 'package:flutter/material.dart';

/// One artist in the artist list: initial avatar, name and song count.
///
/// Tapping it calls [onTap] with the artist name.
final class ArtistTileWidget extends StatelessWidget {
  /// Shown in the avatar when the artist has no name.
  static const String _fallbackInitial = '?';

  /// Separator between the count and the word "songs".
  static const String _space = ' ';

  /// "song" after 1, 21, 31…
  static const String _songOne = 'пісня';

  /// "songs" after 2–4, 22–24…
  static const String _songFew = 'пісні';

  /// "songs" after 0, 5–20, 25–30…
  static const String _songMany = 'пісень';

  /// Base of the last digit.
  static const int _ten = 10;

  /// Base of the last two digits.
  static const int _hundred = 100;

  /// Smallest last digit of the "few" form.
  static const int _fewMin = 2;

  /// Largest last digit of the "few" form.
  static const int _fewMax = 4;

  /// Smallest of the teens, which always take the "many" form.
  static const int _teenMin = 11;

  /// Largest of the teens.
  static const int _teenMax = 14;

  /// Name of the artist.
  final String artist;

  /// Number of the artist's songs.
  final int songCount;

  /// Called with [artist] when the tile is tapped.
  final void Function(String artist) onTap;

  /// Creates a new [ArtistTileWidget].
  const ArtistTileWidget({required this.artist, required this.songCount, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String trimmed = artist.trim();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        child: Text(trimmed.isEmpty ? _fallbackInitial : trimmed.characters.first.toUpperCase()),
      ),
      title: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('$songCount$_space${songsWord(songCount)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _onTilePressed,
    );
  }

  void _onTilePressed() {
    onTap(artist);
  }

  /// Ukrainian plural of "song" for [count]: 1 пісня, 3 пісні, 5 пісень, 12 пісень.
  static String songsWord(int count) {
    final int lastDigit = count % _ten;
    final int lastTwo = count % _hundred;
    if (lastTwo >= _teenMin && lastTwo <= _teenMax) {
      return _songMany;
    }
    if (lastDigit == 1) {
      return _songOne;
    }
    if (lastDigit >= _fewMin && lastDigit <= _fewMax) {
      return _songFew;
    }
    return _songMany;
  }
}
