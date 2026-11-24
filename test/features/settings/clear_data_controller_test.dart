import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/settings/domain/entities/clearable_data.dart';
import 'package:hitwave.cover/features/settings/presentation/controllers/clear_data_controller.dart';

void main() {
  test('nothing is chosen at first; data is chosen and left out', () {
    final ClearDataController controller = ClearDataController();

    expect(controller.selectionController.value, isEmpty);
    controller.choose(ClearableData.practice, chosen: true);
    controller.choose(ClearableData.history, chosen: true);
    controller.choose(ClearableData.practice, chosen: false);

    expect(controller.selectionController.value, <ClearableData>{ClearableData.history});
    controller.dispose();
    expect(controller.isDisposed, isTrue);
  });

  test('the covers go with the songs and stay chosen while the songs are', () {
    final ClearDataController controller = ClearDataController();

    controller.choose(ClearableData.songs, chosen: true);
    expect(controller.selectionController.value, <ClearableData>{ClearableData.songs, ClearableData.covers});

    controller.choose(ClearableData.covers, chosen: false);
    expect(controller.selectionController.value, contains(ClearableData.covers));

    controller.choose(ClearableData.songs, chosen: false);
    controller.choose(ClearableData.covers, chosen: false);
    expect(controller.selectionController.value, isEmpty);
    controller.dispose();
  });
}
