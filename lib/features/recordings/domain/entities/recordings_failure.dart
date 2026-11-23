/// What can go wrong with the recordings; the presentation layer turns it into text.
enum RecordingsFailure {
  /// A take could not be played.
  play,

  /// A take could not be shared.
  share,

  /// The folder of a take could not be opened.
  showInFolder,

  /// The file of a take is gone.
  fileMissing,

  /// A take is already being recorded.
  busy,

  /// No take is being recorded.
  notRecording,

  /// The app may not use the microphone.
  microphonePermission,

  /// Recording could not start.
  start,

  /// The microphones could not be listed.
  listMicrophones,

  /// The take could not be saved.
  save,

  /// The take does not exist.
  notFound,

  /// The take could not be deleted.
  delete,

  /// Takes from an archive could not be added.
  importRecordings,

  /// The recording options could not be remembered.
  savePreferences,
}
