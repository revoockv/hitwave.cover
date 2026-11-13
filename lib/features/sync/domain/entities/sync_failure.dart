/// What can go wrong with syncing; the presentation layer turns it into text.
///
/// Its [name] also goes to the other device when this one stops, so each device shows the
/// reason in its own language.
enum SyncFailure {
  /// The code field is empty.
  emptyCode,

  /// The text is not a sync code of the app.
  notACode,

  /// This device is not in a network.
  noNetwork,

  /// This device could not start waiting for the other one.
  host,

  /// A sync already runs.
  busy,

  /// No sync waits for the choices about the differences.
  nothingWaits,

  /// The other device could not be reached.
  connect,

  /// The sync broke off.
  interrupted,

  /// The user cancelled the sync.
  cancelled,

  /// The other device stopped the sync.
  peerStopped,
}
