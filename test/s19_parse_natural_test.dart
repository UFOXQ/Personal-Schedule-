import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/domain/quick_parse.dart';

void main() {
  // 固定一个「下午」的时刻，避免测试依赖运行时间
  final now = DateTime(2026, 11, 16, 13, 20);

  QuickDraft? parse(String text) => parseQuickAdd(text, now: now);

  group('中文数字与时段词', () {
    test('下午 三点 睡觉', () {
      final draft = parse('下午 三点 睡觉')!;
      expect(draft.startMin, 15 * 60);
      expect(draft.title, '睡觉');
    });

    test('晚上八点半 健身 打卡', () {
      final draft = parse('晚上八点半 健身 打卡')!;
      expect(draft.startMin, 20 * 60 + 30);
      expect(draft.lane, Lane.habit);
      expect(draft.title, '健身');
    });

    test('明天 十点 开会', () {
      final draft = parse('明天 十点 开会')!;
      expect(draft.day, DateTime(2026, 11, 17));
      expect(draft.startMin, 10 * 60);
    });

    test('中午十二点 午饭', () {
      final draft = parse('中午十二点 午饭')!;
      expect(draft.startMin, 12 * 60);
      expect(draft.title, '午饭');
    });

    test('凌晨两点 看球（不会被推到下午）', () {
      final draft = parse('凌晨两点 看球')!;
      expect(draft.startMin, 2 * 60);
    });

    test('下午三点 交周报 四十五分钟', () {
      final draft = parse('下午三点 交周报 四十五分钟')!;
      expect(draft.startMin, 15 * 60);
      expect(draft.durationMin, 45);
      expect(draft.title, '交周报');
    });
  });

  group('时长写法', () {
    test('半小时', () {
      expect(parse('晚上九点 拉伸 半小时')!.durationMin, 30);
    });

    test('一个半小时', () {
      expect(parse('晚上九点 拉伸 一个半小时')!.durationMin, 90);
    });

    test('一刻钟', () {
      expect(parse('晚上九点 拉伸 一刻钟')!.durationMin, 15);
    });

    test('三刻钟', () {
      expect(parse('晚上九点 拉伸 三刻钟')!.durationMin, 45);
    });
  });

  group('优先级', () {
    test('A级 后面直接跟汉字也能认', () {
      final draft = parse('A级打卡 修登录 bug 45分钟')!;
      expect(draft.priority, Priority.a);
      expect(draft.lane, Lane.habit);
      expect(draft.durationMin, 45);
      expect(draft.title, '修登录 bug');
    });

    test('单独一个 D 也能认', () {
      final draft = parse('晚上十点 冥想 D')!;
      expect(draft.priority, Priority.d);
      expect(draft.title, '冥想');
    });

    test('英文单词里的字母不会被当成优先级', () {
      final draft = parse('下午两点 看 APP 文档')!;
      expect(draft.priority, Priority.c);
      expect(draft.title, contains('APP'));
    });
  });
}
