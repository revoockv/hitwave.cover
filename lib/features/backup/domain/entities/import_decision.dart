import 'import_choice.dart';
import 'import_conflict.dart';

/// What to do with one song of a backup that is already in the library.
final class ImportDecision {
  /// Position of the song in the backup ([ImportConflict.index]).
  final int index;

  /// What to do with it.
  final ImportChoice choice;

  /// Creates an [ImportDecision].
  const ImportDecision({required this.index, required this.choice});

  /// The [choice] for [conflict].
  ImportDecision.forConflict(ImportConflict conflict, this.choice) : index = conflict.index;
}
