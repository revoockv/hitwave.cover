import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_change.dart';
import 'package:hitwave.cover/features/sync/presentation/controllers/sync_page_controller.dart';

void main() {
  const SyncChange delete = SyncChange(
    id: 'delete',
    kind: SyncChangeKind.delete,
    direction: SyncDirection.toHere,
    subject: SyncSubject.song,
    excludes: 'restore',
  );
  const SyncChange restore = SyncChange(
    id: 'restore',
    kind: SyncChangeKind.add,
    direction: SyncDirection.toThere,
    subject: SyncSubject.song,
    restores: true,
    excludes: 'delete',
    chosenFirst: false,
  );
  const SyncChange cover = SyncChange(
    id: 'cover',
    kind: SyncChangeKind.add,
    direction: SyncDirection.toHere,
    subject: SyncSubject.cover,
  );

  test('starts with the changes chosen first; ticking one unticks the one it excludes', () {
    final SyncPageController controller = SyncPageController()..resetChosen(const <SyncChange>[delete, restore, cover]);
    expect(controller.chosenController.value, <String>{'delete', 'cover'});

    controller.setChosen(restore, true);
    expect(controller.chosenController.value, <String>{'restore', 'cover'});

    controller.setAllChosen(const <SyncChange>[delete, cover], false);
    expect(controller.chosenController.value, <String>{'restore'});

    controller.setAllChosen(const <SyncChange>[delete, cover], true);
    expect(controller.chosenController.value, <String>{'delete', 'cover'});
    controller.dispose();
  });
}
