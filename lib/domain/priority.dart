/// 优先级是**派生量**：用户只填 A/B/C/D 和死线，排到哪一档由这里算。
/// 规则改动不需要迁移数据库。
library;

import 'models/tblock.dart';

/// 死线前多少小时，B 级自动升格为最高优先级。先写死，后面放进设置页。
const Duration kDeadlinePromoteWindow = Duration(hours: 48);

/// 是否属于「最高优先级」：A 级，或者进入死线窗口的 B 级。
bool isTopPriority(TBlock block, DateTime now) {
  if (block.done) return false;
  switch (block.priority) {
    case Priority.a:
      return true;
    case Priority.b:
      final deadline = block.deadline;
      if (deadline == null) return false;
      return deadline.difference(now) <= kDeadlinePromoteWindow;
    case Priority.c:
    case Priority.d:
      return false;
  }
}

/// 排序权重，数字越小越靠前。同档内按死线远近、再按开始时间。
int priorityRank(TBlock block, DateTime now) {
  if (isTopPriority(block, now)) return 0; // A 与临近死线的 B 同级
  return switch (block.priority) {
    Priority.b => 1,
    Priority.c => 2,
    Priority.d => 3,
    Priority.a => 0,
  };
}

/// 距离死线还有多久；无死线返回 null
Duration? timeToDeadline(TBlock block, DateTime now) =>
    block.deadline?.difference(now);

/// 死线紧急度文案
String deadlineLabel(TBlock block, DateTime now) {
  final left = timeToDeadline(block, now);
  if (left == null) return '';
  if (left.isNegative) return '已超时';
  if (left.inMinutes < 60) return '剩 ${left.inMinutes} 分钟';
  if (left.inHours < 24) return '剩 ${left.inHours} 小时';
  return '剩 ${left.inDays} 天';
}

/// 按优先级排序（置顶优先 → 死线近的优先 → 开始早的优先）
List<TBlock> sortByPriority(Iterable<TBlock> blocks, DateTime now) {
  final list = blocks.toList();
  list.sort((a, b) {
    final ra = priorityRank(a, now);
    final rb = priorityRank(b, now);
    if (ra != rb) return ra.compareTo(rb);
    final da = a.deadline;
    final db = b.deadline;
    if (da != null && db != null) {
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
    } else if (da != null) {
      return -1;
    } else if (db != null) {
      return 1;
    }
    return a.startMin.compareTo(b.startMin);
  });
  return list;
}
