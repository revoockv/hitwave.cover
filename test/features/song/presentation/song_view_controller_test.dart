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

  test('starts in artist mode with no artist selected', () {
    expect(songViewController.viewModeController.value, SongViewMode.artist);
    expect(songViewController.selectedArtistController.value, isEmpty);
  });

  test('toggling the view mode clears the selected artist', () {
    songViewController.selectArtist('Thorinshield');

    songViewController.toggleViewMode();

    expect(songViewController.viewModeController.value, SongViewMode.list);
    expect(songViewController.selectedArtistController.value, isEmpty);
  });
}
