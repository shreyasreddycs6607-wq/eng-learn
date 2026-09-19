import 'package:flutter/foundation.dart';
import '../data/repositories/progress_repository.dart';
import '../models/reminder_setting.dart';

/// The platform side of the daily reminder — a thin seam (like AudioBackend and
/// SpeechBackend) so ReminderService is tested against a fake, never the plugin.
abstract interface class ReminderBackend {
  /// Asks the OS for permission to show notifications. Only ever called when the
  /// learner turns the reminder on. Returns whether notifications are allowed.
  Future<bool> requestPermission();

  /// Schedules (replacing any earlier one) a notification every day at [hour]:[minute] local time.
  Future<void> scheduleDaily({required int hour, required int minute});

  Future<void> cancel();
}

/// Opt-in daily "time to practise" reminder. Entirely local: a scheduled OS
/// notification, no network, no account. The choice is saved in the local
/// database so it survives restarts, and is re-applied at every app start.
class ReminderService {
  final ReminderBackend _backend;
  final ProgressRepository _repository;

  ReminderService(this._backend, this._repository);

  Future<ReminderSetting> current() => _repository.loadReminder();

  /// Turns the reminder on at [minutesOfDay] (minutes after midnight). Returns
  /// false — and leaves the reminder off — if the learner refuses the
  /// notification permission.
  Future<bool> enable(int minutesOfDay) async {
    if (!await _backend.requestPermission()) return false;
    final setting = ReminderSetting(enabled: true, minutesOfDay: minutesOfDay);
    await _backend.scheduleDaily(hour: setting.hour, minute: setting.minute);
    await _repository.saveReminder(setting);
    return true;
  }

  Future<void> disable() async {
    await _backend.cancel();
    final setting = await _repository.loadReminder();
    await _repository.saveReminder(setting.copyWith(enabled: false));
  }

  /// Changes the time of a reminder that is already on (no new permission prompt needed).
  Future<void> changeTime(int minutesOfDay) async {
    final setting = await _repository.loadReminder();
    if (!setting.enabled) {
      await _repository.saveReminder(setting.copyWith(minutesOfDay: minutesOfDay));
      return;
    }
    await enable(minutesOfDay);
  }

  /// Re-applies a saved reminder at app start, so a changed time zone or a
  /// cleared alarm never silently ends the reminders. Never throws: a
  /// notification problem must not stop the app from opening.
  Future<void> restore() async {
    try {
      final setting = await _repository.loadReminder();
      if (setting.enabled) await _backend.scheduleDaily(hour: setting.hour, minute: setting.minute);
    } catch (e) {
      if (kDebugMode) debugPrint('[REMINDER] Could not restore the daily reminder: $e');
    }
  }
}
