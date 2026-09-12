import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class EventProvider extends ChangeNotifier {
  final _api   = ApiService();
  final _notif = NotificationService.instance;
  List<FNEvent> _events = [];
  bool loading = false;

  List<FNEvent> get events => _events;

  List<FNEvent> eventsForDay(DateTime day) => _events.where((e) {
        final s = e.startTime;
        return s.year == day.year &&
            s.month == day.month &&
            s.day == day.day;
      }).toList();

  Future<void> loadEvents() async {
    loading = true;
    notifyListeners();
    try {
      _events = await _api.fetchEvents();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent(Map<String, dynamic> data) async {
    final e = await _api.createEvent(data);
    _events.add(e);
    notifyListeners();

    final fireAt = e.startTime
        .subtract(Duration(minutes: e.reminderOffsetMin));
    await _notif.scheduleEventReminder(
      eventId:     e.id,
      title:       e.title,
      description: e.description,
      scheduledAt: fireAt,
      eventColor:  e.color,
    );
  }

  Future<void> deleteEvent(FNEvent event) async {
    await _notif.cancelEventReminder(event.id);
    await _api.deleteEvent(event.id);
    _events.removeWhere((e) => e.id == event.id);
    notifyListeners();
  }
}
