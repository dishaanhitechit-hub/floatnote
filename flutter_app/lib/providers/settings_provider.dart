import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs);

  // ── Theme ───────────────────────────────────────────────────────────────────

  ThemeMode get themeMode {
    final v = _prefs.getString('theme_mode') ?? 'system';
    switch (v) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode m) async {
    String v;
    switch (m) {
      case ThemeMode.light: v = 'light'; break;
      case ThemeMode.dark:  v = 'dark';  break;
      default:              v = 'system';
    }
    await _prefs.setString('theme_mode', v);
    notifyListeners();
  }

  // ── Stopwatch sound ─────────────────────────────────────────────────────────

  bool get stopwatchSound => _prefs.getBool('stopwatch_sound') ?? true;

  Future<void> toggleStopwatchSound() async {
    await _prefs.setBool('stopwatch_sound', !stopwatchSound);
    notifyListeners();
  }

  // ── Canvas dot grid ─────────────────────────────────────────────────────────

  bool get showDotGrid => _prefs.getBool('show_dot_grid') ?? true;

  Future<void> toggleDotGrid() async {
    await _prefs.setBool('show_dot_grid', !showDotGrid);
    notifyListeners();
  }
}
