import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/entities/recordings_failure.dart';
import '../../domain/entities/shared_song.dart';
import '../controllers/recording_versions_controller.dart';
import '../di/recordings_getters.dart';
import '../l10n/recordings_texts.dart';
import '../widgets/delete_recording_dialog_widget.dart';
import '../widgets/recordings_list_widget.dart';
import '../wrappers/recording_tile_wrapper.dart';
import '../widgets/recording_tile_widget.dart';

/// Takes to listen to (the original or the enhanced one), share, show in their folder, enhance again and delete —
/// a page that other screens place into theirs (the lyrics' sheet, the practice timeline, the home dashboard).
///
/// Owns the chosen versions, starts every action and shows its failures; never rebuilds — a wrapper per take selects
/// what that take shows.
final class RecordingsListPage extends WatchingWidget {
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

  /// Creates a new [RecordingsListPage].
  const RecordingsListPage({
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
    final bool canShowInFolder = canShowRecordingInFolderUseCase();
    final RecordingsTexts texts = context.t.recordingsTexts;
    return RecordingsListWidget(
      recordings: recordings,
      emptyText: emptyText,
      headerOf: headerOf,
      onHeaderPressedOf: onHeaderPressedOf,
      padding: padding,
      shrinkWrap: shrinkWrap,
      tileBuilder: (Recording recording) => RecordingTileWrapper(
        key: ValueKey<String>(recording.id),
        recording: recording,
        recordingVersionsController: recordingVersionsController,
        canShowInFolder: canShowInFolder,
        texts: texts,
        onPlayPressed: (Recording recording, RecordingVersion version) => _onPlayPressed(context, recording, version),
        onVersionChanged: (Recording recording, RecordingVersion version, bool isLoaded) =>
            _onVersionChanged(context, recordingVersionsController, recording, version, isLoaded: isLoaded),
        onSharePressed: (Recording recording, RecordingVersion version) =>
            _share(context, recordingVersionsController, recording, version),
        onShowInFolderPressed: (Recording recording) => _showInFolder(context, recording),
        onRetryPressed: (Recording recording) => _retry(context, recording),
        onDeletePressed: (Recording recording) => _confirmDelete(context, recording),
      ),
    );
  }

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
      builder: (BuildContext context) => DeleteRecordingDialogWidget(texts: context.t.recordingsTexts),
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
