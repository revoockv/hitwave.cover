import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

import '../../../practice/domain/entities/practice_entry_filter.dart';

/// Tabs of the bottom navigation of the home page.
enum HomeTab {
  /// Overview: mini statistics, the songs opened and the covers played last.
  home,

  /// The songs.
  songs,

  /// Every recorded cover.
  covers,

  /// The practice statistics.
  stats,

  /// The tuner of the instrument.
  tuner,
}

/// UI state of the home page: the tab shown and the search and the filter of the covers tab.
///
/// A Flutter-style controller: the page watches its notifiers and text controllers.
final class HomeController {
  /// The tab shown.
  final ValueNotifier<HomeTab> homeTabController = ValueNotifier<HomeTab>(HomeTab.home);

  /// Search text of the covers tab.
  final TextEditingController coverSearchController = TextEditingController();

  /// Which practice items the covers tab shows.
  final ValueNotifier<PracticeEntryFilter> coverFilterController = ValueNotifier<PracticeEntryFilter>(
    PracticeEntryFilter.all,
  );

  /// Shows [tab].
  void selectTab(HomeTab tab) {
    homeTabController.value = tab;
  }

  /// Disposes the notifiers and text controllers.
  void dispose() {
    homeTabController.dispose();
    coverSearchController.dispose();
    coverFilterController.dispose();
  }
}
