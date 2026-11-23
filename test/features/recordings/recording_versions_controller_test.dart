import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_version.dart';
import 'package:hitwave.cover/features/recordings/presentation/controllers/recording_versions_controller.dart';

void main() {
  test('switching the version of one card leaves the others as they are', () {
    final RecordingVersionsController recordingVersionsController = RecordingVersionsController();
    addTearDown(recordingVersionsController.dispose);

    expect(recordingVersionsController.versionOf('a'), RecordingVersion.enhanced);

    recordingVersionsController.choose('a', RecordingVersion.original);

    expect(recordingVersionsController.versionOf('a'), RecordingVersion.original);
    expect(recordingVersionsController.versionOf('b'), RecordingVersion.enhanced);
  });
}
