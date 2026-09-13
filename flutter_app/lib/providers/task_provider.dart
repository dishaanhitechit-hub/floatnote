import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class TaskProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final _notif = NotificationService.instance;
  final _local = LocalDb.instance;
  List<Task> _tasks = [];
  bool loading = false;

  TaskProvider(this._settings);

  List<Task> get tasks => _tasks;

  void clear() { _tasks = []; notifyListeners(); }

  // ── Load: local first, then sync with cloud ────────────────────────────────

  Future<void> loadTasks() async {
    loading = true;
    notifyListeners();
    // Show local data immediately (works offline)
    _tasks = await _local.getTasks();
    loading = false;
    notifyListeners();
    // Background sync if online
    _syncInBackground();
  }

  void _syncInBackground() {
    final api = _settings.cloudApi;
    if (api == null) return;
    SyncService.instance.sync(api).then((_) async {
      _tasks = await _local.getTasks();
      notifyListeners();
    });
  }

  // ── Add ────────────────────────────────────────────────────────────────────

  Future<void> addTask(Map<String, dynamic> data) async {
    final task = await _local.insertTask(data);
    _tasks.insert(0, task);
    notifyListeners();
    _syncInBackground();
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    final row = task.toDbRow()..['synced'] = 0;
    await _local.updateTask(task.id, row);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) { _tasks[idx] = task; notifyListeners(); }
    _syncInBackground();
  }

  Future<void> updatePosition(Task task, double x, double y) async {
    task.posX = x;
    task.posY = y;
    notifyListeners();
    await _local.updateTask(task.id, {'pos_x': x, 'pos_y': y, 'synced': 0});
    _syncInBackground();
  }

  Future<void> toggleDone(Task task) async {
    task.isDone = !task.isDone;
    notifyListeners();
    await _local.updateTask(task.id, {'is_done': task.isDone ? 1 : 0, 'synced': 0});
    _syncInBackground();
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteTask(Task task) async {
    await _notif.cancelTaskReminder(task.id);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
    // Soft delete — sync will send DELETE to server then hard delete
    await _local.softDeleteTask(task.id);
    _syncInBackground();
  }

  // ── Reminder ───────────────────────────────────────────────────────────────

  Future<void> setReminder(Task task, DateTime dt) async {
    task.reminderTime = dt;
    notifyListeners();
    await _local.updateTask(task.id, {
      'reminder_time': dt.toIso8601String(),
      'synced': 0,
    });
    // Also push to server if online
    final api = _settings.cloudApi;
    if (api != null && task.serverId != null) {
      try { await api.setReminder(task.serverId!, dt); } catch (_) {}
    }
    await _notif.scheduleTaskReminder(
      taskId:      task.id,
      title:       task.title,
      body:        task.body,
      scheduledAt: dt,
      noteColor:   task.color,
    );
  }
}
