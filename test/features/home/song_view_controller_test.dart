import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/home/presentation/controllers/song_view_controller.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_sort.dart';

void main() {
  late SongViewController songViewController;

  setUp(() {
    songViewController = SongViewController();
  });

  tearDown(() {
    songViewController.dispose();
  });

  test('starts with songs by artist, nothing searched', () {
    expect(songViewController.songSortController.value, SongSort.artists);
    expect(songViewController.selectedArtistController.value, isEmpty);
    expect(songViewController.songSearchController.text, isEmpty);
  });

  test('choosing another order clears the selected artist', () {
    songViewController.selectArtist('Thorinshield');

    songViewController.selectSort(SongSort.recent);

    expect(songViewController.songSortController.value, SongSort.recent);
    expect(songViewController.selectedArtistController.value, isEmpty);
  });
}
