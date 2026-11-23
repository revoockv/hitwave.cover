import 'import_conflict.dart';

/// An opened backup waiting to be imported: how many songs it has and which of them are already
/// in the library.
final class ImportPlan {
  /// Number of songs in the backup.
  final int songCount;

  /// The songs already in the library, in the order of the backup.
  final List<ImportConflict> conflicts;

  /// Creates an [ImportPlan].
  const ImportPlan({required this.songCount, required this.conflicts});
}
