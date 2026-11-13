/// A step of a sync; the presentation layer turns it into text.
///
/// Its [name] also goes to the other device, so each device shows the step in its own language.
enum SyncStep {
  /// This device connects to the other one.
  connecting,

  /// The songs and covers of the other device are read.
  reading,

  /// The choices about the differences are applied.
  applying,

  /// The covers this device misses are downloaded.
  downloading,

  /// The covers the other device misses are sent.
  uploading,

  /// The data of both devices is merged.
  merging,

  /// The other device connected to this one.
  joined,

  /// The user of the other device chooses what to do with the differences.
  choosing,
}
