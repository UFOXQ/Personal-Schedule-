import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/materialize.dart';
import '../../data/providers.dart';
import '../../data/repositories/day_block_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/materialize.dart';
import '../../domain/models/carry_over.dart';
import '../../domain/models/tblock.dart';
import '../../platform/notifications/reminder_scheduler.dart';
import '../../platform/widgets/home_widget_bridge.dart';
import '../settings/reminder_settings.dart';

/// 时间轴页面的状态。
///
/// 方块来自 Drift（`day_blocks` 表），UI 只认这一层；写操作先改内存再落库，
/// 保证拖拽时的手感不被 IO 拖慢。
class TimelineState {
  const TimelineState({
    required this.blocks,
    required this.now,
    required this.dateKey,
    this.showTopInLane = true,
    this.selectedId,
    this.loading = false,
    this.carryOvers = const [],
  });

  final List<TBlock> blocks;
  final DateTime now;

  /// 当前这一天，yyyy-MM-dd
  final String dateKey;

  /// 置顶项是否同时保留在原泳道里（用户要求做成开关）
  final bool showTopInLane;

  final String? selectedId;

  /// 首次从数据库装载中
  final bool loading;

  /// 之前的日期没做完、等着问「顺延还是丢」的方块
  final List<CarryOver> carryOvers;

  TBlock? get selected {
    if (selectedId == null) return null;
    for (final block in blocks) {
      if (block.id == selectedId) return block;
    }
    return null;
  }

  TimelineState copyWith({
    List<TBlock>? blocks,
    DateTime? now,
    String? dateKey,
    bool? showTopInLane,
    bool? loading,
    List<CarryOver>? carryOvers,
    Object? selectedId = _sentinel,
  }) {
    return TimelineState(
      blocks: blocks ?? this.blocks,
      now: now ?? this.now,
      dateKey: dateKey ?? this.dateKey,
      showTopInLane: showTopInLane ?? this.showTopInLane,
      selectedId: identical(selectedId, _sentinel)
          ? this.selectedId
          : selectedId as String?,
      loading: loading ?? this.loading,
      carryOvers: carryOvers ?? this.carryOvers,
    );
  }
}

const Object _sentinel = Object();

class TimelineNotifier extends Notifier<TimelineState> {
  static const Uuid _uuid = Uuid();

  late final DayBlockRepository _repo;
  late final LibraryRepository _library;
  bool _disposed = false;
  Timer? _reminderDebounce;

  @override
  TimelineState build() {
    _repo = ref.watch(dayBlockRepositoryProvider);
    _library = ref.watch(libraryRepositoryProvider);
    ref.onDispose(() {
      _disposed = true;
      _reminderDebounce?.cancel();
    });
    // 设置面板里改了开关 / 提前量，立刻重排
    ref.listen<ReminderSettings>(reminderSettingsProvider, (previous, next) {
      if (previous?.enabled == next.enabled &&
          previous?.leadMinutes == next.leadMinutes) {
        return;
      }
      _scheduleReminderSync();
    });
    final now = DateTime.now();
    final key = formatDateKey(now);
    unawaited(_load(key));
    return TimelineState(
      blocks: const [],
      now: now,
      dateKey: key,
      loading: true,
    );
  }

  /// 装载当天：
  /// 1. 读当天的方块
  /// 2. 第一次启动（全库为空）时灌示例数据 + 示例集合 / 长期计划
  /// 3. 把今天生效的长期计划物化成方块（幂等）
  /// 4. 找出以前没做完的方块，交给 UI 弹顺延窗
  Future<void> _load(String key) async {
    try {
      final total = await _repo.countAll();
      var blocks = await _repo.loadDay(key);

      if (total == 0) {
        await _seedLibrary();
        blocks = _seed(DateTime.now());
        await _repo.upsertAll(blocks, key);
      }

      blocks = [...blocks, ...await _materializePlans(key, blocks)];

      if (_disposed) return;
      state = state.copyWith(blocks: blocks, loading: false);

      final pending = await _repo.unfinishedBefore(key);
      if (_disposed) return;
      // 只有看「今天」时才问顺延；翻看以前的日期不该被弹窗拦住
      final isToday = key == formatDateKey(DateTime.now());
      state = state.copyWith(
        carryOvers: isToday
            ? [
                for (final c in pending)
                  if (needsCarryPrompt(c.block)) c,
              ]
            : const [],
      );
      _scheduleReminderSync();
    } catch (error, stack) {
      // 数据库打不开也不能白屏：退回内存模式，至少能用
      if (_disposed) return;
      state = state.copyWith(blocks: _seed(DateTime.now()), loading: false);
      // ignore: avoid_print
      print('TNT: 读取数据库失败，已退回内存模式 -> $error\n$stack');
    }
  }

