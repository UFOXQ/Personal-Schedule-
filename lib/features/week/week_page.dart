import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../data/providers.dart';
import '../../data/materialize.dart';
import '../../data/repositories/library_repository.dart' show formatDateKey;
import '../../domain/calendar/week_row.dart';
import '../../domain/models/day_jump.dart';
import '../../domain/materialize.dart';
import '../../domain/models/tblock.dart';

/// 某一天的方块（按日期分组取回）。
///
/// 时间轴是「访问某天才物化那天的长期计划」，所以周视图不能只查库，
/// 否则未来的天数会显示 0 件。这里把还没落库的计划实例算进去（只读预览，不写库）。
final weekBlocksProvider = FutureProvider.autoDispose
    .family<Map<String, List<TBlock>>, DateTime>((ref, anchor) async {
      final days = weekDays(anchor);
      final start = formatDateKey(days.first);
      final end = formatDateKey(days.last);
      final repo = ref.watch(dayBlockRepositoryProvider);
      final library = ref.watch(libraryRepositoryProvider);
      final grouped = await repo.blocksInRange(start, end);

      for (final day in days) {
        final key = formatDateKey(day);
        final existing = grouped[key] ?? const <TBlock>[];
        final keys = existingInstanceKeys(existing);
        final virtual = <TBlock>[];
        for (final plan in await library.plansOn(day)) {
          virtual.addAll(blocksFromPlan(plan, key, keys));
        }
        if (virtual.isNotEmpty) {
          grouped[key] = [...existing, ...virtual]..sort(
            (a, b) => a.startMin.compareTo(b.startMin),
          );
        }
      }
      return grouped;
    });

/// 周视图：7 行，每行一条 24 小时概览条，点一行就跳到那天的轴。
class WeekPage extends ConsumerStatefulWidget {
  const WeekPage({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  ConsumerState<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends ConsumerState<WeekPage> {
  late DateTime _anchor = widget.initialDate;

  void _shiftWeek(int delta) {
    setState(() {
      _anchor = _anchor.add(Duration(days: delta * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = weekDays(_anchor);
    final data = ref.watch(weekBlocksProvider(_anchor));
    final todayKey = formatDateKey(DateTime.now());

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bg,
        elevation: 0,
        foregroundColor: Palette.textPrimary,
        title: Text(
          '${_anchor.year} 年 ${_anchor.month} 月 · 本周',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: '上一周',
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: '下一周',
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: '回到本周',
            onPressed: () => setState(() => _anchor = DateTime.now()),
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '读取失败：$error',
            style: TextStyle(color: Palette.textDim, fontSize: 12),
          ),
        ),
        data: (grouped) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final day = days[index];
            final key = formatDateKey(day);
            return _WeekRow(
              day: day,
              blocks: grouped[key] ?? const <TBlock>[],
              isToday: key == todayKey,
              onTap: () => Navigator.of(context).pop<DayJump>((
                date: key,
                minute: null,
              )),
              onSegmentTap: (minute) => Navigator.of(context).pop<DayJump>((
                date: key,
                minute: minute,
              )),
            );
          },
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.day,
    required this.blocks,
    required this.isToday,
    required this.onTap,
    required this.onSegmentTap,
  });

  final DateTime day;
  final List<TBlock> blocks;
  final bool isToday;
  final VoidCallback onTap;
  final ValueChanged<int> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final segments = weekSegments(blocks);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? Palette.top.withValues(alpha: 0.55) : Palette.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  weekDayLabel(day),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Palette.top : Palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${blocks.length} 件',
                  style: TextStyle(
                    fontSize: 11,
                    color: Palette.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Palette.textDim,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return SizedBox(
                  height: 14,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Palette.laneBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Palette.lineFaint),
                        ),
                      ),
                      for (final segment in segments)
                        Positioned(
                          left: segment.left * width,
                          width: (segment.width * width).clamp(3.0, width),
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSegmentTap(segment.startMin),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: Palette.ofBlock(
                                  _dummy(segment),
                                  segment.isTop,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      // 每 6 小时一根浅刻度
                      for (var i = 1; i < 4; i++)
                        Positioned(
                          left: width * i / 4,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 1, color: Palette.lineFaint),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Palette.ofBlock 需要 TBlock，这里给个只带 priority 的临时对象。
  TBlock _dummy(WeekSegment segment) => TBlock(
    id: segment.title,
    title: segment.title,
    lane: Lane.daily,
    startMin: 0,
    durationMin: 1,
    priority: segment.priority,
  );
}
