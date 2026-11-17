import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/time_utils.dart';
import '../../data/materialize.dart';
import '../../data/providers.dart';
import '../../data/repositories/day_block_repository.dart';
import '../../data/repositories/lane_repository.dart';
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
    this.locked = false,
    this.hiddenLanes = const <Lane>{},
    this.autoHideEmptyLanes = false,
    this.jumpMinute,
    this.lanes = Lane.defaults,
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

  /// 只读浏览模式：锁上之后只能滚动/缩放/查看，不能改任何东西
  final bool locked;

  /// 被整条隐藏的泳道（界面不显示、也不参与布局）
  final Set<Lane> hiddenLanes;

  /// 请求把视口滚到这一分钟（周视图点了某个色块时用），消费一次就清空
  final int? jumpMinute;

  /// 空泳道自动收起（默认关，免得突然找不到泳道）
  final bool autoHideEmptyLanes;

  /// 当前启用的泳道（用户可增删改名排序，默认日常/打卡/临时）
  final List<Lane> lanes;

  /// 能不能改数据：锁定、加载中都不行
  bool get canEdit => !locked && !loading;

  /// 这条泳道是否显示
  bool laneVisible(Lane lane) => !hiddenLanes.contains(lane);

  /// 真正要传给布局的隐藏集合（手动的 + 自动收起的空泳道）
  Set<Lane> get effectiveHiddenLanes {
    if (!autoHideEmptyLanes) return hiddenLanes;
    final used = {for (final block in blocks) block.lane};
    final empty = lanes.where((lane) => !used.contains(lane));
    return {...hiddenLanes, ...empty};
  }

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
    bool? locked,
    List<CarryOver>? carryOvers,
    Set<Lane>? hiddenLanes,
    bool? autoHideEmptyLanes,
    List<Lane>? lanes,
    Object? jumpMinute = _sentinel,
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
      locked: locked ?? this.locked,
      carryOvers: carryOvers ?? this.carryOvers,
      hiddenLanes: hiddenLanes ?? this.hiddenLanes,
      autoHideEmptyLanes: autoHideEmptyLanes ?? this.autoHideEmptyLanes,
      lanes: lanes ?? this.lanes,
      jumpMinute: identical(jumpMinute, _sentinel)
          ? this.jumpMinute
          : jumpMinute as int?,
    );
  }
}

const Object _sentinel = Object();

class TimelineNotifier extends Notifier<TimelineState> {
  static const Uuid _uuid = Uuid();

  late final DayBlockRepository _repo;
  late final LibraryRepository _library;
  late final LaneRepository _lanes;
  bool _disposed = false;
  Timer? _reminderDebounce;

