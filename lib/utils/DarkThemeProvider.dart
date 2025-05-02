import 'package:customer/utils/DarkThemePreference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  int _darkTheme = 0;

  int get darkTheme => _darkTheme;

  set darkTheme(int value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }

  bool getThem() {
    return false; // Siempre retorna falso para desactivar el modo oscuro
  }

  bool getSystemThem() {
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
}
