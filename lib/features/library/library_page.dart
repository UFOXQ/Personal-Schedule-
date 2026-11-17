import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';
import '../plans/plan_editor_sheet.dart';
import '../plans/plans_page.dart';
import '../timeline/timeline_state.dart';
import 'collection_editor_sheet.dart';

/// 库里的一包东西：合集（可整包投放）+ 它现在的条目
final collectionsProvider = FutureProvider.autoDispose<
    List<({Collection collection, int count, String preview})>>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final rows = await repo.collections();
  final result = <({Collection collection, int count, String preview})>[];
  for (final row in rows) {
    final items = await repo.collectionSeeds(row.id);
    final preview = items.isEmpty
        ? '空集合'
        : items
              .take(3)
              .map((i) => '${formatMinute(i.startMin)} ${i.title}')
              .join(' · ');
    result.add((collection: row, count: items.length, preview: preview));
  }
  return result;
});

/// 「库」：合集 + 重复任务（长期计划），建好之后一键投到某一天。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(collectionsProvider);
    ref.invalidate(plansProvider);
  }

  Future<void> _inject(String collectionId, String name) async {
    final count = await ref
        .read(timelineProvider.notifier)
        .injectCollection(collectionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count > 0 ? '把「$name」投到了今天（$count 件事）' : '「$name」今天已经投过了',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// 选日期投入：默认今天，也可以投到别的天（比如明天早上）
  Future<void> _injectOnDate(String collectionId, String name) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '把这套投入哪天',
    );
    if (picked == null || !mounted) return;
    final key = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    final count =
        await ref.read(timelineProvider.notifier).injectCollectionFor(key, collectionId);
    if (!mounted) return;
    final when = picked.month == DateTime.now().month &&
            picked.day == DateTime.now().day
        ? '今天'
        : '${picked.month}/${picked.day}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count > 0 ? '把「$name」投到了$when（$count 件事）' : '「$name」$when已经投过了',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _editCollection({String? id}) async {
    final saved = await showCollectionEditor(context, collectionId: id);
    if (saved == true) _refresh();
  }

  Future<void> _editPlan({Plan? plan}) async {
    final saved = await showPlanEditor(context, plan: plan);
    if (saved != true) return;
    _refresh();
    await ref.read(timelineProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bg,
        title: const Text('库', style: TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Palette.textPrimary,
          unselectedLabelColor: Palette.textDim,
          indicatorColor: Palette.accent,
          dividerColor: Palette.line,
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13.5),
          tabs: const [Tab(text: '合集'), Tab(text: '重复任务')],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [_collectionsTab(), _plansTab()],
        ),
      ),
    );
  }

  Widget _collectionsTab() {
    final rows = ref.watch(collectionsProvider);
    return Stack(
      children: [
        rows.when(
          loading: () => const _Loading(),
          error: (error, _) => _ErrorText('$error'),
          data: (list) {
            if (list.isEmpty) return const _EmptyCollections();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = list[index];
                return _CollectionCard(
                  name: row.collection.name,
                  count: row.count,
                  preview: row.preview,
                  onInject: () => _inject(row.collection.id, row.collection.name),
                onInjectDate: () =>
                    _injectOnDate(row.collection.id, row.collection.name),
                  onEdit: () => _editCollection(id: row.collection.id),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _editCollection(),
            backgroundColor: Palette.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('新建合集'),
          ),
        ),
      ],
    );
  }

  Widget _plansTab() {
    final rows = ref.watch(plansProvider);
    return Stack(
      children: [
        rows.when(
          loading: () => const _Loading(),
          error: (error, _) => _ErrorText('$error'),
          data: (list) {
            if (list.isEmpty) return const _EmptyPlansHint();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final plan = list[index];
                return PlanTile(
                  plan: plan,
                  onTap: () => _editPlan(plan: plan),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _editPlan(),
            backgroundColor: Palette.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('新建重复任务'),
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.name,
    required this.count,
    required this.preview,
    required this.onInject,
    required this.onInjectDate,
    required this.onEdit,
  });

  final String name;
  final int count;
  final String preview;
  final VoidCallback onInject;
  final VoidCallback onInjectDate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count 件',
                style: TextStyle(
                  color: Palette.textDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Palette.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CollectionActionChip(
                icon: Icons.playlist_add,
                label: '投入今天',
                tint: Palette.accent,
                onTap: onInject,
              ),
              const SizedBox(width: 8),
              CollectionActionChip(
                icon: Icons.event_outlined,
                label: '选哪天',
                onTap: onInjectDate,
              ),
              const SizedBox(width: 8),
              CollectionActionChip(
                icon: Icons.edit_outlined,
                label: '编辑',
                onTap: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        style: TextStyle(color: Palette.textDim, fontSize: 12),
      ),
    ),
  );
}

class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          '还没有合集。\n把「早间流程」「健身包」这种排好的几件事存成一包，\n以后一键就能投到某一天。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.textDim, fontSize: 12, height: 1.6),
        ),
      ),
    );
  }
}

class _EmptyPlansHint extends StatelessWidget {
  const _EmptyPlansHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          '还没有重复任务。\n像「学英语 11/1–12/31 每天 9:00」这种，\n建一条就会自动铺到每一天的时间轴上。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.textDim, fontSize: 12, height: 1.6),
        ),
      ),
    );
  }
}
