import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class EventProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final _notif = NotificationService.instance;
  final _local = LocalDb.instance;
  List<FNEvent> _events = [];
  bool loading = false;

  EventProvider(this._settings);

  List<FNEvent> get events => _events;

  void clear() { _events = []; notifyListeners(); }

  List<FNEvent> eventsForDay(DateTime day) => _events.where((e) {
        final s = e.startTime;
        return s.year == day.year && s.month == day.month && s.day == day.day;
      }).toList();

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadEvents() async {
    loading = true;
    notifyListeners();
    _events = await _local.getEvents();
    loading = false;
    notifyListeners();
    _syncInBackground();
  }

  void _syncInBackground() {
    final api = _settings.cloudApi;
    if (api == null) return;
    SyncService.instance.sync(api).then((_) async {
      _events = await _local.getEvents();
      notifyListeners();
    });
  }

  // ── Add ────────────────────────────────────────────────────────────────────

  Future<void> addEvent(Map<String, dynamic> data) async {
    final event = await _local.insertEvent(data);
    _events.add(event);
    notifyListeners();
    _syncInBackground();

    final fireAt = event.startTime.subtract(
        Duration(minutes: event.reminderOffsetMin));
    await _notif.scheduleEventReminder(
      eventId:     event.id,
      title:       event.title,
      description: event.description,
      scheduledAt: fireAt,
      eventColor:  event.color,
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteEvent(FNEvent event) async {
    await _notif.cancelEventReminder(event.id);
    _events.removeWhere((e) => e.id == event.id);
    notifyListeners();
    await _local.softDeleteEvent(event.id);
    _syncInBackground();
  }
}
