import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../practice/domain/entities/practice_entry_filter.dart';
import '../../../practice/presentation/pages/practice_timeline_page.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/widgets/search_field_widget.dart';
import '../controllers/home_controller.dart';
import '../widgets/covers_tab_widget.dart';

/// The covers tab: gives the practice timeline the search text and the filter of the page's [HomeController], so
/// typing rebuilds only this tab.
final class CoversTabWrapper extends WatchingWidget {
  /// The cover search and filter, owned by the page.
  final HomeController homeController;

  /// Called with the song of a cover whose title is tapped.
  final ValueChanged<Song> onSongPressed;

  /// Creates the wrapper.
  const CoversTabWrapper({super.key, required this.homeController, required this.onSongPressed});

  @override
  Widget build(BuildContext context) {
    final String query = watchPropertyValue(_textOf, target: homeController.coverSearchController);
    final PracticeEntryFilter filter = watch(homeController.coverFilterController).value;
    return CoversTabWidget(
      searchField: SearchFieldWidget(
        searchController: homeController.coverSearchController,
        hintText: context.t.song.coverSearch,
        clearTooltip: context.t.common.clear,
      ),
      timeline: PracticeTimelinePage(
        query: query,
        filter: filter,
        onFilterChanged: _onFilterChanged,
        onSongPressed: onSongPressed,
      ),
    );
  }

  static String _textOf(TextEditingController searchController) => searchController.text;

  void _onFilterChanged(PracticeEntryFilter filter) {
    homeController.coverFilterController.value = filter;
  }
}
