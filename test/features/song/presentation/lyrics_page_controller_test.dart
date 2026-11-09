import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result_state.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/lyrics_page_controller.dart';

void main() {
  test('starts at the speed saved with the song', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la', initialSpeed: 0.8);
    addTearDown(lyricsPageController.dispose);

    expect(lyricsPageController.speedController.value, 0.8);
  });

  test('only a changed speed may be saved', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la', initialSpeed: 0.5);
    addTearDown(lyricsPageController.dispose);

    expect(lyricsPageController.canSaveSpeed(0.5), isFalse);
    expect(lyricsPageController.canSaveSpeed(0.7), isTrue);

    lyricsPageController.markSpeedSaved(0.7);
    expect(lyricsPageController.canSaveSpeed(0.7), isFalse);
  });

  test('no second speed save while one runs', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la');
    addTearDown(lyricsPageController.dispose);

    lyricsPageController.speedSavingStateController.value = ResultState.loading;

    expect(lyricsPageController.canSaveSpeed(0.9), isFalse);
  });

  test('dispose marks the controller as disposed', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la')..dispose();

    expect(lyricsPageController.isDisposed, isTrue);
  });
}
