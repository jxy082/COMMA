import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider with ChangeNotifier {
  double _scaleFactor = 1.0;

  double get scaleFactor => _scaleFactor;

  FontSizeProvider() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _scaleFactor = prefs.getDouble('fontSize') ?? 1.0;
    notifyListeners();
  }

  Future<void> setScaleFactor(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _scaleFactor = value;
    await prefs.setDouble('fontSize', value);
    notifyListeners();
  }
}
