import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/playback_state.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../controllers/recording_versions_controller.dart';
import '../di/recordings_getters.dart';
import '../widgets/recording_tile_widget.dart';
import 'enhance_progress_wrapper.dart';
import 'playback_progress_wrapper.dart';

/// Gives [RecordingTileWidget] what its take is now: loaded, playing, the chosen version, being shared. Rebuilds
/// only when one of these changes for this take — playing another take does not rebuild it.
final class RecordingTileWrapper extends WatchingWidget {
  /// The take.
  final Recording recording;

  /// The chosen versions and the takes being shared, owned by the page.
  final RecordingVersionsController recordingVersionsController;

  /// Whether the device can show a file in its folder.
  final bool canShowInFolder;

  /// The texts.
  final RecordingsTexts texts;

  /// Called with the take and its version when the play button is pressed.
  final void Function(Recording recording, RecordingVersion version) onPlayPressed;

  /// Called with the take, the chosen version and whether the take is loaded.
  final void Function(Recording recording, RecordingVersion version, bool isLoaded) onVersionChanged;

  /// Called with the take and its version when the share button is pressed.
  final void Function(Recording recording, RecordingVersion version) onSharePressed;

  /// Called with the take when the show-in-folder button is pressed.
  final ValueChanged<Recording> onShowInFolderPressed;

  /// Called with the take when it is to be enhanced again.
  final ValueChanged<Recording> onRetryPressed;

  /// Called with the take when the delete button is pressed.
  final ValueChanged<Recording> onDeletePressed;

  /// Creates the wrapper.
  const RecordingTileWrapper({
    required this.recording,
    required this.recordingVersionsController,
    required this.canShowInFolder,
    required this.texts,
    required this.onPlayPressed,
    required this.onVersionChanged,
    required this.onSharePressed,
    required this.onShowInFolderPressed,
    required this.onRetryPressed,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLoaded = watchPropertyValue(_isLoadedOf, target: watchPlaybackUseCase());
    final bool isPlaying = watchPropertyValue(_isPlayingOf, target: watchPlaybackUseCase());
    final RecordingVersion version = watchPropertyValue(
      _versionOf,
      target: recordingVersionsController.versionsController,
    );
    final bool isSharing = watchPropertyValue(_isSharingOf, target: recordingVersionsController.sharingController);
    return RecordingTileWidget(
      recording: recording,
      version: version,
      isLoaded: isLoaded,
      isPlaying: isPlaying,
      isSharing: isSharing,
      texts: texts,
      enhanceProgress: EnhanceProgressWrapper(recordingId: recording.id),
      playbackProgress: isLoaded ? const PlaybackProgressWrapper() : null,
      onVersionChanged: (RecordingVersion chosen) => onVersionChanged(recording, chosen, isLoaded),
      onPlayPressed: () => onPlayPressed(recording, version),
      onSharePressed: () => onSharePressed(recording, version),
      onShowInFolderPressed: canShowInFolder ? () => onShowInFolderPressed(recording) : null,
      onRetryPressed: () => onRetryPressed(recording),
      onDeletePressed: () => onDeletePressed(recording),
    );
  }

  bool _isLoadedOf(ValueListenable<PlaybackState> playback) => playback.value.recordingId == recording.id;

  bool _isPlayingOf(ValueListenable<PlaybackState> playback) =>
      playback.value.recordingId == recording.id && playback.value.isPlaying;

  RecordingVersion _versionOf(ValueListenable<ChosenVersions> versions) => versions.value.of(recording.id);

  bool _isSharingOf(ValueListenable<Set<String>> sharing) => sharing.value.contains(recording.id);
}
