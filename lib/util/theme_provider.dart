import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Initial theme is set to light
  bool _isDark = true;

  bool get isDark => _isDark;

  // Toggle the theme (light or dark)
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners(); // Notify listeners to rebuild the widgets that depend on this
  }
}
