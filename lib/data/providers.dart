import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/tnt_database.dart';
import 'repositories/day_block_repository.dart';
import 'repositories/inbox_repository.dart';
import 'repositories/lane_repository.dart';
import 'repositories/library_repository.dart';

/// 全局唯一的数据库句柄。App 退出时关闭。
final databaseProvider = Provider<TntDatabase>((ref) {
  final db = TntDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 某天时间轴方块的读写
final dayBlockRepositoryProvider = Provider<DayBlockRepository>((ref) {
  return DayBlockRepository(ref.watch(databaseProvider));
});

/// 模板 / 集合 / 长期计划 / 完成记录
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(databaseProvider));
});

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(ref.watch(databaseProvider));
});

/// 自定义泳道
final laneRepositoryProvider = Provider<LaneRepository>((ref) {
  return LaneRepository(ref.watch(databaseProvider));
});
