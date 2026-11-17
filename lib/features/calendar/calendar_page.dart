import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../domain/models/day_jump.dart';
import '../../core/time_utils.dart';
import '../../data/providers.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/calendar/day_overview.dart';
import '../../domain/calendar/month_grid.dart';
import '../../domain/models/tblock.dart';
import '../library/library_page.dart';
import '../week/week_page.dart';

/// 月视图每个日期上的方块数
final monthCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, DateTime>((ref, month) {
      final repo = ref.watch(dayBlockRepositoryProvider);
      final start = firstOfMonth(month);
      final end = DateTime(month.year, month.month, daysInMonth(month));
      return repo.countByDateRange(formatDateKey(start), formatDateKey(end));
    });

/// 某一天的概览（日历下方预览用）
final dayOverviewProvider = FutureProvider.autoDispose
    .family<DayOverview, String>((ref, dateKey) async {
      final repo = ref.watch(dayBlockRepositoryProvider);
      final blocks = await repo.loadDay(dateKey);
      return DayOverview(dateKey: dateKey, blocks: blocks, now: DateTime.now());
    });

/// 月份总览：叠起来看哪天最挤
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  late String _selectedKey;

  @override
  void initState() {
    super.initState();
    final day = widget.initialDate ?? DateTime.now();
    _month = firstOfMonth(day);
    _selectedKey = formatDateKey(day);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = addMonths(_month, delta));
  }

  void _openDay(String key) {
    Navigator.of(context).pop<DayJump>((date: key, minute: null));
  }

  Future<void> _openWeek() async {
    final entry = _calendarEntryDate;
    final jump = await Navigator.of(context).push<DayJump>(
      MaterialPageRoute<DayJump>(
        builder: (_) => WeekPage(initialDate: entry),
      ),
    );
    if (!mounted || jump == null) return;
    Navigator.of(context).pop<DayJump>(jump);
    ref.invalidate(monthCountsProvider);
    ref.invalidate(dayOverviewProvider);
  }

  /// 周视图从「当前选中的那天」打开，否则从今天。
  DateTime get _calendarEntryDate {
    return DateTime.tryParse(_selectedKey) ?? DateTime.now();
  }

  Future<void> _openPlans() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const LibraryPage(initialTab: 1)));
    ref.invalidate(monthCountsProvider);
    ref.invalidate(dayOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(monthCountsProvider(_month));
    final todayKey = formatDateKey(DateTime.now());

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bg,
        title: const Text('日历', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: '周视图',
            onPressed: _openWeek,
            icon: const Icon(Icons.view_week_outlined, size: 20),
          ),
          IconButton(
            tooltip: '长期计划',
            onPressed: _openPlans,
            icon: const Icon(Icons.event_note, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _MonthHeader(
              month: _month,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
              onToday: () {
                final now = DateTime.now();
                setState(() {
                  _month = firstOfMonth(now);
                  _selectedKey = formatDateKey(now);
                });
              },
            ),
            _WeekdayRow(),
            Expanded(
              child: counts.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    '读不到数据：$error',
                    style: TextStyle(
                      color: Palette.textDim,
                      fontSize: 12,
                    ),
                  ),
                ),
                data: (byDate) => _MonthGrid(
                  month: _month,
                  counts: byDate,
                  selectedKey: _selectedKey,
                  todayKey: todayKey,
                  onSelect: (key) => setState(() => _selectedKey = key),
                ),
              ),
            ),
            _DayPreview(
              dateKey: _selectedKey,
              onOpen: () => _openDay(_selectedKey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: '上个月',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, size: 22),
          ),
          Text(
            monthLabel(month),
            style: TextStyle(
              color: Palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            tooltip: '下个月',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 22),
          ),
          const Spacer(),
          TextButton(onPressed: onToday, child: const Text('今天')),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          for (final label in kMondayFirstWeekdayLabels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(color: Palette.textDim, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.counts,
    required this.selectedKey,
    required this.todayKey,
    required this.onSelect,
  });

  final DateTime month;
  final Map<String, int> counts;
  final String selectedKey;
  final String todayKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final cells = monthCells(month);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.92,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final day = cells[index];
        if (day == null) return const SizedBox.shrink();
        final key = formatDateKey(day);
        return _DayCell(
          day: day,
          count: counts[key] ?? 0,
          isToday: key == todayKey,
          isSelected: key == selectedKey,
          onTap: () => onSelect(key),
          onDoubleTap: () =>
              Navigator.of(context).pop<DayJump>((date: key, minute: null)),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final DateTime day;
  final int count;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final dense = count >= 8;
    final medium = count >= 4;
    final dotColor = count == 0
        ? Palette.line
        : (dense
              ? Palette.top
              : (medium ? Palette.of(Priority.b) : Palette.accent));

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Palette.surfaceHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Palette.top
                : (isSelected ? Palette.accent : Colors.transparent),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? Palette.top : Palette.textPrimary,
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            if (count > 0)
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 3),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(color: Palette.textDim, fontSize: 9),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}

class _DayPreview extends ConsumerWidget {
  const _DayPreview({required this.dateKey, required this.onOpen});

  final String dateKey;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dayOverviewProvider(dateKey));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.line)),
      ),
      child: overview.when(
        loading: () => const SizedBox(height: 92),
        error: (error, _) => Text(
          '$error',
          style: TextStyle(color: Palette.textDim, fontSize: 12),
        ),
        data: (data) {
          final day = DateTime.parse(dateKey);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dayLabel(day),
                    style: TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (data.isEmpty)
                    Text(
                      '空着',
                      style: TextStyle(color: Palette.textDim, fontSize: 11),
                    ),
                  const Spacer(),
                  Text(
                    '${data.blocks.length} 件 · ${formatDuration(data.totalMinutes)}',
                    style: TextStyle(
                      color: Palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: data.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '这天还没有安排',
                          style: TextStyle(
                            color: Palette.textDim,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.sorted.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final block = data.sorted[index];
                          return _MiniBlock(block: block);
                        },
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.accent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('打开这天的轴'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniBlock extends StatelessWidget {
  const _MiniBlock({required this.block});

  final TBlock block;

  @override
  Widget build(BuildContext context) {
    final color = Palette.of(block.priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMinute(block.startMin),
            style: TextStyle(color: Palette.textSecondary, fontSize: 9),
          ),
          Text(
            block.title,
            style: TextStyle(color: Palette.textPrimary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
