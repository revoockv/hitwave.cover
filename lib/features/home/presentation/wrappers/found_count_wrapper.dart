import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../song/domain/entities/song.dart';
import '../di/home_getters.dart';

/// The number of songs the search finds, after the title of the songs tab; the only part that rebuilds while typing.
final class FoundCountWrapper extends WatchingWidget {
  /// All the songs.
  final List<Song> songs;

  /// The search field of the songs tab.
  final TextEditingController searchController;

  /// Put before the number.
  final String separator;

  /// Style of the number.
  final TextStyle style;

  /// Creates the wrapper.
  const FoundCountWrapper({
    super.key,
    required this.songs,
    required this.searchController,
    required this.separator,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final String query = watchPropertyValue(_textOf, target: searchController);
    return Text(
      '$separator${findSongsUseCase(songs: songs, query: query).length}',
      style: style,
    );
  }

  static String _textOf(TextEditingController searchController) => searchController.text;
}
