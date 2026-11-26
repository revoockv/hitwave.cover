import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result_state.dart';
import 'package:hitwave.cover/features/lyrics/presentation/controllers/lyrics_page_controller.dart';

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

  test('starts at the space saved with the song, or the default', () {
    final LyricsPageController savedController = LyricsPageController(lyrics: 'la', initialLeadIn: 0.1);
    final LyricsPageController defaultController = LyricsPageController(lyrics: 'la');
    addTearDown(savedController.dispose);
    addTearDown(defaultController.dispose);

    expect(savedController.leadInController.value, 0.1);
    expect(defaultController.leadInController.value, 0.4);
  });

  test('only a changed space may be saved', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la', initialLeadIn: 0.4);
    addTearDown(lyricsPageController.dispose);

    expect(lyricsPageController.canSaveLeadIn(0.4), isFalse);
    expect(lyricsPageController.canSaveLeadIn(0.0), isTrue);

    lyricsPageController.markLeadInSaved(0.0);
    expect(lyricsPageController.canSaveLeadIn(0.0), isFalse);
  });

  test('edited lyrics may be saved until they are marked saved', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la');
    addTearDown(lyricsPageController.dispose);

    expect(lyricsPageController.canSaveLyrics(), isFalse);

    lyricsPageController.lyricsTextController.text = 'la la';
    expect(lyricsPageController.hasUnsavedLyrics, isTrue);
    expect(lyricsPageController.canSaveLyrics(), isTrue);

    lyricsPageController.lyricsSavingStateController.value = ResultState.loading;
    expect(lyricsPageController.canSaveLyrics(), isFalse);

    lyricsPageController.markLyricsSaved('la la');
    expect(lyricsPageController.hasUnsavedLyrics, isFalse);
  });

  test('dispose marks the controller as disposed', () {
    final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la')..dispose();

    expect(lyricsPageController.isDisposed, isTrue);
  });
}
