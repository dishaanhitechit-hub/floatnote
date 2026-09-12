import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class EventProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final _notif = NotificationService.instance;
  List<FNEvent> _events = [];
  bool loading = false;

  EventProvider(this._settings);

  List<FNEvent> get events => _events;

  ApiService get _primary => _settings.primaryApi;
  List<ApiService> get _all => _settings.activeApis;

  List<FNEvent> eventsForDay(DateTime day) => _events.where((e) {
        final s = e.startTime;
        return s.year == day.year && s.month == day.month && s.day == day.day;
      }).toList();

  Future<void> loadEvents() async {
    loading = true;
    notifyListeners();
    try {
      _events = await _primary.fetchEvents();
    } catch (_) {
      final cloud = _settings.cloudApi;
      if (cloud != null && _settings.dbMode != DbMode.cloud) {
        try { _events = await cloud.fetchEvents(); } catch (_) {}
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent(Map<String, dynamic> data) async {
    FNEvent? created;
    for (final api in _all) {
      try {
        final e = await api.createEvent(data);
        created ??= e;
      } catch (_) {}
    }
    if (created == null) return;

    _events.add(created);
    notifyListeners();

    final fireAt = created.startTime.subtract(
        Duration(minutes: created.reminderOffsetMin));
    await _notif.scheduleEventReminder(
      eventId:     created.id,
      title:       created.title,
      description: created.description,
      scheduledAt: fireAt,
      eventColor:  created.color,
    );
  }

  Future<void> deleteEvent(FNEvent event) async {
    await _notif.cancelEventReminder(event.id);
    for (final api in _all) {
      try { await api.deleteEvent(event.id); } catch (_) {}
    }
    _events.removeWhere((e) => e.id == event.id);
    notifyListeners();
  }
}
