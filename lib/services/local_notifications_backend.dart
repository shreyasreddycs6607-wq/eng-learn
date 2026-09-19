import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_service.dart';

/// The real reminder backend: a daily local notification via
/// flutter_local_notifications. Works offline — the phone's own alarm shows it.
class LocalNotificationsBackend implements ReminderBackend {
  static const _notificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    // Daily reminders must follow the phone's local time (including daylight saving).
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await _init();
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _notificationId, // one fixed id: scheduling again replaces, never duplicates
      title: 'English ಕಲಿಯೋಣ',
      body: 'ಇಂದಿನ ಅಭ್ಯಾಸ ಸಿದ್ಧವಾಗಿದೆ. Time for today’s practice!',
      scheduledDate: first,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A gentle daily reminder to practise English',
        ),
      ),
      // Inexact: needs no special "exact alarm" permission; may arrive a little late.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat every day at this time
    );
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _notificationId);
  }
}
