import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/domain/reminders.dart';
import 'package:tnt_app/features/settings/reminder_settings.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

import 'support/seed_helper.dart';
import 'package:tnt_app/platform/notifications/reminder_scheduler.dart';

/// 假的调度器：只记录被排了哪些提醒。
class FakeScheduler implements ReminderScheduler {
  final List<List<TBlock>> syncs = <List<TBlock>>[];
  final StreamController<Reminder> fires =
      StreamController<Reminder>.broadcast();
  int initCount = 0;

  @override
  Stream<Reminder> get fired => fires.stream;

  @override
  Future<void> init() async => initCount++;

  @override
  Future<NotificationPermissionState> permissionState() async =>
      NotificationPermissionState.unknown;

  @override
  Future<NotificationPermissionState> requestPermissions() async =>
      NotificationPermissionState.unknown;

  @override
  Future<void> showTest() async {}

  @override
  Future<void> sync({
    required DateTime day,
    required List<TBlock> blocks,
    required ReminderSettings settings,
  }) async {
    syncs.add(List<TBlock>.of(blocks));
  }
}

TBlock block({
  String id = 'b1',
  String title = '交周报',
  int startMin = 560, // 09:20
  int durationMin = 30,
  bool done = false,
  BlockStatus status = BlockStatus.planned,
}) {
  return TBlock(
    id: id,
    title: title,
    lane: Lane.daily,
    startMin: startMin,
    durationMin: durationMin,
    priority: Priority.b,
    done: done,
    status: status,
  );
}

Future<void> settle(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    if (!container.read(timelineProvider).loading) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('时间轴一直没有加载完');
}

