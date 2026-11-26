import '../entities/tab_block.dart';

/// Finds the tablatures in lyrics being edited, so the page keeps them in a fixed-width font.
///
/// The tabs of a saved song are `Song.tabs`; the rules of a tab line are in [TabBlock].
final class FindTabBlocksUseCase {
  /// Creates a new [FindTabBlocksUseCase] use case.
  const FindTabBlocksUseCase();

  /// The tab blocks of [lyrics] in order; empty when the lyrics have none.
  List<TabBlock> call(String lyrics) => TabBlock.findAll(lyrics);
}
