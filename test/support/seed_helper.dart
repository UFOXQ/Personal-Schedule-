import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

/// 新版 App 首次启动不再自动灌示例数据，测试里自己放几条当代替。
Future<void> seedTimeline(ProviderContainer container) async {
  final notifier = container.read(timelineProvider.notifier);
  final first = notifier.addBlockAt(lane: Lane.daily, startMin: 9 * 60);
  final second = notifier.addBlockAt(lane: Lane.habit, startMin: 10 * 60);
  notifier.addBlockAt(lane: Lane.temp, startMin: 11 * 60);
  for (var i = 0; i < 40; i++) {
    if (container.read(timelineProvider).blocks.length >= 3) break;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  if (second != null) {
    notifier.updateBlock(
      second.id,
      deadline: DateTime.now().add(const Duration(hours: 20)),
    );
  }
  if (first != null) await Future<void>.delayed(const Duration(milliseconds: 20));
  final lib = container.read(libraryRepositoryProvider);
  if ((await lib.collections()).isEmpty) {
    await lib.createCollectionSimple(
      name: '早间流程',
      items: const [
        CollectionSeedItem(title: '喂猫', lane: Lane.habit, startMin: 430, durationMin: 15),
        CollectionSeedItem(title: '早餐', lane: Lane.daily, startMin: 460, durationMin: 30),
      ],
    );
  }
}
