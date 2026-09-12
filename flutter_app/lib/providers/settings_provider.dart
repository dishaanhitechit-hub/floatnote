import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum DbMode { local, cloud, both }

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

  // ── Database mode ───────────────────────────────────────────────────────────

  static const _defaultLocalUrl  = 'http://10.0.2.2:5050';
  static const _defaultCloudUrl = 'http://132.154.156.82/floatnote-api';

  DbMode get dbMode {
    switch (_prefs.getString('db_mode') ?? 'cloud') {
      case 'local': return DbMode.local;
      case 'both':  return DbMode.both;
      default:      return DbMode.cloud;
    }
  }

  Future<void> setDbMode(DbMode m) async {
    await _prefs.setString('db_mode', m.name);
    notifyListeners();
  }

  String get localUrl => _prefs.getString('local_url') ?? _defaultLocalUrl;
  String get cloudUrl => _prefs.getString('cloud_url') ?? _defaultCloudUrl;

  Future<void> setLocalUrl(String url) async {
    await _prefs.setString('local_url', url.trimRight().replaceAll(RegExp(r'/$'), ''));
    notifyListeners();
  }

  Future<void> setCloudUrl(String url) async {
    await _prefs.setString('cloud_url', url.trimRight().replaceAll(RegExp(r'/$'), ''));
    notifyListeners();
  }

  // ── Active API instances ────────────────────────────────────────────────────

  ApiService get localApi => ApiService(localUrl);

  ApiService? get cloudApi => cloudUrl.isNotEmpty ? ApiService(cloudUrl) : null;

  /// Primary API for reads (local preferred, falls back to cloud).
  ApiService get primaryApi {
    switch (dbMode) {
      case DbMode.cloud: return cloudApi ?? localApi;
      default:           return localApi;
    }
  }

  /// All active APIs for fan-out writes.
  List<ApiService> get activeApis {
    switch (dbMode) {
      case DbMode.local: return [localApi];
      case DbMode.cloud: return [cloudApi ?? localApi];
      case DbMode.both:
        final c = cloudApi;
        return c != null ? [localApi, c] : [localApi];
    }
  }
}
