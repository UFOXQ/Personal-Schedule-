import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';

/// 集合选择面板：返回被点中的集合 id，由调用方负责「投入今天」
Future<String?> showCollectionsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _CollectionsSheet(),
  );
}

class _CollectionsSheet extends ConsumerWidget {
  const _CollectionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: FutureBuilder<List<Collection>>(
          future: ref.read(libraryRepositoryProvider).collections(),
          builder: (context, snapshot) {
            final collections = snapshot.data ?? const <Collection>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '把集合整包投入今天',
                  style: TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '集合是排好时段的重复任务，投进来就是一串方块',
                  style: TextStyle(color: Palette.textDim, fontSize: 11),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (collections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      '还没有集合。后面在模板页可以建（如「晚间收尾」）。',
                      style: TextStyle(
                        color: Palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: collections.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Palette.line),
                      itemBuilder: (context, index) {
                        final collection = collections[index];
                        return _CollectionTile(collection: collection);
                      },
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(collection.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Palette.accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FutureBuilder<List<CollectionItem>>(
                future: ref
                    .read(libraryRepositoryProvider)
                    .collectionItems(collection.id),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <CollectionItem>[];
                  final preview = items
                      .take(3)
                      .map((i) => '${formatMinute(i.startMin)} ${i.title}')
                      .join(' · ');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        style: const TextStyle(
                          color: Palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items.isEmpty
                            ? '空集合'
                            : '${items.length} 个方块 · $preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              color: Palette.textDim,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
