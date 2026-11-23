import 'package:flutter/foundation.dart' show ValueNotifier;

/// UI state of the practice page: the month shown in the calendar and the chosen day.
final class PracticePageController {
  /// First day of the month shown in the calendar.
  final ValueNotifier<DateTime> monthController;

  /// The day whose practice is shown under the calendar (midnight).
  final ValueNotifier<DateTime> selectedDayController;

  /// Creates the controller showing the month of [today] with [today] chosen.
  PracticePageController({required DateTime today})
    : monthController = ValueNotifier<DateTime>(DateTime(today.year, today.month)),
      selectedDayController = ValueNotifier<DateTime>(DateTime(today.year, today.month, today.day));

  /// Shows the month before.
  void showPreviousMonth() {
    final DateTime month = monthController.value;
    monthController.value = DateTime(month.year, month.month - 1);
  }

  /// Shows the month after.
  void showNextMonth() {
    final DateTime month = monthController.value;
    monthController.value = DateTime(month.year, month.month + 1);
  }

  /// Chooses [day].
  void selectDay(DateTime day) {
    selectedDayController.value = day;
  }

  /// Disposes the [ValueNotifier]s.
  void dispose() {
    monthController.dispose();
    selectedDayController.dispose();
  }
}
