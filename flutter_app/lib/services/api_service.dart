import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/event.dart';
import '../models/summary.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Future<List<Task>> fetchTasks() async {
    final res = await http.get(Uri.parse('$baseUrl/api/tasks/')).timeout(const Duration(seconds: 8));
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => Task.fromJson(j)).toList();
  }

  Future<Task> createTask(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/tasks/'),
      headers: _json,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 8));
    _check(res);
    return Task.fromJson(jsonDecode(res.body));
  }

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/tasks/$id'),
      headers: _json,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 8));
    _check(res);
    return Task.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteTask(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/tasks/$id'))
        .timeout(const Duration(seconds: 8));
    _check(res);
  }

  Future<void> setReminder(int id, DateTime dt) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/tasks/$id/remind'),
      headers: _json,
      body: jsonEncode({'reminder_time': dt.toIso8601String()}),
    ).timeout(const Duration(seconds: 8));
    _check(res);
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<List<FNEvent>> fetchEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/api/events/')).timeout(const Duration(seconds: 8));
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => FNEvent.fromJson(j)).toList();
  }

  Future<FNEvent> createEvent(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/events/'),
      headers: _json,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 8));
    _check(res);
    return FNEvent.fromJson(jsonDecode(res.body));
  }

  Future<FNEvent> updateEvent(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/events/$id'),
      headers: _json,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 8));
    _check(res);
    return FNEvent.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteEvent(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/events/$id'))
        .timeout(const Duration(seconds: 8));
    _check(res);
  }

  // ── DB Manager ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> previewRange(String from, String to) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/db/preview?from=$from&to=$to'),
    ).timeout(const Duration(seconds: 8));
    _check(res);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> clearRange(String from, String to) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/db/clear-range'),
      headers: _json,
      body: jsonEncode({'from': from, 'to': to}),
    ).timeout(const Duration(seconds: 8));
    _check(res);
    return jsonDecode(res.body);
  }

  Future<List<Summary>> fetchSummaries() async {
    final res = await http.get(Uri.parse('$baseUrl/api/db/summaries'))
        .timeout(const Duration(seconds: 8));
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
      Uri.parse('$baseUrl/api/stopwatch/'),
      headers: _json,
      body: jsonEncode({
        'duration_seconds': durationSeconds,
        'laps': laps,
        'label': label,
      }),
    ).timeout(const Duration(seconds: 8));
    _check(res);
  }

  // ── Search ──────────────────────────────────────────────────────────────────

  Future<List<Task>> searchTasks({String q = '', String tag = ''}) async {
    final params = <String, String>{};
    if (q.isNotEmpty) params['q'] = q;
    if (tag.isNotEmpty) params['tag'] = tag;
    final uri = Uri.parse('$baseUrl/api/tasks/search')
        .replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    _check(res);
    return (jsonDecode(res.body) as List).map((j) => Task.fromJson(j)).toList();
  }

  // ── Health check ────────────────────────────────────────────────────────────

  Future<bool> ping() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _json = {'Content-Type': 'application/json'};

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }
}
