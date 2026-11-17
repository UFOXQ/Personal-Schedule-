import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tnt_app/app.dart';
import 'package:tnt_app/core/time_utils.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/layout/timeline_layout.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_painter.dart';

/// 回归：手机端「长按拿起 → 拖动」必须真的能把方块挪走。
///
/// 之前的 bug：长按胜出后，同一个指针的 Scale 手势在竞技场里被判负，
/// `_onScaleUpdate` 再也不回调，于是方块拿起来了却纹丝不动。
/// 现在改成用 `onLongPressMoveUpdate` 自己算位移，这个测试就是钉它。
void main() {
  setUp(() {
    // 首次引导会盖住界面，测试里直接跳过
    SharedPreferences.setMockInitialValues(<String, Object>{
      'flutter.ui.onboarded': true,
    });
  });

  testWidgets('长按方块后拖动，方块换了泳道也换了时间', (tester) async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final dayRepo = DayBlockRepository(db);
    final todayKey = formatDateKey(DateTime.now());

    const pxPerMin = 1.5;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = (nowMin - 30).clamp(0, 1380);
    const durationMin = 60;

    await dayRepo.upsert(
      TBlock(
        id: 'drag-me',
        title: '拖我一下',
        lane: Lane.daily,
        startMin: startMin,
        durationMin: durationMin,
        priority: Priority.c,
      ),
      todayKey,
    );

    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const TntApp(),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final paintFinder = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TimelinePainter,
    );
    expect(paintFinder, findsOneWidget);

    final viewport = tester.getSize(paintFinder);
    final paintTopLeft = tester.getTopLeft(paintFinder);

    final layout = TimelineLayout.compute(
      viewport: viewport,
      pxPerMin: pxPerMin,
      blocks: await dayRepo.loadDay(todayKey),
      showTopInLane: false,
      now: now,
    );

    // 与 TimelineView 的初次滚动一致：现在往前 2 小时
    final contentViewportHeight =
        viewport.height - TimelineLayout.headerHeight;
    final maxScroll = (kMinutesPerDay * pxPerMin +
            TimelineLayout.bottomPadding -
            contentViewportHeight)
        .clamp(0.0, double.infinity);
    final scroll = ((nowMin - 120) * pxPerMin).clamp(0.0, maxScroll);

    // 屏幕坐标 = 内容坐标 + 表头 - 滚动
    double screenY(int minute) =>
        paintTopLeft.dy +
        TimelineLayout.headerHeight +
        minute * pxPerMin -
        scroll;

    final dailyCenterX = paintTopLeft.dx +
        layout.laneRectAt(Lane.daily).center.dx;
    final start = Offset(dailyCenterX, screenY(startMin) + 12);

    // 手指按住 → 等过长按 → 往右下拖到「打卡」泳道
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(180, 80));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    final moved = (await dayRepo.loadDay(
      todayKey,
    )).firstWhere((b) => b.id == 'drag-me');

    expect(moved.lane, Lane.habit, reason: '往右拖过了泳道中线，应该换到「打卡」');
    expect(moved.startMin, greaterThan(startMin), reason: '往下拖了 80px，开始时间应该变晚');
  });

  testWidgets('双击方块弹出快速修改面板', (tester) async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final dayRepo = DayBlockRepository(db);
    final todayKey = formatDateKey(DateTime.now());
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = (nowMin - 30).clamp(0, 1380);

    await dayRepo.upsert(
      TBlock(
        id: 'tap-me',
        title: '点我两下',
        lane: Lane.daily,
        startMin: startMin,
        durationMin: 45,
        priority: Priority.b,
      ),
      todayKey,
    );

    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const TntApp(),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    final paintFinder = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TimelinePainter,
    );
    final viewport = tester.getSize(paintFinder);
    final paintTopLeft = tester.getTopLeft(paintFinder);
    final layout = TimelineLayout.compute(
      viewport: viewport,
      pxPerMin: 1.5,
      blocks: await dayRepo.loadDay(todayKey),
      showTopInLane: false,
      now: now,
    );

    final contentViewportHeight =
        viewport.height - TimelineLayout.headerHeight;
    final maxScroll = (kMinutesPerDay * 1.5 +
            TimelineLayout.bottomPadding -
            contentViewportHeight)
        .clamp(0.0, double.infinity);
    final scroll = ((nowMin - 120) * 1.5).clamp(0.0, maxScroll);

    final point = Offset(
      paintTopLeft.dx + layout.laneRectAt(Lane.daily).center.dx,
      paintTopLeft.dy +
          TimelineLayout.headerHeight +
          (startMin + 12) * 1.5 -
          scroll,
    );

    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(point);
    await tester.pumpAndSettle();

    expect(find.text('快速调整'), findsOneWidget);
    expect(find.text('点我两下'), findsWidgets);

    // 拖「结束」滑块，改动是即时写库的（面板关掉后库里就该是新的时长）
    await tester.drag(
      find.descendant(
        of: find.byKey(const Key('quick-edit-end')),
        matching: find.byType(Slider),
      ),
      const Offset(60, 0),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.byKey(const Key('quick-edit-save')));
    await tester.pump(const Duration(milliseconds: 300));

    final saved = (await dayRepo.loadDay(
      todayKey,
    )).firstWhere((b) => b.id == 'tap-me');
    expect(saved.durationMin, greaterThan(45), reason: '把结束时间往后拖，时长应该变大');
  });
}