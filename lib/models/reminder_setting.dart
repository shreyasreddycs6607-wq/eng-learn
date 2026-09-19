/// The learner's daily-reminder choice. Off by default — nothing is scheduled,
/// and no permission is requested, until the learner turns it on.
class ReminderSetting {
  /// 6:00 PM.
  static const defaultMinutesOfDay = 18 * 60;

  final bool enabled;
  final int minutesOfDay;

  const ReminderSetting({this.enabled = false, this.minutesOfDay = defaultMinutesOfDay});

  int get hour => minutesOfDay ~/ 60;
  int get minute => minutesOfDay % 60;

  ReminderSetting copyWith({bool? enabled, int? minutesOfDay}) =>
      ReminderSetting(enabled: enabled ?? this.enabled, minutesOfDay: minutesOfDay ?? this.minutesOfDay);
}