  @override
  TimelineState build() {
    _repo = ref.watch(dayBlockRepositoryProvider);
    _library = ref.watch(libraryRepositoryProvider);
    _lanes = ref.watch(laneRepositoryProvider);
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
      final lanes = await _lanes.all();
      if (_disposed) return;
      state = state.copyWith(lanes: lanes);
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

  /// 在空白处放置一个新方块（锁定/加载中返回 null）
  TBlock? addBlockAt({required Lane lane, required int startMin}) {
    if (!state.canEdit) return null;
    final block = TBlock(
      id: _uuid.v4(),
      title: _defaultTitle(lane),
      lane: lane,
      startMin: clampStartMinute(startMin, 30),
      durationMin: 30,
      priority: Priority.c,
    );
    _commit([..._blocks, block]);
    state = state.copyWith(selectedId: block.id);
    unawaited(_repo.upsert(block, state.dateKey));
    return block;
  }

  /// 改单个方块的任意字段（编辑面板 / 右键菜单都走这里）
  void updateBlock(
    String id, {
    String? title,
    int? startMin,
    int? durationMin,
    Priority? priority,
    Lane? lane,
    Object? deadline = _sentinel,
  }) {
    if (!state.canEdit) return;
    final trimmed = title?.trim();
    final target = _blockOrNull(id);
    if (target == null) return;
    final nextStart = (startMin ?? target.startMin).clamp(
      0,
      kMinutesPerDay - kMinDuration,
    );
    final nextDuration = clampDuration(
      nextStart,
      durationMin ?? target.durationMin,
    );
    final next = [
      for (final block in _blocks)
        if (block.id == id)
          block.copyWith(
            title: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
            startMin: nextStart,
            durationMin: nextDuration,
            priority: priority,
            lane: lane,
            // 原样透传：没传就是「保留」，显式 null 才是「清除死线」
            deadline: deadline,
          )
        else
          block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// 只读浏览开关
  void toggleLock() {
    final locked = !state.locked;
    state = state.copyWith(
      locked: locked,
      selectedId: locked ? null : state.selectedId,
    );
  }

  /// 拖动：换位置（可跨泳道）
  void moveBlock(String id, {required int startMin, required Lane lane}) {
    if (!state.canEdit) return;
    final target = _blockOrNull(id);
    if (target == null) return;
    final clamped = clampStartMinute(startMin, target.durationMin);
    final next = [
      for (final block in _blocks)
        if (block.id == id)
          block.copyWith(startMin: clamped, lane: lane)
        else
          block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// 拖右（下）边缘：改时长
  void resizeBlock(String id, {required int durationMin}) {
    if (!state.canEdit) return;
    final target = _blockOrNull(id);
    if (target == null) return;
    final fitted = clampDuration(target.startMin, durationMin);
    final next = [
      for (final block in _blocks)
        if (block.id == id) block.copyWith(durationMin: fitted) else block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// 拖上边缘：开始时间变、结束时间不动
  void resizeStart(String id, {required int startMin}) {
    if (!state.canEdit) return;
    final target = _blockOrNull(id);
    if (target == null) return;
    final end = target.startMin + target.durationMin;
    final fittedStart = startMin.clamp(0, (end - kMinDuration).clamp(0, kMinutesPerDay));
    final fittedDuration = (end - fittedStart).clamp(kMinDuration, kMinutesPerDay);
    final next = [
      for (final block in _blocks)
        if (block.id == id)
          block.copyWith(
            startMin: fittedStart,
            durationMin: fittedDuration,
          )
        else
          block,
    ];
    _commit(next);
    _persist(id, next);
  }

  void renameBlock(String id, String title) {
    if (!state.canEdit) return;
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
    if (!state.canEdit) return;
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

  /// 长按优先级小旗：直接指定某一级
  void setPriority(String id, Priority priority) {
    if (!state.canEdit) return;
    if (_blockOrNull(id) == null) return;
    final next = [
      for (final block in _blocks)
        if (block.id == id) block.copyWith(priority: priority) else block,
    ];
    _commit(next);
    _persist(id, next);
  }

  /// 清空当天：按泳道多选，可选是否连已完成一起清。
  /// 返回被清掉的方块列表，调用方拿去做「撤销」。
  Future<List<TBlock>> clearBlocks({
    required Set<Lane> lanes,
    required bool includeDone,
  }) async {
    if (!state.canEdit) return const <TBlock>[];
    final victims = [
      for (final block in _blocks)
        if (lanes.contains(block.lane) && (includeDone || !block.done)) block,
    ];
    if (victims.isEmpty) return const <TBlock>[];
    final ids = victims.map((b) => b.id).toSet();
    _commit([
      for (final block in _blocks)
        if (!ids.contains(block.id)) block,
    ]);
    state = state.copyWith(selectedId: null);
    for (final id in ids) {
      await _repo.softDelete(id);
    }
    return victims;
  }

  /// 完成：写一条完成记录，方块从当天时间轴消失（记录页仍可回看）
  Future<void> completeSelected() async {

    final block = state.selected;
    if (block == null) return;
    await completeBlock(block.id);
  }

  /// 按 id 完成（手机左滑用；和选中条上的圆钮是同一套逻辑）
  Future<void> completeBlock(String id) async {
    if (!state.canEdit) return;
    final block = _blockOrNull(id);
    if (block == null) return;
    _commit([
      for (final b in _blocks)
        if (b.id != block.id) b,
    ]);
    if (state.selectedId == id) {
      state = state.copyWith(selectedId: null);
    }
    await _library.logCompletion(
      dayBlockId: block.id,
      date: state.dateKey,
      title: block.title,
      lane: block.lane.id,
      startMin: block.startMin,
      durationMin: block.durationMin,
      note: block.note.isEmpty ? null : block.note,
    );
    await _repo.setStatus(block.id, BlockStatus.done);
  }

  void deleteBlock(String id) {
    if (!state.canEdit) return;
    _commit([
      for (final block in _blocks)
        if (block.id != id) block,
    ]);
    if (state.selectedId == id) {
      state = state.copyWith(selectedId: null);
    }
    unawaited(_repo.softDelete(id));
  }

  /// 单条顺延到第二天：复制一份到明天，原方块标记为已顺延。
  /// 返回新建那份的 id（撤销时要用），失败返回 null。
  Future<String?> carryOverToNextDay(String id) async {
    if (!state.canEdit) return null;
    final block = _blockOrNull(id);
    if (block == null) return null;
    final day = DateTime.parse(state.dateKey).add(const Duration(days: 1));
    final nextKey = formatDateKey(day);
    final copy = carryOverBlock(
      block,
      newId: _uuid.v4(),
      sourceDateKey: state.dateKey,
    );
    await _repo.upsert(copy, nextKey);
    await _repo.setStatus(block.id, BlockStatus.carried);
    _commit([
      for (final b in _blocks)
        if (b.id != block.id) b,
    ]);
    state = state.copyWith(selectedId: null);
    return copy.id;
  }

  /// 把方块整条挪到另一天（同 id 改日期，完成记录/顺延链都跟着走）。
  Future<bool> moveToDate(String id, String dateKey) async {
    if (!state.canEdit) return false;
    if (dateKey == state.dateKey) return false;
    final block = _blockOrNull(id);
    if (block == null) return false;
    await _repo.upsert(block, dateKey);
    _commit([..._blocks.where((b) => b.id != id)]);
    return true;
  }
  /// 复制一份到第二天（原方块保持不动）
  Future<void> duplicateToNextDay(String id) async {
    if (!state.canEdit) return;
    final block = _blockOrNull(id);
    if (block == null) return;
    final day = DateTime.parse(state.dateKey).add(const Duration(days: 1));
    final nextKey = formatDateKey(day);
    final copy = TBlock(
      id: _uuid.v4(),
      title: block.title,
      lane: block.lane,
      startMin: block.startMin,
      durationMin: block.durationMin,
      priority: block.priority,
      deadline: block.deadline,
      note: block.note,
    );
    await _repo.upsert(copy, nextKey);
  }

  /// 晚间小结：把今天还没做完的，全部顺延到明天。
  /// 返回顺延的条数。
  Future<int> carryAllUnfinished() async {
    if (!state.canEdit) return 0;
    final today = DateTime.parse(state.dateKey);
    final nextKey = formatDateKey(today.add(const Duration(days: 1)));
    final pending = [
      for (final b in _blocks)
        if (!b.done && b.status == BlockStatus.planned) b,
    ];
    if (pending.isEmpty) return 0;
    final copies = [
      for (final b in pending)
        carryOverBlock(
          b,
          newId: _uuid.v4(),
          sourceDateKey: state.dateKey,
        ),
    ];
    await _repo.upsertAll(copies, nextKey);
    for (final b in pending) {
      await _repo.setStatus(b.id, BlockStatus.carried);
    }
    final ids = {for (final b in pending) b.id};
    _commit([
      for (final b in _blocks)
        if (!ids.contains(b.id)) b,
    ]);
    state = state.copyWith(selectedId: null);
    return copies.length;
  }

  /// 晚间小结：把今天还没做完的全部丢掉（标记 dropped，可从记录里看出）
  Future<int> dropAllUnfinished() async {
    if (!state.canEdit) return 0;
    final pending = [
      for (final b in _blocks)
        if (!b.done && b.status == BlockStatus.planned) b,
    ];
    if (pending.isEmpty) return 0;
    for (final b in pending) {
      await _repo.setStatus(b.id, BlockStatus.dropped);
    }
    final ids = {for (final b in pending) b.id};
    _commit([
      for (final b in _blocks)
        if (!ids.contains(b.id)) b,
    ]);
    state = state.copyWith(selectedId: null);
    return pending.length;
  }

  TBlock? _blockOrNull(String id) {
    for (final block in _blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  /// 顺延弹窗的答复：保留 → 复制到今天；丢弃 → 标记 dropped
  Future<void> resolveCarryOvers({required bool keep}) async {
    if (!state.canEdit) return;
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
    if (!state.canEdit) return 0;
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

  /// 把集合投到指定日期（库页面「选哪天投入」用）；不是今天时只落库不刷当前列表
  Future<int> injectCollectionFor(String dateKey, String collectionId) async {
    if (!state.canEdit) return 0;
    final items = await _library.collectionItems(collectionId);
    final all = blocksFromCollection(collectionId, items, dateKey);
    final sameDay = dateKey == state.dateKey;
    final existing = sameDay
        ? existingInstanceKeys(_blocks)
        : existingInstanceKeys(await _loadDayBlocks(dateKey));
    final created = all
        .where((b) => needsMaterialize(b.instanceGroupId ?? '', existing))
        .toList();
    if (created.isEmpty) return 0;
    await _repo.upsertAll(created, dateKey);
    if (sameDay) {
      _commit([..._blocks, ...created]);
    }
    return created.length;
  }

  Future<List<TBlock>> _loadDayBlocks(String dateKey) async {
    try {
      return await _repo.loadDay(dateKey, includeDone: true);
    } catch (error) {
      debugPrint('TNT: 读取 $dateKey 失败 -> $error');
      return const [];
    }
  }

  void select(String? id) {
    state = state.copyWith(selectedId: id);
  }

  /// 一句话快速添加：直接给齐字段建一条（日期不是今天就只落库不塞进当前列表）
  Future<TBlock?> addBlock({
    required String title,
    required Lane lane,
    required int startMin,
    required int durationMin,
    required Priority priority,
    String? dateKey,
  }) async {
    if (!state.canEdit) return null;
    final key = dateKey ?? state.dateKey;
    final trimmed = title.trim();
    final fitted = clampDuration(startMin, durationMin);
    final block = TBlock(
      id: _uuid.v4(),
      title: trimmed.isEmpty ? '新任务' : trimmed,
      lane: lane,
      startMin: clampStartMinute(startMin, fitted),
      durationMin: fitted,
      priority: priority,
    );
    await _repo.upsert(block, key);
    if (key == state.dateKey) {
      _commit([..._blocks, block]);
      state = state.copyWith(selectedId: block.id);
    }
    return block;
  }

  /// 撤销删除：把方块原样放回来
  Future<void> restoreBlock(TBlock block) async {
    if (!state.canEdit) return;
    await _repo.upsert(block, state.dateKey);
    _commit([..._blocks, block]);
    state = state.copyWith(selectedId: block.id);
  }

  /// 撤销顺延：把原方块原样放回今天，并删掉明天那份
  Future<void> undoCarryOver(TBlock original, String createdNextDayId) async {
    if (!state.canEdit) return;
    final restored = original.copyWith(status: BlockStatus.planned);
    await _repo.upsert(restored, state.dateKey);
    await _repo.softDelete(createdNextDayId);
    _commit([..._blocks, restored]);
    state = state.copyWith(selectedId: restored.id);
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

  /// 请求时间轴滚到某个时刻（分钟）。视图消费一次后调 clearJump()。
  void requestJumpTo(int minute) {
    state = state.copyWith(jumpMinute: minute.clamp(0, kMinutesPerDay));
  }

  void clearJump() {
    if (state.jumpMinute == null) return;
    state = state.copyWith(jumpMinute: null);
  }
  void toggleShowTopInLane() {
    state = state.copyWith(showTopInLane: !state.showTopInLane);
  }

  /// 整条显示/隐藏某条泳道（隐藏后界面不显示、也不参与布局）
  /// 按 id 找泳道（菜单里传的是 id 字符串）
  Lane? laneById(String id) {
    for (final lane in state.lanes) {
      if (lane.id == id) return lane;
    }
    return null;
  }

  void toggleLaneHiddenById(String id) {
    final lane = laneById(id);
    if (lane != null) toggleLaneHidden(lane);
  }

  Future<void> _reloadLanes() async {
    final lanes = await _lanes.all();
    if (_disposed) return;
    final ids = {for (final lane in lanes) lane.id};
    state = state.copyWith(
      lanes: lanes,
      hiddenLanes: {...state.hiddenLanes.where((l) => ids.contains(l.id))},
    );
  }

  Future<void> addLane(String name) async {
    if (!state.canEdit || name.trim().isEmpty) return;
    await _lanes.add(name.trim());
    await _reloadLanes();
    _scheduleReminderSync();
  }

  Future<void> renameLane(String id, String name) async {
    if (!state.canEdit || name.trim().isEmpty) return;
    await _lanes.rename(id, name.trim());
    await _reloadLanes();
  }

  /// 拖动排序：把第 [oldIndex] 条挪到 [newIndex]
  Future<void> reorderLanes(int oldIndex, int newIndex) async {
    if (!state.canEdit) return;
    final lanes = [...state.lanes];
    if (oldIndex < 0 || oldIndex >= lanes.length) return;
    final target = newIndex.clamp(0, lanes.length - 1);
    if (target == oldIndex) return;
    final moved = lanes.removeAt(oldIndex);
    lanes.insert(target, moved);
    await _lanes.reorder(lanes);
    await _reloadLanes();
  }

  Future<int> deleteLane(String id) async {
    if (!state.canEdit) return 0;
    final lanes = state.lanes;
    if (lanes.length <= 1) return -1;
    final target = lanes.firstWhere((lane) => lane.id != id);
    final victims = _blocks.where((block) => block.lane.id == id).toList();
    for (final block in victims) {
      final moved = block.copyWith(lane: target);
      unawaited(_repo.upsert(moved, state.dateKey));
    }
    await _lanes.remove(id);
    await _reloadLanes();
    if (victims.isNotEmpty) {
      _commit([
        for (final block in _blocks)
          if (block.lane.id != id) block else block.copyWith(lane: target),
      ]);
    }
    return victims.length;
  }

  Future<void> resetLanes() async {
    if (!state.canEdit) return;
    await _lanes.resetToDefaults();
    await _reloadLanes();
    state = state.copyWith(hiddenLanes: const <Lane>{});
  }

  void toggleLaneHidden(Lane lane) {
    final next = Set<Lane>.of(state.hiddenLanes);
    if (!next.remove(lane)) next.add(lane);
    final selected = state.selected;
    state = state.copyWith(
      // 隐藏的泳道里如果还有选中的方块，顺手取消选中
      hiddenLanes: next,
      selectedId: (selected != null && next.contains(selected.lane))
          ? null
          : state.selectedId,
    );
  }

  /// 空泳道自动收起的开关
  void toggleAutoHideEmptyLanes() {
    state = state.copyWith(autoHideEmptyLanes: !state.autoHideEmptyLanes);
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
    return switch (lane.id) {
      'daily' => '新日常',
      'habit' => '新打卡',
      'temp' => '新事件',
      _ => '新任务',
    };
  }

  // ── 示例数据 ───────────────────────────────────────────────
  /// 第一次启动时给两个集合和一个长期计划，让 S3 的功能一进来就能看见
  Future<void> _seedLibrary() async {
    if ((await _library.collections()).isNotEmpty) return;
    await _library.createCollectionSimple(
      name: '早间流程',
      id: 'seed-coll-morning',
      itemIdPrefix: 'seed-coll-morning-item',
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
      id: 'seed-coll-evening',
      itemIdPrefix: 'seed-coll-evening-item',
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
      id: 'seed-plan-english',
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
    String? id,
    Duration? deadline,
    DateTime? now,
  }) {
    return TBlock(
      id: id ?? _uuid.v4(),
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
      _block('喂猫', Lane.daily, 7, 10, 15, Priority.d, id: 'seed-cat'),
      _block('早餐', Lane.daily, 7, 40, 30, Priority.c, id: 'seed-breakfast'),
      _block('洗衣服', Lane.daily, 12, 0, 40, Priority.d, id: 'seed-laundry'),
      _block('午饭', Lane.daily, 12, 40, 45, Priority.c, id: 'seed-lunch'),
      _block('晚饭', Lane.daily, 18, 30, 45, Priority.c, id: 'seed-dinner'),
      _block('洗澡', Lane.daily, 21, 30, 25, Priority.d, id: 'seed-shower'),

      // ② 长期任务打卡（含一处重叠：阅读 vs 线上会议）
      _block('阅读', Lane.habit, 14, 0, 60, Priority.c, id: 'seed-reading'),
      _block('线上会议', Lane.habit, 14, 20, 45, Priority.c, id: 'seed-meeting'),
      _block('健身', Lane.habit, 16, 30, 60, Priority.d, id: 'seed-gym'),
      _block('复盘日记', Lane.habit, 20, 30, 20, Priority.c, id: 'seed-review'),
      _block('冥想', Lane.habit, 22, 30, 15, Priority.d, id: 'seed-meditate'),

      // ③ 平时没有、A 级或临近死线才出现的临时事件
      _block('交周报', Lane.temp, 10, 30, 60, Priority.a, id: 'seed-weekly'),
      _block(
        '回复邮件',
        Lane.temp,
        10,
        45,
        30,
        Priority.b,
        id: 'seed-email',
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
        id: 'seed-bug',
        deadline: const Duration(hours: 20),
        now: now,
      ),
    ];
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);
