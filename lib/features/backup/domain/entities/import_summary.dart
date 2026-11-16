/// What an import did.
final class ImportSummary {
  /// Songs added (new ones and the ones kept next to a song with the same name).
  final int added;

  /// Songs of the library that got the lyrics of the backup.
  final int replaced;

  /// Songs of the backup that were not imported.
  final int skipped;

  /// Creates an [ImportSummary].
  const ImportSummary({required this.added, required this.replaced, required this.skipped});
}
