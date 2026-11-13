import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/presentation/widgets/artist_tile_widget.dart';

void main() {
  test('song count uses the right Ukrainian plural', () {
    expect(ArtistTileWidget.songsWord(1), 'пісня');
    expect(ArtistTileWidget.songsWord(21), 'пісня');
    expect(ArtistTileWidget.songsWord(3), 'пісні');
    expect(ArtistTileWidget.songsWord(24), 'пісні');
    expect(ArtistTileWidget.songsWord(5), 'пісень');
    expect(ArtistTileWidget.songsWord(11), 'пісень');
    expect(ArtistTileWidget.songsWord(12), 'пісень');
    expect(ArtistTileWidget.songsWord(0), 'пісень');
  });
}
