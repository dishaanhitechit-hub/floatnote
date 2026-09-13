import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ── Bootstrap ───────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: _onTap);

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  // ── Task reminder ───────────────────────────────────────────────────────────

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String noteColor,
  }) async {
    if (!_ready || scheduledAt.isBefore(DateTime.now())) return;
    if (!kIsWeb && Platform.isWindows) {
      // Windows scheduled toasts require MSIX packaging; use in-process timer instead
      final delay = scheduledAt.difference(DateTime.now());
      Future.delayed(delay, () => showNow(
        id: _taskNotifId(taskId),
        title: '📌  $title',
        body: body.isEmpty ? 'Tap to view your sticky note.' : body,
      ));
      return;
    }
    await _plugin.zonedSchedule(
      _taskNotifId(taskId),
      '📌  $title',
      body.isEmpty ? 'Tap to view your sticky note.' : body,
      _toTZ(scheduledAt),
      _details(noteColor),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('[Notif] task $taskId scheduled for $scheduledAt');
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _plugin.cancel(_taskNotifId(taskId));
  }

  // ── Event reminder ──────────────────────────────────────────────────────────

  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    required String description,
    required DateTime scheduledAt,
    required String eventColor,
  }) async {
    if (!_ready || scheduledAt.isBefore(DateTime.now())) return;
    if (!kIsWeb && Platform.isWindows) {
      final delay = scheduledAt.difference(DateTime.now());
      Future.delayed(delay, () => showNow(
        id: _eventNotifId(eventId),
        title: '📅  $title',
        body: description.isEmpty ? 'Event starting soon.' : description,
      ));
      return;
    }
    await _plugin.zonedSchedule(
      _eventNotifId(eventId),
      '📅  $title',
      description.isEmpty ? 'Event starting soon.' : description,
      _toTZ(scheduledAt),
      _details(eventColor),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('[Notif] event $eventId scheduled for $scheduledAt');
  }

  Future<void> cancelEventReminder(int eventId) async {
    await _plugin.cancel(_eventNotifId(eventId));
  }

  // ── Immediate notification ──────────────────────────────────────────────────

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(id, title, body, _details(null));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _taskNotifId(int id)  => 1000 + (id % 1000);
  int _eventNotifId(int id) => 2000 + (id % 1000);

  tz.TZDateTime _toTZ(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }

  NotificationDetails _details(String? colorHex) {
    Color? androidColor;
    if (colorHex != null) {
      try {
        androidColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'floatnote_channel',
        'FloatNote Reminders',
        channelDescription: 'Task and event reminders',
        importance: Importance.high,
        priority: Priority.high,
        color: androidColor,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  void _onTap(NotificationResponse r) {
    debugPrint('[Notif tapped] payload=${r.payload}');
  }
}