  /// 长期计划 → 今天的方块；已在库里的来源不会再生成
  Future<List<TBlock>> _materializePlans(
    String key,
    List<TBlock> existing,
  ) async {
    final day = DateTime.parse(key);
    final plans = await _library.plansOn(day);
    if (plans.isEmpty) return const [];
    final keys = existingInstanceKeys(existing);
    final created = <TBlock>[];
    for (final plan in plans) {
      created.addAll(blocksFromPlan(plan, key, keys));
    }
    if (created.isEmpty) return const [];
    await _repo.upsertAll(created, key);
    return created;
  }

  List<TBlock> get _blocks => state.blocks;

  void _commit(List<TBlock> next) {
    state = state.copyWith(blocks: next, loading: false);
    _scheduleReminderSync();
  }

  /// 提醒排程跟着方块走：合并 300ms 内的连续改动（拖拽会狂改状态）
  void _scheduleReminderSync() {
    _reminderDebounce?.cancel();
    _reminderDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_syncReminders());
      unawaited(_syncHomeWidget());
    });
  }

  /// 桌面小组件也跟着同一次防抖刷新（Android 才有实际动作）
  Future<void> _syncHomeWidget() async {
    if (_disposed) return;
    try {
      await ref
          .read(homeWidgetBridgeProvider)
          .sync(day: DateTime.parse(state.dateKey), blocks: state.blocks);
    } catch (error) {
      // 小组件失败不影响主界面
      debugPrint('TNT: 小组件同步失败 -> $error');
    }
  }

  Future<void> _syncReminders() async {
    if (_disposed) return;
    final settings = ref.read(reminderSettingsProvider);
    try {
      await ref
          .read(reminderSchedulerProvider)
          .sync(
            day: DateTime.parse(state.dateKey),
            blocks: state.blocks,
            settings: settings,
          );
    } catch (error) {
      // 提醒失败不影响时间轴本身
      // ignore: avoid_print
      print('TNT: 同步提醒失败 -> $error');
    }
  }

  /// 在空白处放置一个新方块
  TBlock addBlockAt({required Lane lane, required int startMin}) {
    final block = TBlock(
      id: _uuid.v4(),
      title: _defaultTitle(lane),
      lane: lane,
      startMin: startMin,
      durationMin: 30,
      priority: Priority.c,
    );
    _commit([..._blocks, block]);
    state = state.copyWith(selectedId: block.id);
    unawaited(_repo.upsert(block, state.dateKey));
    return block;
  }

  /// 拖动：换位置（可跨泳道）
  void moveBlock(String id, {required int startMin, required Lane lane}) {
    final next = [
      for (final block in _blocks)
        if (block.id == id)
          block.copyWith(startMin: startMin, lane: lane)
        else
          block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// 拖右（下）边缘：改时长
  void resizeBlock(String id, {required int durationMin}) {
    final next = [
      for (final block in _blocks)
        if (block.id == id) block.copyWith(durationMin: durationMin) else block,
    ];
    _commit(next);
    _persist(id, next);
  }

  void renameBlock(String id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final next = [
      for (final block in _blocks)
        if (block.id == id) block.copyWith(title: trimmed) else block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// A -> B -> C -> D -> A
  void cyclePriority(String id) {
    final next = [
      for (final block in _blocks)
        if (block.id == id)
          block.copyWith(priority: block.priority.next)
        else
          block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// 完成：写一条完成记录，方块从当天时间轴消失（记录页仍可回看）
  Future<void> completeSelected() async {
    final block = state.selected;
    if (block == null) return;
    _commit([
      for (final b in _blocks)
        if (b.id != block.id) b,
    ]);
    state = state.copyWith(selectedId: null);
    await _library.logCompletion(
      dayBlockId: block.id,
      date: state.dateKey,
      title: block.title,
      lane: block.lane.index,
      startMin: block.startMin,
      durationMin: block.durationMin,
      note: block.note.isEmpty ? null : block.note,
    );
    await _repo.setStatus(block.id, BlockStatus.done);
  }

  void deleteBlock(String id) {
    _commit([
      for (final block in _blocks)
        if (block.id != id) block,
    ]);
    if (state.selectedId == id) {
      state = state.copyWith(selectedId: null);
    }
    unawaited(_repo.softDelete(id));
  }

  /// 顺延弹窗的答复：保留 → 复制到今天；丢弃 → 标记 dropped
  Future<void> resolveCarryOvers({required bool keep}) async {
    final pendings = state.carryOvers;
    if (pendings.isEmpty) return;
    state = state.copyWith(carryOvers: const []);

    if (!keep) {
      for (final c in pendings) {
        await _repo.setStatus(c.block.id, BlockStatus.dropped);
      }
      return;
    }

    final created = <TBlock>[
      for (final c in pendings)
        carryOverBlock(c.block, newId: _uuid.v4(), sourceDateKey: c.date),
    ];
    await _repo.upsertAll(created, state.dateKey);
    for (final c in pendings) {
      await _repo.setStatus(c.block.id, BlockStatus.carried);
    }
    _commit([..._blocks, ...created]);
  }

  /// 先不问，下次打开再说
  void postponeCarryOvers() {
    state = state.copyWith(carryOvers: const []);
  }

  /// 把一个集合整包投入今天（幂等：同一天重复投入不会叠两份）
  Future<int> injectCollection(String collectionId) async {
    final items = await _library.collectionItems(collectionId);
    final all = blocksFromCollection(collectionId, items, state.dateKey);
    // 只补还没投过的那几条（集合里后来加的新条目也能补进去）
    final existing = existingInstanceKeys(_blocks);
    final created = all
        .where((b) => needsMaterialize(b.instanceGroupId ?? '', existing))
        .toList();
    if (created.isEmpty) return 0;
    await _repo.upsertAll(created, state.dateKey);
    _commit([..._blocks, ...created]);
    return created.length;
  }

  void select(String? id) {
    state = state.copyWith(selectedId: id);
  }

  /// 跳去看某一天（yyyy-MM-dd）。日历选日期、顶栏左右箭头都走这里。
  Future<void> goToDate(String key) async {
    if (key == state.dateKey) return;
    state = state.copyWith(
      dateKey: key,
      blocks: const [],
      loading: true,
      selectedId: null,
      carryOvers: const [],
    );
    await _load(key);
  }

  /// 前后翻一天
  Future<void> shiftDay(int delta) {
    final day = DateTime.parse(state.dateKey).add(Duration(days: delta));
    return goToDate(formatDateKey(day));
  }

  /// 回到今天
  Future<void> goToday() => goToDate(formatDateKey(DateTime.now()));

  /// 原地重载（计划改过 / 集合换过之后，需要重新物化当天）
  Future<void> reload() async {
    state = state.copyWith(
      blocks: const [],
      loading: true,
      selectedId: null,
      carryOvers: const [],
    );
    await _load(state.dateKey);
  }

  void toggleShowTopInLane() {
    state = state.copyWith(showTopInLane: !state.showTopInLane);
  }

  /// 每分钟刷新「现在」线和死线倒计时。
  ///
  /// 注意：只在「看今天」时跨零点自动换页；翻看别的日期时保持当前页。
  void tickNow() {
    final now = DateTime.now();
    final key = formatDateKey(now);
    if (key == state.dateKey) {
      state = state.copyWith(now: now);
      return;
    }
    final yesterdayView = formatDateKey(now.subtract(const Duration(days: 1)));
    if (state.dateKey == yesterdayView) {
      // 一直挂着看昨天，跨零点后跟着到今天
      state = state.copyWith(
        now: now,
        dateKey: key,
        blocks: const [],
        loading: true,
        selectedId: null,
        carryOvers: const [],
      );
      unawaited(_load(key));
      return;
    }
    state = state.copyWith(now: now);
  }

  void _persist(String id, List<TBlock> next) {
    for (final block in next) {
      if (block.id == id) {
        unawaited(_repo.upsert(block, state.dateKey));
        return;
      }
    }
  }

  String _defaultTitle(Lane lane) {
    switch (lane) {
      case Lane.daily:
        return '新日常';
      case Lane.habit:
        return '新打卡';
      case Lane.temp:
        return '新事件';
    }
  }

  // ── 示例数据 ───────────────────────────────────────────────
  /// 第一次启动时给两个集合和一个长期计划，让 S3 的功能一进来就能看见
  Future<void> _seedLibrary() async {
    if ((await _library.collections()).isNotEmpty) return;
    await _library.createCollectionSimple(
      name: '早间流程',
      items: const [
        CollectionSeedItem(
          title: '喂猫',
          lane: Lane.daily,
          startMin: 430,
          durationMin: 15,
          priority: Priority.d,
        ),
        CollectionSeedItem(
          title: '早餐',
          lane: Lane.daily,
          startMin: 460,
          durationMin: 30,
        ),
      ],
    );
    await _library.createCollectionSimple(
      name: '晚间收尾',
      items: const [
        CollectionSeedItem(
          title: '晚饭',
          lane: Lane.daily,
          startMin: 1110,
          durationMin: 45,
        ),
        CollectionSeedItem(
          title: '洗澡',
          lane: Lane.daily,
          startMin: 1290,
          durationMin: 25,
          priority: Priority.d,
        ),
        CollectionSeedItem(
          title: '复盘日记',
          lane: Lane.habit,
          startMin: 1230,
          durationMin: 20,
        ),
      ],
    );

    if ((await _library.plans()).isNotEmpty) return;
    final today = DateTime.now();
    await _library.createPlanSimple(
      id: _uuid.v4(),
      title: '学英语',
      startDate: formatDateKey(today.subtract(const Duration(days: 30))),
      endDate: formatDateKey(today.add(const Duration(days: 60))),
      lane: Lane.habit,
      startMin: 540,
      durationMin: 60,
      priority: Priority.b,
    );
  }

  TBlock _block(
    String title,
    Lane lane,
    int hour,
    int minute,
    int duration,
    Priority priority, {
    Duration? deadline,
    DateTime? now,
  }) {
    return TBlock(
      id: _uuid.v4(),
      title: title,
      lane: lane,
      startMin: hour * 60 + minute,
      durationMin: duration,
      priority: priority,
      // deadline 用「相对现在还有多久」描述，落库时再换成绝对时间
      deadline: deadline == null ? null : (now ?? DateTime.now()).add(deadline),
    );
  }

  /// 示例当天排班。`学英语` 故意不放这里——它由长期计划物化生成，
  /// 用来验证「计划 → 当天方块」这条链路。
  List<TBlock> _seed(DateTime now) {
    return [
      // ① 日常琐事
      _block('喂猫', Lane.daily, 7, 10, 15, Priority.d),
      _block('早餐', Lane.daily, 7, 40, 30, Priority.c),
      _block('洗衣服', Lane.daily, 12, 0, 40, Priority.d),
      _block('午饭', Lane.daily, 12, 40, 45, Priority.c),
      _block('晚饭', Lane.daily, 18, 30, 45, Priority.c),
      _block('洗澡', Lane.daily, 21, 30, 25, Priority.d),

      // ② 长期任务打卡（含一处重叠：阅读 vs 线上会议）
      _block('阅读', Lane.habit, 14, 0, 60, Priority.c),
      _block('线上会议', Lane.habit, 14, 20, 45, Priority.c),
      _block('健身', Lane.habit, 16, 30, 60, Priority.d),
      _block('复盘日记', Lane.habit, 20, 30, 20, Priority.c),
      _block('冥想', Lane.habit, 22, 30, 15, Priority.d),

      // ③ 平时没有、A 级或临近死线才出现的临时事件
      _block('交周报', Lane.temp, 10, 30, 60, Priority.a),
      _block(
        '回复邮件',
        Lane.temp,
        10,
        45,
        30,
        Priority.b,
        deadline: const Duration(hours: 30),
        now: now,
      ),
      _block(
        '修登录 bug',
        Lane.temp,
        15,
        30,
        45,
        Priority.b,
        deadline: const Duration(hours: 20),
        now: now,
      ),
    ];
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);
