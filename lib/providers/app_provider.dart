import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = 'Guest User';

  bool get isDarkMode => _isDarkMode;

  String get userName => _userName;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }
}
