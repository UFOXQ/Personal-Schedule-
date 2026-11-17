import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/weekday.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../domain/models/tblock.dart';
import '../../data/providers.dart';
import '../timeline/timeline_state.dart';
import '../../data/repositories/inbox_repository.dart';
import '../../data/repositories/library_repository.dart';
import '../library/collection_editor_sheet.dart';
import '../library/library_page.dart';
import '../timeline/quick_add_sheet.dart';

/// 收件箱（组合台的「待安排」）：落库，关掉页面也不会丢。
final inboxProvider = FutureProvider.autoDispose<List<InboxItem>>((ref) {
  return ref.watch(inboxRepositoryProvider).items();
});

/// 组合台：把「还没安排的小任务」拖进「合集」，再把合集投到某一天。
///
/// 布局有列表 / 方块两种，切换按钮在右上角。
class ComposerPage extends ConsumerStatefulWidget {
  const ComposerPage({super.key, this.startInGrid = false});

  final bool startInGrid;

  @override
  ConsumerState<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends ConsumerState<ComposerPage> {
  late bool _grid = widget.startInGrid;

  InboxRepository get _inbox => ref.read(inboxRepositoryProvider);

  Future<void> _addDraft() async {
    final draft = await showQuickAddSheet(context);
    if (!mounted || draft == null) return;
    await _inbox.add(
      title: draft.title,
      lane: draft.lane,
      startMin: draft.startMin,
      durationMin: draft.durationMin,
      priority: draft.priority,
      day: formatDateKey(draft.day),
    );
    if (!mounted) return;
    ref.invalidate(inboxProvider);
  }

  /// 把一条收件箱任务直接放到今天（不进合集）
  /// 左滑删除收件箱条目（拖出去安排是主路径，这里给「不要了」留个快捷方式）
  Future<void> _removeInbox(InboxItem item) async {
    await _inbox.remove(item.id);
    ref.invalidate(inboxProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已从收件箱移除「${item.title}」'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _dropToToday(InboxItem item) async {
    final start = item.startMin ?? _defaultStartMin();
    final created = await ref.read(timelineProvider.notifier).addBlock(
          title: item.title,
          lane: Lane(id: item.lane, name: item.lane),
          startMin: start,
          durationMin: item.durationMin,
          priority: Priority.byIndex(item.priority),
          dateKey: formatDateKey(DateTime.now()),
        );
    if (!mounted) return;
    if (created == null) {
      _toast('加不进去：现在是锁定状态');
      return;
    }
    await _inbox.remove(item.id);
    if (!mounted) return;
    ref.invalidate(inboxProvider);
    _toast('「${item.title}」放到今天了');
  }

  /// 没有指定时间时，落到「下一个半点」
  int _defaultStartMin() {
    final now = DateTime.now();
    final next = now.hour * 60 + now.minute;
    return ((next ~/ 30) + 1) * 30 % kMinutesPerDay;
  }

  /// 把一条任务塞进某个合集
  Future<void> _dropIntoCollection(InboxItem item, String collectionId) async {
    final repo = ref.read(libraryRepositoryProvider);
    final seeds = await repo.collectionSeeds(collectionId);
    // 同名同时段的不重复加
    final duplicated = seeds.any(
      (seed) => seed.title == item.title && seed.startMin == item.startMin,
    );
    if (duplicated) {
      if (!mounted) return;
      _toast('「${item.title}」已经在这个合集里了');
      return;
    }
    final name = await _collectionName(collectionId);
    await repo.updateCollection(
      id: collectionId,
      name: name,
      items: [
        ...seeds,
        CollectionSeedItem(
          title: item.title,
          lane: Lane(id: item.lane, name: item.lane),
          startMin: item.startMin ?? _defaultStartMin(),
          durationMin: item.durationMin,
          priority: Priority.byIndex(item.priority),
        ),
      ],
    );
    await _inbox.remove(item.id);
    if (!mounted) return;
    ref.invalidate(inboxProvider);
    ref.invalidate(collectionsProvider);
    _toast('「${item.title}」收进「$name」了');
  }

  Future<String> _collectionName(String collectionId) async {
    final rows = await ref.read(libraryRepositoryProvider).collections();
    for (final row in rows) {
      if (row.id == collectionId) return row.name;
    }
    return '合集';
  }

  /// 长按合集：选一天，把整套投过去
  Future<void> _invest(String collectionId, String name) async {
    final picked = await showDateStripSheet(context);
    if (!mounted || picked == null) return;
    final key = formatDateKey(picked);
    final count =
        await ref.read(timelineProvider.notifier).injectCollectionFor(key, collectionId);
    if (!mounted) return;
    final today = formatDateKey(DateTime.now());
    final when = key == today ? '今天' : '${picked.month}/${picked.day}';
    _toast(count > 0 ? '把「$name」投到$when（$count 件）' : '「$name」$when已经投过了');
    if (key == today) {
      await ref.read(timelineProvider.notifier).reload();
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final inboxAsync = ref.watch(inboxProvider);

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bg,
        surfaceTintColor: Colors.transparent,
        title: const Text('组合台', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            tooltip: _grid ? '换成列表' : '换成方块',
            icon: Icon(
              _grid ? Icons.view_list_outlined : Icons.grid_view_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          IconButton(
            tooltip: '新建合集',
            icon: const Icon(Icons.library_add_outlined, size: 20),
            onPressed: () async {
              await showCollectionEditor(context);
              ref.invalidate(collectionsProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDraft,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('新任务'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 96),
        children: [
          _sectionTitle(
            '待安排',
            trailing: inboxAsync.maybeWhen(
              data: (rows) =>
                  rows.isEmpty ? null : Text('${rows.length} 个', style: _hint),
              orElse: () => null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点右下「新任务」写一条，写好之后可以拖进下面的合集，也可以点一下直接放到今天。'
            '关掉这个页面也不会丢。',
            style: _hint,
          ),
          const SizedBox(height: 10),
          inboxAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, _) => Text('读不到收件箱：$error', style: _hint),
            data: (rows) {
              if (rows.isEmpty) {
                return _emptyBox('还没有待安排的任务');
              }
              return _grid
                  ? _DraftGrid(items: rows, onTap: _dropToToday)
                  : Column(
                      children: [
                        for (final item in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Palette.top.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onDismissed: (_) => _removeInbox(item),
                              child: _DraftTile(
                                item: item,
                                onTap: () => _dropToToday(item),
                              ),
                            ),
                          ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 22),
          _sectionTitle('合集', trailing: Text('长按投到某天', style: _hint)),
          const SizedBox(height: 8),
          collectionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, _) => Text('读不到合集：$error', style: _hint),
            data: (rows) {
              if (rows.isEmpty) {
                return _emptyBox('还没有合集，点右上角「新建合集」');
              }
              return Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CollectionDropCard(
                        name: row.collection.name,
                        count: row.count,
                        preview: row.preview,
                        onDrop: (item) =>
                            _dropIntoCollection(item, row.collection.id),
                        onLongPress: () =>
                            _invest(row.collection.id, row.collection.name),
                        onTap: () async {
                          await showCollectionEditor(
                            context,
                            collectionId: row.collection.id,
                          );
                          ref.invalidate(collectionsProvider);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: Palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }

  static final TextStyle _hint = TextStyle(
    color: Palette.textSecondary,
    fontSize: 11,
    height: 1.5,
  );

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.lineFaint),
      ),
      child: Center(child: Text(text, style: _hint)),
    );
  }
}

/// 一条待安排任务（列表布局）
class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priority = Priority.byIndex(item.priority);
    final lane = Lane(id: item.lane, name: item.lane);
    final color = Palette.of(priority);
    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.startMin == null
                      ? '还没定时间 · ${priority.label} 级 · ${lane.name}'
                      : '${formatRange(item.startMin!, item.durationMin)} · '
                          '${priority.label} 级 · ${lane.name}',
                  style: TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.drag_indicator, size: 16, color: Palette.textDim),
        ],
      ),
    );
    return LongPressDraggable<InboxItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.9, child: SizedBox(width: 220, child: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// 方块布局：小方块排成一行行，同样可以拖
class _DraftGrid extends StatelessWidget {
  const _DraftGrid({required this.items, required this.onTap});

  final List<InboxItem> items;
  final ValueChanged<InboxItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          LongPressDraggable<InboxItem>(
            data: item,
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(opacity: 0.9, child: _DraftSquare(item: item, wide: 96)),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: _DraftSquare(item: item),
            ),
            child: _DraftSquare(item: item, onTap: () => onTap(item)),
          ),
      ],
    );
  }
}

class _DraftSquare extends StatelessWidget {
  const _DraftSquare({required this.item, this.onTap, this.wide});

  final InboxItem item;
  final VoidCallback? onTap;
  final double? wide;

  @override
  Widget build(BuildContext context) {
    final priority = Priority.byIndex(item.priority);
    final color = Palette.of(priority);
    final width = wide ?? 86.0;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: width,
        height: 74,
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              item.startMin == null ? '待定' : formatMinute(item.startMin!),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 可以接住拖拽的合集卡片；长按选日期
class _CollectionDropCard extends StatefulWidget {
  const _CollectionDropCard({
    required this.name,
    required this.count,
    required this.preview,
    required this.onDrop,
    required this.onLongPress,
    required this.onTap,
  });

  final String name;
  final int count;
  final String preview;
  final ValueChanged<InboxItem> onDrop;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  @override
  State<_CollectionDropCard> createState() => _CollectionDropCardState();
}

class _CollectionDropCardState extends State<_CollectionDropCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: _hovering
            ? Palette.accent.withValues(alpha: 0.16)
            : Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hovering ? Palette.accent : Palette.lineFaint,
          width: _hovering ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: Palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Palette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.count} 件',
                      style: TextStyle(
                        color: Palette.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _hovering ? '松手就收进这个合集' : widget.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hovering ? Palette.accent : Palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return DragTarget<InboxItem>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovering = false);
        widget.onDrop(details.data);
      },
      builder: (context, _, _) => GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}

/// 选一天：给未来两周的紧凑网格，下面还有「换个月」
Future<DateTime?> showDateStripSheet(BuildContext context) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Palette.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _DateStripSheet(),
  );
}

class _DateStripSheet extends StatelessWidget {
  const _DateStripSheet();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (index) => today.add(Duration(days: index)));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Palette.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '投到哪天',
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in days)
                  _DayChip(
                    day: day,
                    isToday: day.day == today.day && day.month == today.month,
                    onTap: () => Navigator.of(context).pop(day),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: today,
                  firstDate: today.subtract(const Duration(days: 365)),
                  lastDate: today.add(const Duration(days: 365)),
                );
                if (picked != null && context.mounted) {
                  Navigator.of(context).pop(picked);
                }
              },
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('换个月'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = kWeekdayLabels[day.weekday - 1];
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isToday
              ? Palette.accent.withValues(alpha: 0.18)
              : Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? Palette.accent : Palette.lineFaint,
          ),
        ),
        child: Column(
          children: [
            Text(
              weekday,
              style: TextStyle(color: Palette.textDim, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? Palette.accent : Palette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
