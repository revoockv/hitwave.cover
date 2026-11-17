import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/entities/shared_song.dart';
import '../controllers/recording_versions_controller.dart';
import '../di/recordings_getters.dart';
import 'delete_recording_dialog_widget.dart';
import 'recording_tile_widget.dart';
import '../../domain/entities/recordings_failure.dart';
import '../l10n/recordings_texts.dart';

/// List of recordings: listen to the original or the enhanced take, delete it, enhance it again
/// after a failure. Calls the recordings use cases.
///
/// With [headerOf], a header (the song) is shown above every run of recordings with the same one.
final class RecordingsListWidget extends WatchingWidget {
  /// The recordings, in the order to show.
  final List<Recording> recordings;

  /// Header of a recording, or `null` for none.
  final String? Function(Recording recording)? headerOf;

  /// What tapping the header of a recording does (opens its song), or `null` when it does nothing.
  final VoidCallback? Function(Recording recording)? onHeaderPressedOf;

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
    this.onHeaderPressedOf,
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
    watch(recordingVersionsController.sharingController);
    // Only which take is loaded and whether it plays; the position is watched by PlaybackProgressWidget alone.
    final String? loadedId = watchPropertyValue(_loadedIdOf, target: watchPlaybackUseCase());
    final bool isPlaying = watchPropertyValue(_isPlayingOf, target: watchPlaybackUseCase());
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
        final bool isLoaded = loadedId == recording.id;
        final RecordingVersion version = recordingVersionsController.versionOf(recording.id);
        final String? header = headerOf?.call(recording);
        final bool showHeader = header != null && (index == 0 || headerOf?.call(recordings[index - 1]) != header);
        final Widget tile = RecordingTileWidget(
          key: ValueKey<String>(recording.id),
          recording: recording,
          version: version,
          isLoaded: isLoaded,
          isPlaying: isLoaded && isPlaying,
          onVersionChanged: (RecordingVersion chosen) =>
              _onVersionChanged(context, recordingVersionsController, recording, chosen, isLoaded: isLoaded),
          onPlayPressed: () => _onPlayPressed(context, recording, version),
          onDeletePressed: () => _confirmDelete(context, recording),
          onSharePressed: () => _share(context, recordingVersionsController, recording, version),
          isSharing: recordingVersionsController.isSharing(recording.id),
          onShowInFolderPressed: canShowInFolder ? () => _showInFolder(context, recording) : null,
          onRetryPressed: () => _retry(context, recording),
        );
        if (!showHeader) return tile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : AppTheme.spacingMedium, bottom: AppTheme.spacingSmall),
              child: _HeaderWidget(title: header, onPressed: onHeaderPressedOf?.call(recording)),
            ),
            tile,
          ],
        );
      },
    );
  }

  static String? _loadedIdOf(ValueListenable<PlaybackState> playback) => playback.value.recordingId;

  static bool _isPlayingOf(ValueListenable<PlaybackState> playback) => playback.value.isPlaying;

  Future<void> _onPlayPressed(BuildContext context, Recording recording, RecordingVersion version) async {
    if (watchPlaybackUseCase().value.recordingId == recording.id) {
      final Result<void, RecordingsFailure> result = await togglePlaybackPauseUseCase();
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
    final Result<void, RecordingsFailure> result = await playRecordingUseCase(recording: recording, version: version);
    if (result.isSuccess) await markCoverPlayedUseCase(recording.id);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  /// Makes the MP3 (the card shows it is busy) and opens the share sheet.
  Future<void> _share(
    BuildContext context,
    RecordingVersionsController recordingVersionsController,
    Recording recording,
    RecordingVersion version,
  ) async {
    final Translations t = context.t;
    recordingVersionsController.setSharing(recording.id, sharing: true);
    final Result<bool, RecordingsFailure> result = await shareRecordingUseCase(
      recording: recording,
      version: version,
      song: songOf?.call(recording),
    );
    if (!context.mounted) return;
    recordingVersionsController.setSharing(recording.id, sharing: false);
    switch (result) {
      case SuccessResult<bool, RecordingsFailure>(value: true):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.recordings.captionCopied)));
      case SuccessResult<bool, RecordingsFailure>():
        break;
      case FailureResult<bool, RecordingsFailure>(:final RecordingsFailure failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.text(context.t))));
    }
  }

  Future<void> _showInFolder(BuildContext context, Recording recording) async {
    final Result<void, RecordingsFailure> result = await showRecordingInFolderUseCase(recording);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  Future<void> _retry(BuildContext context, Recording recording) async {
    final Result<void, RecordingsFailure> result = await enhanceRecordingAgainUseCase(
      recordingId: recording.id,
      trimSilence: watchRecordingPreferencesUseCase().value.trimSilence,
    );
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  Future<void> _confirmDelete(BuildContext context, Recording recording) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const DeleteRecordingDialogWidget(),
    );
    if (confirmed != true) return;
    if (watchPlaybackUseCase().value.recordingId == recording.id) await stopPlaybackUseCase();
    final Result<void, RecordingsFailure> result = await deleteRecordingUseCase(recording.id);
    if (!context.mounted) return;
    _showFailure(context, result);
  }

  static void _showFailure(BuildContext context, Result<void, RecordingsFailure> result) {
    if (result case FailureResult<void, RecordingsFailure>(:final RecordingsFailure failure)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.text(context.t))));
    }
  }
}

/// The song above its recordings; with [onPressed], tapping it opens the song.
final class _HeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const _HeaderWidget({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Text text = Text(title, style: theme.textTheme.titleMedium);
    final VoidCallback? pressed = onPressed;
    if (pressed == null) return text;
    return InkWell(
      onTap: pressed,
      borderRadius: BorderRadius.circular(AppTheme.spacingSmall),
      child: Row(
        children: <Widget>[
          Flexible(child: text),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
