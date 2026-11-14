/// 领域模型：一天的方块。纯 Dart，不依赖 Flutter，方便单测。
library;

/// 三条泳道。方块**永远**属于其中一条，置顶只是投影，不改归属。
enum Lane {
  /// ① 日常琐事：喂猫、洗衣、做饭
  daily,

  /// ② 长期任务打卡：学英语、健身
  habit,

  /// ③ 临时：平时没有，出现了 A 级或临近死线的 B 级才进来
  temp;

  String get label => switch (this) {
    Lane.daily => '日常',
    Lane.habit => '打卡',
    Lane.temp => '临时',
  };

  static Lane byIndex(int index) =>
      Lane.values[index.clamp(0, Lane.values.length - 1)];
}

/// 用户手动设定的分类，不是最终优先级
enum Priority {
  /// A 非常重要
  a,

  /// B 有时间限定（死线）
  b,

  /// C 普通
  c,

  /// D 轻松
  d;

  String get label => switch (this) {
    Priority.a => 'A',
    Priority.b => 'B',
    Priority.c => 'C',
    Priority.d => 'D',
  };

  /// A -> B -> C -> D -> A
  Priority get next => Priority.values[(index + 1) % Priority.values.length];
}

/// 方块从哪来
enum BlockSource {
  /// 手动放的
  manual,

  /// 从模板放的
  template,

  /// 集合整包投入的
  collection,

  /// 长期计划物化出来的
  plan;

  static BlockSource byIndex(int index) =>
      BlockSource.values[index.clamp(0, BlockSource.values.length - 1)];
}

/// 方块的状态机：planned → done / carried（顺延走了）/ dropped（不要了）
enum BlockStatus {
  planned,
  done,

  /// 已经顺延到后面的某天（原位置只留一条状态, 不再重复询问）
  carried,

  /// 用户选择丢弃
  dropped;

  static BlockStatus byIndex(int index) =>
      BlockStatus.values[index.clamp(0, BlockStatus.values.length - 1)];

  /// 还需要在今天的时间轴上出现吗
  bool get isActive => this == BlockStatus.planned;
}

/// 时间轴上的一个方块
class TBlock {
  const TBlock({
    required this.id,
    required this.title,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    this.priority = Priority.c,
    this.deadline,
    this.done = false,
    this.note = '',
    this.sourceType = BlockSource.manual,
    this.sourceId,
    this.instanceGroupId,
    this.fromBlockId,
    this.carryCount = 0,
    this.originalDate,
    this.status = BlockStatus.planned,
  });

  final String id;
  final String title;

  /// 归属泳道（置顶不改变它）
  final Lane lane;

  /// 开始时刻，0..1439
  final int startMin;

  /// 时长（分钟）
  final int durationMin;

  final Priority priority;

  /// 死线，只有 B 级用得到；为空表示没有死线
  final DateTime? deadline;

  final bool done;
  final String note;

  // ── 溯源（为物化幂等、顺延链、同步合并准备）──────────────────
  final BlockSource sourceType;
  final String? sourceId;

  /// 物化幂等键，例如 `plan:<id>@2026-11-13`
  final String? instanceGroupId;

  /// 顺延自哪个方块
  final String? fromBlockId;

  /// 顺延了几次
  final int carryCount;

  /// 最早属于哪一天（yyyy-MM-dd）
  final String? originalDate;

  final BlockStatus status;

  int get endMin => startMin + durationMin;

  /// 顺延过的方块给个标记，方便 UI 提示
  bool get isCarried => carryCount > 0;

  TBlock copyWith({
    String? title,
    Lane? lane,
    int? startMin,
    int? durationMin,
    Priority? priority,
    Object? deadline = _sentinel,
    bool? done,
    String? note,
    BlockSource? sourceType,
    Object? sourceId = _sentinel,
    Object? instanceGroupId = _sentinel,
    Object? fromBlockId = _sentinel,
    int? carryCount,
    Object? originalDate = _sentinel,
    BlockStatus? status,
  }) {
    return TBlock(
      id: id,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      startMin: startMin ?? this.startMin,
      durationMin: durationMin ?? this.durationMin,
      priority: priority ?? this.priority,
      deadline: identical(deadline, _sentinel)
          ? this.deadline
          : deadline as DateTime?,
      done: done ?? this.done,
      note: note ?? this.note,
      sourceType: sourceType ?? this.sourceType,
      sourceId: identical(sourceId, _sentinel)
          ? this.sourceId
          : sourceId as String?,
      instanceGroupId: identical(instanceGroupId, _sentinel)
          ? this.instanceGroupId
          : instanceGroupId as String?,
      fromBlockId: identical(fromBlockId, _sentinel)
          ? this.fromBlockId
          : fromBlockId as String?,
      carryCount: carryCount ?? this.carryCount,
      originalDate: identical(originalDate, _sentinel)
          ? this.originalDate
          : originalDate as String?,
      status: status ?? this.status,
    );
  }

  @override
  String toString() => 'TBlock($title, ${lane.label}, $startMin+$durationMin)';
}

const Object _sentinel = Object();
