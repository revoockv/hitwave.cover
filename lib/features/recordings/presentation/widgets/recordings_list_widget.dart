import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../../vocal_enhance/domain/entities/enhance_progress.dart';
import '../../../vocal_enhance/presentation/di/vocal_enhance_getters.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/entities/shared_song.dart';
import '../controllers/recording_versions_controller.dart';
import '../di/recordings_getters.dart';
import 'delete_recording_dialog_widget.dart';
import 'recording_tile_widget.dart';

/// List of recordings: listen to the original or the enhanced take, delete it, enhance it again
/// after a failure. Calls the recordings use cases.
///
/// With [headerOf], a header (the song) is shown above every run of recordings with the same one.
final class RecordingsListWidget extends WatchingWidget {
  /// The recordings, in the order to show.
  final List<Recording> recordings;

  /// Header of a recording, or `null` for none.
  final String? Function(Recording recording)? headerOf;

  /// The song a shared recording is named after, or `null` when unknown.
  final SharedSong? Function(Recording recording)? songOf;

  /// Shown when there are no recordings.
  final String emptyText;

  /// Padding of the list.
  final EdgeInsets padding;

  /// Whether the list takes only the height of its tiles (inside another scrolling list).
  final bool shrinkWrap;

  /// Creates a new [RecordingsListWidget].
  const RecordingsListWidget({
    super.key,
    required this.recordings,
    required this.emptyText,
    this.headerOf,
    this.songOf,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final RecordingVersionsController recordingVersionsController = createOnce(
      _createRecordingVersionsController,
      dispose: _disposeRecordingVersionsController,
    );
    watch(recordingVersionsController.versionsController);
    final PlaybackState playback = watch(watchPlaybackUseCase()).value;
    final EnhanceProgress? progress = watch(watchEnhanceProgressUseCase()).value;
    final bool trimSilence = watch(watchRecordingPreferencesUseCase()).value.trimSilence;
    final String? firstEnhancing = _firstEnhancing(recordings);
    final bool canShowInFolder = canShowRecordingInFolderUseCase();
    final ThemeData theme = Theme.of(context);

    if (recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: padding,
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      itemCount: recordings.length,
      itemBuilder: (BuildContext context, int index) {
        final Recording recording = recordings[index];
        final bool isLoaded = playback.recordingId == recording.id;
        final RecordingVersion version = recordingVersionsController.versionOf(recording.id);
        final String? header = headerOf?.call(recording);
        final bool showHeader = header != null && (index == 0 || headerOf?.call(recordings[index - 1]) != header);
        final Widget tile = RecordingTileWidget(
          key: ValueKey<String>(recording.id),
          recording: recording,
          version: version,
          isLoaded: isLoaded,
          isPlaying: isLoaded && playback.isPlaying,
          playedFraction: isLoaded ? _fraction(playback) : 0,
          enhanceFraction: recording.id == firstEnhancing ? progress?.fraction : null,
          onVersionChanged: (RecordingVersion chosen) =>
              _onVersionChanged(context, recordingVersionsController, recording, chosen, isLoaded: isLoaded),
          onPlayPressed: () => _onPlayPressed(context, recording, playback, version),
          onDeletePressed: () => _confirmDelete(context, recording, playback),
          onSharePressed: () => _share(context, recording, version),
          onShowInFolderPressed: canShowInFolder ? () => _showInFolder(context, recording) : null,
          onRetryPressed: () => _retry(context, recording, trimSilence),
        );
        if (!showHeader) return tile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : AppTheme.spacingMedium, bottom: AppTheme.spacingSmall),
              child: Text(header, style: theme.textTheme.titleMedium),
            ),
            tile,
          ],
        );
      },
    );
  }

  /// The oldest take still waiting for its enhancement: the one the engine works on.
  static String? _firstEnhancing(List<Recording> recordings) {
    for (final Recording recording in recordings.reversed) {
      if (recording.status == RecordingStatus.enhancing) return recording.id;
    }
    return null;
  }

  static double _fraction(PlaybackState playback) {
    final int total = playback.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (playback.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Future<void> _onPlayPressed(
    BuildContext context,
    Recording recording,
    PlaybackState playback,
    RecordingVersion version,
  ) async {
    if (playback.recordingId == recording.id) {
      final Result<void> result = await togglePlaybackPauseUseCase();
      if (!context.mounted) return;
      _showFailure(context, result);
      return;
    }
    await _play(context, recording, version);
  }

  static RecordingVersionsController _createRecordingVersionsController() => RecordingVersionsController();

  static void _disposeRecordingVersionsController(RecordingVersionsController recordingVersionsController) =>
      recordingVersionsController.dispose();

  /// Chooses [version] on this card only; the card playing now goes on with the chosen version.
  Future<void> _onVersionChanged(
    BuildContext context,
    RecordingVersionsController recordingVersionsController,
    Recording recording,
    RecordingVersion version, {
    required bool isLoaded,
  }) async {
    recordingVersionsController.choose(recording.id, version);
    if (isLoaded) await _play(context, recording, version);
  }

  Future<void> _play(BuildContext context, Recording recording, RecordingVersion version) async {
    final Result<void> result = await playRecordingUseCase(recording: recording, version: version);
    if (result.isSuccess) await markCoverPlayedUseCase(recording.id);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  Future<void> _share(BuildContext context, Recording recording, RecordingVersion version) async {
    final Result<void> result = await shareRecordingUseCase(
      recording: recording,
      version: version,
      song: songOf?.call(recording),
    );
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  Future<void> _showInFolder(BuildContext context, Recording recording) async {
    final Result<void> result = await showRecordingInFolderUseCase(recording);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  Future<void> _retry(BuildContext context, Recording recording, bool trimSilence) async {
    final Result<void> result = await enhanceRecordingAgainUseCase(recordingId: recording.id, trimSilence: trimSilence);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  Future<void> _confirmDelete(BuildContext context, Recording recording, PlaybackState playback) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const DeleteRecordingDialogWidget(),
    );
    if (confirmed != true) return;
    if (playback.recordingId == recording.id) await stopPlaybackUseCase();
    final Result<void> result = await deleteRecordingUseCase(recording.id);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  static void _showFailure(BuildContext context, Result<void> result) {
    if (result case FailureResult<void>(:final String error)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
