import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/app.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';

/// 顺延弹窗的端到端验证：库里有一条昨天没做完的方块 → 启动 → 弹窗 →
/// 点「顺延到今天」→ 今天的库里多一条带 fromBlockId 的方块，原来那条变 carried。
void main() {
  testWidgets('昨天没做完的方块会在启动时弹窗，点顺延后落到今天', (tester) async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final dayRepo = DayBlockRepository(db);
    final todayKey = formatDateKey(DateTime.now());
    final yesterdayKey = formatDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await dayRepo.upsert(
      TBlock(
        id: 'legacy',
        title: '昨天的报告',
        lane: Lane.temp,
        startMin: 630,
        durationMin: 45,
        priority: Priority.b,
      ),
      yesterdayKey,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const TntApp(),
      ),
    );

    // 等首帧 + 异步读库 + addPostFrameCallback 把弹窗推上来
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('有 1 件事没做完'), findsOneWidget);
    expect(find.textContaining('昨天的报告'), findsWidgets);

    await tester.tap(find.text('顺延到今天'));
    await tester.pumpAndSettle();

    final today = await dayRepo.loadDay(todayKey);
    final carried = today.where((b) => b.title == '昨天的报告').toList();
    expect(carried, hasLength(1));
    expect(carried.single.fromBlockId, 'legacy');
    expect(carried.single.carryCount, 1);
    expect(carried.single.originalDate, yesterdayKey);
    expect(carried.single.startMin, 630);

    // 原来那条变成 carried，不会再次被顺延
    final all = await dayRepo.loadDay(yesterdayKey, includeDone: true);
    expect(all.single.status, BlockStatus.carried);
    expect(await dayRepo.unfinishedBefore(todayKey), isEmpty);
  });

  testWidgets('点「丢弃」则原方块标 dropped，今天不多东西', (tester) async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final dayRepo = DayBlockRepository(db);
    final todayKey = formatDateKey(DateTime.now());
    final yesterdayKey = formatDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await dayRepo.upsert(
      TBlock(
        id: 'legacy2',
        title: '过期的准备',
        lane: Lane.daily,
        startMin: 480,
        durationMin: 30,
      ),
      yesterdayKey,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const TntApp(),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text('有 1 件事没做完'), findsOneWidget);

    await tester.tap(find.text('丢弃'));
    await tester.pumpAndSettle();

    expect(await dayRepo.loadDay(todayKey), isEmpty);
    final all = await dayRepo.loadDay(yesterdayKey, includeDone: true);
    expect(all.single.status, BlockStatus.dropped);
    expect(await dayRepo.unfinishedBefore(todayKey), isEmpty);
  });
}
