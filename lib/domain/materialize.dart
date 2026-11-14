/// 物化与顺延的纯逻辑：不碰数据库、不 import flutter，单测直接调。
library;

import 'models/tblock.dart';

/// 长期计划某天的物化幂等键。同一天重复进入时间轴只会生成一次。
String planInstanceKey(String planId, String dateKey) =>
    'plan:$planId@$dateKey';

/// 集合整包投入的幂等键（一天可以投一次，重复投入不会叠两份）
String collectionInstanceKey(String collectionId, String dateKey, int index) =>
    'collection:$collectionId@$dateKey#$index';

/// 这个幂等键是不是已经有对应方块了
bool needsMaterialize(String instanceKey, Set<String> existingKeys) =>
    !existingKeys.contains(instanceKey);

/// 这一天已经物化了哪些来源（用 set 做幂等判断）
Set<String> existingInstanceKeys(Iterable<TBlock> blocks) => {
  for (final block in blocks)
    if (block.instanceGroupId != null) block.instanceGroupId!,
};

/// 顺延：把昨天没做完的方块复制到今天
///
/// - 保留原时段、时长、优先级、死线（死线是绝对时间，过期后 UI 会显示「已超时」）
/// - 记下 fromBlockId 与 originalDate，顺延次数 +1
/// - 状态回到 planned，done 归零
TBlock carryOverBlock(
  TBlock source, {
  required String newId,
  required String sourceDateKey,
}) {
  return TBlock(
    id: newId,
    title: source.title,
    lane: source.lane,
    startMin: source.startMin,
    durationMin: source.durationMin,
    priority: source.priority,
    deadline: source.deadline,
    note: source.note,
    sourceType: source.sourceType,
    sourceId: source.sourceId,
    fromBlockId: source.id,
    carryCount: source.carryCount + 1,
    originalDate: source.originalDate ?? sourceDateKey,
  );
}

/// 要不要在打开今天的时候问用户「昨天这些没做完，顺延还是丢掉」
bool needsCarryPrompt(TBlock block) =>
    block.status == BlockStatus.planned && !block.done;
