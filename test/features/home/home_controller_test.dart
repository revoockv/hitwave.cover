import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/home/presentation/controllers/home_controller.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_entry_filter.dart';

void main() {
  test('starts on the home tab with every cover, then switches tabs', () {
    final HomeController homeController = HomeController();
    addTearDown(homeController.dispose);
    expect(homeController.homeTabController.value, HomeTab.home);
    expect(homeController.coverFilterController.value, PracticeEntryFilter.all);

    homeController.selectTab(HomeTab.covers);

    expect(homeController.homeTabController.value, HomeTab.covers);
  });
}
