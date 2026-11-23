import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/can_show_recording_in_folder_use_case.dart';
import '../../domain/use_cases/delete_all_recordings_use_case.dart';
import '../../domain/use_cases/delete_recording_use_case.dart';
import '../../domain/use_cases/enhance_recording_again_use_case.dart';
import '../../domain/use_cases/list_microphones_use_case.dart';
import '../../domain/use_cases/play_recording_use_case.dart';
import '../../domain/use_cases/share_recording_use_case.dart';
import '../../domain/use_cases/show_recording_in_folder_use_case.dart';
import '../../domain/use_cases/start_recording_use_case.dart';
import '../../domain/use_cases/stop_playback_use_case.dart';
import '../../domain/use_cases/stop_recording_use_case.dart';
import '../../domain/use_cases/toggle_playback_pause_use_case.dart';
import '../../domain/use_cases/update_recording_preferences_use_case.dart';
import '../../domain/use_cases/watch_playback_use_case.dart';
import '../../domain/use_cases/watch_enhancing_recording_use_case.dart';
import '../../domain/use_cases/watch_recorder_use_case.dart';
import '../../domain/use_cases/watch_recording_preferences_use_case.dart';
import '../../domain/use_cases/watch_recordings_use_case.dart';

/// The use case that starts recording a take.
StartRecordingUseCase get startRecordingUseCase => di<StartRecordingUseCase>();

/// The use case that stops the take, keeps it and enhances it.
StopRecordingUseCase get stopRecordingUseCase => di<StopRecordingUseCase>();

/// The use case that enhances a recording again after a failure.
EnhanceRecordingAgainUseCase get enhanceRecordingAgainUseCase => di<EnhanceRecordingAgainUseCase>();

/// The use case that deletes a recording.
DeleteRecordingUseCase get deleteRecordingUseCase => di<DeleteRecordingUseCase>();

/// The use case that watches every recording; call it to get the [ValueListenable].
WatchRecordingsUseCase get watchRecordingsUseCase => di<WatchRecordingsUseCase>();

/// The use case that watches the recorder; call it to get the [ValueListenable].
WatchRecorderUseCase get watchRecorderUseCase => di<WatchRecorderUseCase>();

/// The use case that tells which take the audio engine is enhancing now.
WatchEnhancingRecordingUseCase get watchEnhancingRecordingUseCase => di<WatchEnhancingRecordingUseCase>();

/// The use case that plays a recording.
PlayRecordingUseCase get playRecordingUseCase => di<PlayRecordingUseCase>();

/// The use case that pauses or continues playback.
TogglePlaybackPauseUseCase get togglePlaybackPauseUseCase => di<TogglePlaybackPauseUseCase>();

/// The use case that stops playback.
StopPlaybackUseCase get stopPlaybackUseCase => di<StopPlaybackUseCase>();

/// The use case that watches the player; call it to get the [ValueListenable].
WatchPlaybackUseCase get watchPlaybackUseCase => di<WatchPlaybackUseCase>();

/// The use case that watches the remembered recording options; call it to get the [ValueListenable].
WatchRecordingPreferencesUseCase get watchRecordingPreferencesUseCase => di<WatchRecordingPreferencesUseCase>();

/// The use case that remembers the recording options.
UpdateRecordingPreferencesUseCase get updateRecordingPreferencesUseCase => di<UpdateRecordingPreferencesUseCase>();

/// The use case that sends a recording through the share sheet.
ShareRecordingUseCase get shareRecordingUseCase => di<ShareRecordingUseCase>();

/// The use case that opens the folder of a recording.
ShowRecordingInFolderUseCase get showRecordingInFolderUseCase => di<ShowRecordingInFolderUseCase>();

/// The use case that tells whether the folder of a recording can be opened here.
CanShowRecordingInFolderUseCase get canShowRecordingInFolderUseCase => di<CanShowRecordingInFolderUseCase>();

/// The use case that lists the sound inputs of the device.
ListMicrophonesUseCase get listMicrophonesUseCase => di<ListMicrophonesUseCase>();

/// The use case that deletes every take of every song.
DeleteAllRecordingsUseCase get deleteAllRecordingsUseCase => di<DeleteAllRecordingsUseCase>();
