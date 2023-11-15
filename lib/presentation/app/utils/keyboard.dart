import 'package:flutter/widgets.dart';

class Keyboard {
  static bool isVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0.0;
  }

  static void unfocus(BuildContext context) {
    final currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
