import 'package:flutter/widgets.dart' show TextEditingController;

/// UI state of the sync page: the code typed by hand.
final class SyncPageController {
  /// The code typed or pasted by hand (on a device that cannot scan).
  final TextEditingController codeController = TextEditingController();

  /// Disposes the text controller.
  void dispose() {
    codeController.dispose();
  }
}
