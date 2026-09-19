import 'package:english_kaliyona/services/reminder_service.dart';

/// A controllable stand-in for the notification plugin, so ReminderService and
/// the screen that drives it are tested without a phone or a real notification.
class FakeReminderBackend implements ReminderBackend {
  bool permissionGranted = true;
  bool failToSchedule = false;

  int permissionRequests = 0;
  int cancelCalls = 0;

  /// Every scheduleDaily call, as minutes after midnight, in order.
  final List<int> scheduled = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (failToSchedule) throw Exception('simulated scheduling failure');
    scheduled.add(hour * 60 + minute);
  }

  @override
  Future<void> cancel() async => cancelCalls++;
}
