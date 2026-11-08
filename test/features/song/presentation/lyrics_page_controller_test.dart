import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/lyrics_page_controller.dart';

void main() {
  late List<double> saved;
  late Result<void> nextResult;

  Future<Result<void>> save(double speed) async {
    saved.add(speed);
    return nextResult;
  }

  setUp(() {
    saved = <double>[];
    nextResult = Result.ok;
  });

  test('starts at the speed saved with the song', () {
    final LyricsPageController controller = LyricsPageController(lyrics: 'la', initialSpeed: 0.8, saveSpeed: save);
    addTearDown(controller.dispose);

    expect(controller.speed.value, 0.8);
  });

  test('saves a changed speed once and skips an unchanged one', () async {
    final LyricsPageController controller = LyricsPageController(lyrics: 'la', initialSpeed: 0.5, saveSpeed: save);
    addTearDown(controller.dispose);

    await controller.saveSpeed(0.5);
    await controller.saveSpeed(0.7);
    await controller.saveSpeed(0.7);

    expect(saved, <double>[0.7]);
    expect(controller.speedSave.value.isSuccess, isTrue);
  });

  test('a failed save is retried on the next release', () async {
    nextResult = const Result.failure('offline');
    final LyricsPageController controller = LyricsPageController(lyrics: 'la', saveSpeed: save);
    addTearDown(controller.dispose);

    await controller.saveSpeed(0.9);
    expect(controller.speedSave.value.isFailure, isTrue);

    nextResult = Result.ok;
    await controller.saveSpeed(0.9);
    expect(saved, <double>[0.9, 0.9]);
  });
}
