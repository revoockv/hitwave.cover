import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/song_view_controller.dart';

void main() {
  late SongViewController controller;

  setUp(() {
    controller = SongViewController();
  });

  tearDown(() {
    controller.dispose();
  });

  test('starts in artist mode with no artist selected', () {
    expect(controller.viewMode.value, SongViewMode.artist);
    expect(controller.selectedArtist.value, isEmpty);
  });

  test('toggling the view mode clears the selected artist', () {
    controller.selectArtist('Thorinshield');

    controller.toggleViewMode();

    expect(controller.viewMode.value, SongViewMode.list);
    expect(controller.selectedArtist.value, isEmpty);
  });
}