/// 等防抖（300ms）过去，让 sync 真的跑一次。
Future<void> settleReminders() =>
    Future<void>.delayed(const Duration(milliseconds: 450));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('提醒 id', () {
    test('同一个方块 id 每次算出来都一样，且是非负数', () {
      expect(reminderIdFor('b1'), reminderIdFor('b1'));
      expect(reminderIdFor('b1'), isNonNegative);
      expect(reminderIdFor('b1'), lessThan(0x80000000));
    });

    test('不同方块 id 不会撞（这里取几个样例）', () {
      final ids = ['a', 'b', 'c', 'block-1', 'block-2']
          .map(reminderIdFor)
          .toSet();
      expect(ids, hasLength(5));
    });
  });

  group('提醒时刻', () {
    final day = DateTime(2026, 11, 13);

    test('准点提醒 = 方块开始时刻', () {
      final at = reminderAt(block(startMin: 560), day, 0);
      expect(at, DateTime(2026, 11, 13, 9, 20));
    });

    test('提前 5 分钟', () {
      final at = reminderAt(block(startMin: 560), day, 5);
      expect(at, DateTime(2026, 11, 13, 9, 15));
    });

    test('已完成 / 非 planned 的方块不提醒', () {
      expect(reminderAt(block(done: true), day, 0), isNull);
      expect(reminderAt(block(status: BlockStatus.carried), day, 0), isNull);
      expect(reminderAt(block(status: BlockStatus.dropped), day, 0), isNull);
    });
  });

  group('排提醒列表', () {
    final day = DateTime(2026, 11, 13);

    test('只排未来且未完成的，按开始时间排序', () {
      final reminders = planReminders(
        blocks: [
          block(id: 'late', title: '下午', startMin: 900),
          block(id: 'early', title: '早上', startMin: 540),
          block(id: 'done', title: '做完了', startMin: 600, done: true),
          block(
            id: 'carried',
            title: '顺延来的',
            startMin: 660,
            status: BlockStatus.carried,
          ),
        ],
        day: day,
        leadMinutes: 0,
        now: DateTime(2026, 11, 13, 8),
      );
      expect(reminders.map((r) => r.blockId), ['early', 'late']);
      expect(reminders.first.at, DateTime(2026, 11, 13, 9));
    });

    test('已经过去的时刻不再排', () {
      final reminders = planReminders(
        blocks: [block(id: 'early', startMin: 540)],
        day: day,
        leadMinutes: 0,
        now: DateTime(2026, 11, 13, 10),
      );
      expect(reminders, isEmpty);
    });

    test('默认文案带泳道和时段，也可以自定义', () {
      final reminders = planReminders(
        blocks: [block(id: 'x', title: '交周报', startMin: 560)],
        day: day,
        leadMinutes: 0,
        now: DateTime(2026, 11, 13, 8),
      );
      expect(reminders.single.title, '交周报');
      expect(reminders.single.body, contains('日常'));
      expect(reminders.single.body, contains('09:20'));
      // 文案里的时段必须用「时长」算结束（用 endMin 当参数会算出 09:20 - 10:20 以外的怪时间）
      expect(reminders.single.body, contains('09:20 - 09:50'));

      final custom = planReminders(
        blocks: [block(id: 'x', title: '交周报', startMin: 560)],
        day: day,
        leadMinutes: 0,
        now: DateTime(2026, 11, 13, 8),
        bodyBuilder: (b) => '还有 10 分钟',
      );
      expect(custom.single.body, '还有 10 分钟');
    });
  });

  group('提醒设置', () {
    test('默认开启、准点，标签文案正确', () {
      const settings = ReminderSettings();
      expect(settings.enabled, isTrue);
      expect(settings.leadMinutes, 0);
      expect(settings.leadLabel, '准点');
      expect(ReminderSettings.leadLabelOf(5), '提前 5 分钟');
      expect(ReminderSettings.leadOptions, [0, 5, 15]);
    });

    test('copyWith 与相等性', () {
      const base = ReminderSettings();
      final changed = base.copyWith(enabled: false, leadMinutes: 15);
      expect(changed.enabled, isFalse);
      expect(changed.leadMinutes, 15);
      expect(changed, const ReminderSettings(enabled: false, leadMinutes: 15));
      expect(changed == base, isFalse);
      expect(base.copyWith(), base);
    });

    test('从 SharedPreferences 恢复上次的选择', () async {
      SharedPreferences.setMockInitialValues({
        'reminders.enabled': false,
        'reminders.leadMinutes': 15,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(reminderSettingsProvider);
      for (var i = 0; i < 50; i++) {
        if (container.read(reminderSettingsProvider).leadMinutes == 15) break;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final restored = container.read(reminderSettingsProvider);
      expect(restored.enabled, isFalse);
      expect(restored.leadMinutes, 15);
    });
  });

  group('状态层与调度器', () {
    late TntDatabase db;
    late ProviderContainer container;
    late FakeScheduler scheduler;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = TntDatabase.forTesting(NativeDatabase.memory());
      scheduler = FakeScheduler();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      container.read(timelineProvider.notifier);
      await settle(container);
    await seedTimeline(container);
      await settleReminders();
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('加载完当天就会把提醒排一遍', () async {
      expect(scheduler.syncs, isNotEmpty);
      expect(scheduler.syncs.last, isNotEmpty);
      // 传进去的是当天全部方块
      expect(
        scheduler.syncs.last.length,
        container.read(timelineProvider).blocks.length,
      );
    });

    test('移动方块后会重新排（防抖后只多排一次）', () async {
      final before = scheduler.syncs.length;
      final target = container.read(timelineProvider).blocks.first;
      container
          .read(timelineProvider.notifier)
          .moveBlock(target.id, startMin: 600, lane: target.lane);
      // 防抖期内连改几次
      container
          .read(timelineProvider.notifier)
          .moveBlock(target.id, startMin: 620, lane: target.lane);
      await settleReminders();
      expect(scheduler.syncs.length, before + 1);
    });

    test('关掉提醒设置后会按新设置重排', () async {
      final before = scheduler.syncs.length;
      await container
          .read(reminderSettingsProvider.notifier)
          .setEnabled(false);
      await settleReminders();
      expect(scheduler.syncs.length, before + 1);
      expect(container.read(reminderSettingsProvider).enabled, isFalse);
    });
  });
}
