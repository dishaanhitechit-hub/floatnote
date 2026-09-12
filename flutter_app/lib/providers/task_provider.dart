import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class TaskProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final _notif = NotificationService.instance;
  List<Task> _tasks = [];
  bool loading = false;

  TaskProvider(this._settings);

  List<Task> get tasks => _tasks;

  ApiService get _primary => _settings.primaryApi;
  List<ApiService> get _all => _settings.activeApis;

  Future<void> loadTasks() async {
    loading = true;
    notifyListeners();
    try {
      _tasks = await _primary.fetchTasks();
    } catch (_) {
      // try cloud fallback if local failed
      final cloud = _settings.cloudApi;
      if (cloud != null && _settings.dbMode != DbMode.cloud) {
        try { _tasks = await cloud.fetchTasks(); } catch (_) {}
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Map<String, dynamic> data) async {
    Task? created;
    for (final api in _all) {
      try {
        final t = await api.createTask(data);
        created ??= t;
      } catch (_) {}
    }
    if (created != null) {
      _tasks.insert(0, created);
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    for (final api in _all) {
      try { await api.updateTask(task.id, task.toJson()); } catch (_) {}
    }
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task;
      notifyListeners();
    }
  }

  Future<void> updatePosition(Task task, double x, double y) async {
    task.posX = x;
    task.posY = y;
    notifyListeners();
    for (final api in _all) {
      try { await api.updateTask(task.id, {'pos_x': x, 'pos_y': y}); } catch (_) {}
    }
  }

  Future<void> toggleDone(Task task) async {
    task.isDone = !task.isDone;
    notifyListeners();
    for (final api in _all) {
      try { await api.updateTask(task.id, {'is_done': task.isDone}); } catch (_) {}
    }
  }

  Future<void> deleteTask(Task task) async {
    await _notif.cancelTaskReminder(task.id);
    for (final api in _all) {
      try { await api.deleteTask(task.id); } catch (_) {}
    }
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
  }

  Future<void> setReminder(Task task, DateTime dt) async {
    for (final api in _all) {
      try { await api.setReminder(task.id, dt); } catch (_) {}
    }
    task.reminderTime = dt;
    notifyListeners();

    await _notif.scheduleTaskReminder(
      taskId:      task.id,
      title:       task.title,
      body:        task.body,
      scheduledAt: dt,
      noteColor:   task.color,
    );
  }
}
