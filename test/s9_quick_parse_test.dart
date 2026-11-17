import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/core/time_utils.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/domain/quick_parse.dart';

void main() {
  final now = DateTime(2026, 11, 15, 14, 12); // 周日下午

  test('完整写法：明天 10:30 交周报 45分 A', () {
    final draft = parseQuickAdd('明天 10:30 交周报 45分 A', now: now)!;
    expect(draft.day, DateTime(2026, 11, 16));
    expect(draft.startMin, 10 * 60 + 30);
    expect(draft.durationMin, 45);
    expect(draft.title, '交周报');
    expect(draft.priority, Priority.a);
    expect(draft.lane, Lane.temp);
    // formatRange 的第二个参数是「时长」而不是结束分钟，
    // 这里曾经传成 startMin + durationMin，预览显示成 10:30 - 21:45。
    expect(draft.preview, contains('10:30 - 11:15'));
  });

  test('中文时间与小时：今晚 8点 健身 1小时 打卡', () {
    final draft = parseQuickAdd('今晚 8点 健身 1小时 打卡', now: now)!;
    expect(draft.day, DateTime(2026, 11, 15));
    expect(draft.startMin, 20 * 60);
    expect(draft.durationMin, 60);
    expect(draft.title, '健身');
    expect(draft.lane, Lane.habit);
    expect(draft.priority, Priority.c);
  });

  test('半点与绝对日期：10点半 会 A级 11/20', () {
    final draft = parseQuickAdd('10点半 会 A级 11/20', now: now)!;
    expect(draft.day, DateTime(2026, 11, 20));
    expect(draft.startMin, 10 * 60 + 30);
    expect(draft.title, '会');
    expect(draft.priority, Priority.a);
  });

  test('只写标题：默认下一个半点、30 分钟、临时泳道', () {
    final draft = parseQuickAdd('买牛奶', now: now)!;
    expect(draft.day, DateTime(2026, 11, 15));
    // 14:12 → 下一个半点是 14:30
    expect(draft.startMin, 14 * 60 + 30);
    expect(draft.durationMin, 30);
    expect(draft.title, '买牛奶');
    expect(draft.lane, Lane.temp);
    expect(draft.priority, Priority.c);
  });

  test('英文词里的字母不会被当成优先级', () {
    final draft = parseQuickAdd('修 bug 30分', now: now)!;
    expect(draft.title, '修 bug');
    expect(draft.priority, Priority.c);
    expect(draft.durationMin, 30);
  });

  test('空了就返回 null', () {
    expect(parseQuickAdd('   ', now: now), isNull);
  });

  test('时长会被夹到合理范围', () {
    final tooLong = parseQuickAdd('写方案 20小时', now: now)!;
    expect(tooLong.durationMin, 12 * 60);
    final tooShort = parseQuickAdd('回邮件 2分', now: now)!;
    expect(tooShort.durationMin, kMinDuration);
  });

  test('预览串带上日期、时段、优先级与泳道', () {
    final draft = parseQuickAdd('明天 09:00 学英语 1小时', now: now)!;
    expect(draft.preview, contains('11/16'));
    expect(draft.preview, contains(formatRange(9 * 60, 60)));
    expect(draft.preview, contains('C 级'));
  });
}
