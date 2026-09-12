import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/event.dart';
import '../models/summary.dart';

class ApiService {
  // 10.0.2.2 is the Android emulator's alias for the host machine (localhost on Mac)
  static const _base = 'http://10.0.2.2:5050';

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Future<List<Task>> fetchTasks() async {
    final res = await http.get(Uri.parse('$_base/api/tasks/'));
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => Task.fromJson(j)).toList();
  }

  Future<Task> createTask(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_base/api/tasks/'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(res);
    return Task.fromJson(jsonDecode(res.body));
  }

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_base/api/tasks/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(res);
    return Task.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteTask(int id) async {
    final res = await http.delete(Uri.parse('$_base/api/tasks/$id'));
    _check(res);
  }

  Future<void> setReminder(int id, DateTime dt) async {
    final res = await http.post(
      Uri.parse('$_base/api/tasks/$id/remind'),
      headers: _json,
      body: jsonEncode({'reminder_time': dt.toIso8601String()}),
    );
    _check(res);
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<List<FNEvent>> fetchEvents() async {
    final res = await http.get(Uri.parse('$_base/api/events/'));
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => FNEvent.fromJson(j)).toList();
  }

  Future<FNEvent> createEvent(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_base/api/events/'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(res);
    return FNEvent.fromJson(jsonDecode(res.body));
  }

  Future<FNEvent> updateEvent(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_base/api/events/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(res);
    return FNEvent.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteEvent(int id) async {
    final res = await http.delete(Uri.parse('$_base/api/events/$id'));
    _check(res);
  }

  // ── DB Manager ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> previewRange(String from, String to) async {
    final res = await http.get(
      Uri.parse('$_base/api/db/preview?from=$from&to=$to'),
    );
    _check(res);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> clearRange(String from, String to) async {
    final res = await http.post(
      Uri.parse('$_base/api/db/clear-range'),
      headers: _json,
      body: jsonEncode({'from': from, 'to': to}),
    );
    _check(res);
    return jsonDecode(res.body);
  }

  Future<List<Summary>> fetchSummaries() async {
    final res = await http.get(Uri.parse('$_base/api/db/summaries'));
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => Summary.fromJson(j)).toList();
  }

  // ── Stopwatch ───────────────────────────────────────────────────────────────

  Future<void> saveStopwatchSession({
    required double durationSeconds,
    required List<double> laps,
    required String label,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/stopwatch/'),
      headers: _json,
      body: jsonEncode({
        'duration_seconds': durationSeconds,
        'laps': laps,
        'label': label,
      }),
    );
    _check(res);
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  Future<List<Task>> searchTasks({String q = '', String tag = ''}) async {
    final params = <String, String>{};
    if (q.isNotEmpty) params['q'] = q;
    if (tag.isNotEmpty) params['tag'] = tag;
    final uri = Uri.parse('$_base/api/tasks/search')
        .replace(queryParameters: params);
    final res = await http.get(uri);
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => Task.fromJson(j)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTags() async {
    final res = await http.get(Uri.parse('$_base/api/tasks/tags'));
    _check(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _json = {'Content-Type': 'application/json'};

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
