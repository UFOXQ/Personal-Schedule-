/// 把「模板 / 集合 / 长期计划」变成某天的方块。这里是数据层，可以碰 Drift 行对象。
library;

import 'package:uuid/uuid.dart';

import '../domain/materialize.dart';
import '../domain/models/tblock.dart';
import 'db/tnt_database.dart';

const Uuid _uuid = Uuid();

/// 长期计划 → 今天的方块。已有同键方块时返回空列表（幂等）。
List<TBlock> blocksFromPlan(
  Plan plan,
  String dateKey,
  Set<String> existingKeys,
) {
  final key = planInstanceKey(plan.id, dateKey);
  if (!needsMaterialize(key, existingKeys)) return const [];
  return [
    TBlock(
      id: _uuid.v4(),
      title: plan.title,
      lane: Lane.byIndex(plan.lane),
      startMin: plan.startMin,
      durationMin: plan.durationMin,
      priority:
          Priority.values[plan.priority.clamp(0, Priority.values.length - 1)],
      note: plan.note ?? '',
      sourceType: BlockSource.plan,
      sourceId: plan.id,
      instanceGroupId: key,
    ),
  ];
}

/// 集合 → 今天的方块（整包投入）
List<TBlock> blocksFromCollection(
  String collectionId,
  List<CollectionItem> items,
  String dateKey,
) {
  return [
    for (var i = 0; i < items.length; i++)
      TBlock(
        id: _uuid.v4(),
        title: items[i].title,
        lane: Lane.byIndex(items[i].lane),
        startMin: items[i].startMin,
        durationMin: items[i].durationMin,
        priority: Priority
            .values[items[i].priority.clamp(0, Priority.values.length - 1)],
        sourceType: BlockSource.collection,
        sourceId: collectionId,
        instanceGroupId: collectionInstanceKey(collectionId, dateKey, i),
      ),
  ];
}
