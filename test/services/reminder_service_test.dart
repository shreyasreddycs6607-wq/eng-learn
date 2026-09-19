import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/progress_repository.dart';
import 'package:english_kaliyona/models/reminder_setting.dart';
import 'package:english_kaliyona/services/reminder_service.dart';
import '../fakes/fake_reminder_backend.dart';

void main() {
  late AppDatabase db;
  late ProgressRepository repo;
  late FakeReminderBackend backend;
  late ReminderService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProgressRepository(db);
    backend = FakeReminderBackend();
    service = ReminderService(backend, repo);
  });

  tearDown(() => db.close());

  const evening = 18 * 60; // 6:00 PM
  const morning = 8 * 60 + 30; // 8:30 AM

  test('is off by default, at 6:00 PM, and asks for nothing', () async {
    final s = await service.current();
    expect((s.enabled, s.minutesOfDay), (false, ReminderSetting.defaultMinutesOfDay));
    expect(backend.permissionRequests, 0);
    expect(backend.scheduled, isEmpty);
  });

  test('turning it on asks permission, schedules that time once, and remembers it', () async {
    expect(await service.enable(evening), isTrue);

    expect(backend.permissionRequests, 1);
    expect(backend.scheduled, [evening]);
    final saved = await ReminderService(FakeReminderBackend(), repo).current(); // a "restart"
    expect((saved.enabled, saved.minutesOfDay), (true, evening));
  });

  test('a refused notification permission leaves the reminder off and schedules nothing', () async {
    backend.permissionGranted = false;

    expect(await service.enable(evening), isFalse);

    expect(backend.scheduled, isEmpty);
    expect((await service.current()).enabled, isFalse);
  });

  test('turning it off cancels the alarm but keeps the chosen time', () async {
    await service.enable(morning);
    await service.disable();

    expect(backend.cancelCalls, 1);
    final s = await service.current();
    expect((s.enabled, s.minutesOfDay), (false, morning));
  });

  test('changing the time while on reschedules once, without a second permission prompt', () async {
    await service.enable(evening);
    await service.changeTime(morning);

    expect(backend.scheduled, [evening, morning]);
    expect((await service.current()).minutesOfDay, morning);
  });

  test('changing the time while off only saves it', () async {
    await service.changeTime(morning);

    expect(backend.scheduled, isEmpty);
    expect(backend.permissionRequests, 0);
    final s = await service.current();
    expect((s.enabled, s.minutesOfDay), (false, morning));
  });

  group('restore at app start', () {
    test('re-applies a saved reminder', () async {
      await service.enable(morning);
      final restarted = FakeReminderBackend();

      await ReminderService(restarted, repo).restore();

      expect(restarted.scheduled, [morning]);
      expect(restarted.permissionRequests, 0);
    });

    test('does nothing when the reminder is off', () async {
      final restarted = FakeReminderBackend();
      await ReminderService(restarted, repo).restore();
      expect(restarted.scheduled, isEmpty);
    });

    test('never throws, so a notification problem cannot stop the app opening', () async {
      await service.enable(evening);
      final broken = FakeReminderBackend()..failToSchedule = true;

      await expectLater(ReminderService(broken, repo).restore(), completes);
    });
  });
}
