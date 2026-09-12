import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final _api    = ApiService();
  final _notif  = NotificationService.instance;
  List<Task> _tasks = [];
  bool loading = false;

  List<Task> get tasks => _tasks;

  Future<void> loadTasks() async {
    loading = true;
    notifyListeners();
    try {
      _tasks = await _api.fetchTasks();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Map<String, dynamic> data) async {
    final t = await _api.createTask(data);
    _tasks.insert(0, t);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _api.updateTask(task.id, task.toJson());
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
    await _api.updateTask(task.id, {'pos_x': x, 'pos_y': y});
  }

  Future<void> toggleDone(Task task) async {
    task.isDone = !task.isDone;
    notifyListeners();
    await _api.updateTask(task.id, {'is_done': task.isDone});
  }

  Future<void> deleteTask(Task task) async {
    await _notif.cancelTaskReminder(task.id);
    await _api.deleteTask(task.id);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
  }

  Future<void> setReminder(Task task, DateTime dt) async {
    await _api.setReminder(task.id, dt);
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
