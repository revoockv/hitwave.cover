import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/song_view_controller.dart';

void main() {
  late SongViewController songViewController;

  setUp(() {
    songViewController = SongViewController();
  });

  tearDown(() {
    songViewController.dispose();
  });

  test('starts on the home tab, songs by artist, nothing searched', () {
    expect(songViewController.homeTabController.value, HomeTab.home);
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

  test('switches tabs', () {
    songViewController.selectTab(HomeTab.covers);

    expect(songViewController.homeTabController.value, HomeTab.covers);
  });
}
