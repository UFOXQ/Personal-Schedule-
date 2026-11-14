import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/tblock.dart';
import '../../domain/priority.dart';
import '../../domain/reminders.dart';
import '../../platform/notifications/reminder_scheduler.dart';
import '../calendar/calendar_page.dart';
import '../logs/completion_logs_page.dart';
import '../settings/reminder_settings_sheet.dart';
import '../templates/collections_sheet.dart';
import 'timeline_state.dart';
import 'timeline_view.dart';

/// 时间轴主页面：顶栏 + 置顶投影区 + 时间轴 + 选中信息条
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  Timer? _ticker;
  bool _carryDialogOpen = false;

  /// 到点提醒的应用内横幅（桌面端主要靠它，系统 toast 不一定弹得出来）
  Reminder? _banner;
  StreamSubscription<Reminder>? _bannerSub;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // 「现在」线和死线倒计时每分钟刷新
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(timelineProvider.notifier).tickNow();
    });
    _bannerSub = ref.read(reminderSchedulerProvider).fired.listen((reminder) {
      if (!mounted) return;
      _bannerTimer?.cancel();
      setState(() => _banner = reminder);
      _bannerTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _banner = null);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bannerSub?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  /// 有以前没做完的方块时，弹窗问「顺延还是丢掉」
  void _maybeShowCarryDialog(TimelineState state) {
    if (state.carryOvers.isEmpty || _carryDialogOpen) return;
    final pending = state.carryOvers;
    _carryDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _carryDialogOpen = false;
        return;
      }
      final preview = pending
          .take(4)
          .map((c) => '· ${c.date} ${c.block.title}')
          .join('\n');
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Palette.surface,
          title: Text(
            '有 ${pending.length} 件事没做完',
            style: const TextStyle(
              color: Palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending.length > 4 ? '$preview\n…' : preview,
                style: const TextStyle(
                  color: Palette.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '顺延会照原时段复制到今天，并记下顺延次数。',
                style: TextStyle(color: Palette.textDim, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('later'),
              child: const Text('稍后'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('drop'),
              child: const Text('丢弃', style: TextStyle(color: Palette.textDim)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: const Text('顺延到今天'),
            ),
          ],
        ),
      );
      _carryDialogOpen = false;
      if (!mounted) return;
      final notifier = ref.read(timelineProvider.notifier);
      switch (action) {
        case 'keep':
          await notifier.resolveCarryOvers(keep: true);
        case 'drop':
          await notifier.resolveCarryOvers(keep: false);
        default:
          notifier.postponeCarryOvers();
      }
    });
  }

  Future<void> _openCollections() async {
    final collectionId = await showCollectionsSheet(context);
    if (collectionId == null || !mounted) return;
    final count = await ref
        .read(timelineProvider.notifier)
        .injectCollection(collectionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(count == 0 ? '这个集合是空的' : '投入了 $count 个方块')),
    );
  }

  void _openLogs() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CompletionLogsPage()));
  }

  /// 打开「到点提醒」设置面板
  Future<void> _openReminders() => showReminderSettingsSheet(context);

  /// 打开月历，选一天后跳到那天
  Future<void> _openCalendar() async {
    final current = ref.read(timelineProvider).dateKey;
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => CalendarPage(initialDate: DateTime.parse(current)),
      ),
    );
    if (!mounted || picked == null) return;
    await ref.read(timelineProvider.notifier).goToDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    _maybeShowCarryDialog(state);
    final topBlocks = sortByPriority(
      state.blocks.where((b) => isTopPriority(b, state.now)),
      state.now,
    );
    final selected = state.selected;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  dateKey: state.dateKey,
                  now: state.now,
                  showTopInLane: state.showTopInLane,
                  onPrevDay: () =>
                      ref.read(timelineProvider.notifier).shiftDay(-1),
                  onNextDay: () =>
                      ref.read(timelineProvider.notifier).shiftDay(1),
                  onToday: () => ref.read(timelineProvider.notifier).goToday(),
                  onOpenCalendar: _openCalendar,
                  onOpenReminders: _openReminders,
                  onToggleTopInLane: () =>
                      ref.read(timelineProvider.notifier).toggleShowTopInLane(),
                  onOpenCollections: _openCollections,
                  onOpenLogs: _openLogs,
                ),
                if (topBlocks.isNotEmpty)
                  _TopDock(
                    blocks: topBlocks,
                    now: state.now,
                    selectedId: state.selectedId,
                    onTap: (id) =>
                        ref.read(timelineProvider.notifier).select(id),
                  ),
                const Expanded(child: TimelineView()),
                if (selected != null)
                  _SelectedBar(
                    block: selected,
                    now: state.now,
                    onComplete: () =>
                        ref.read(timelineProvider.notifier).completeSelected(),
                    onCyclePriority: () => ref
                        .read(timelineProvider.notifier)
                        .cyclePriority(selected.id),
                    onDelete: () => ref
                        .read(timelineProvider.notifier)
                        .deleteBlock(selected.id),
                    onClose: () =>
                        ref.read(timelineProvider.notifier).select(null),
                  ),
              ],
            ),
            if (_banner != null)
              Positioned(
                left: 12,
                right: 12,
                top: 8,
                child: _ReminderBanner(
                  reminder: _banner!,
                  onClose: () {
                    _bannerTimer?.cancel();
                    setState(() => _banner = null);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 到点提醒横幅 ──────────────────────────────────────────────
class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.reminder, required this.onClose});

  final Reminder reminder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Palette.top.withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm, color: Palette.top, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reminder.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '知道了',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18, color: Palette.textDim),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 顶栏 ──────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.dateKey,
    required this.now,
    required this.showTopInLane,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onToday,
    required this.onOpenCalendar,
    required this.onOpenReminders,
    required this.onToggleTopInLane,
    required this.onOpenCollections,
    required this.onOpenLogs,
  });

  final String dateKey;
  final DateTime now;
  final bool showTopInLane;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenReminders;
  final VoidCallback onToggleTopInLane;
  final VoidCallback onOpenCollections;
  final VoidCallback onOpenLogs;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final day = DateTime.parse(dateKey);
    final isToday = dateKey == formatDateKey(now);
    final dateLabel =
        '${day.month} 月 ${day.day} 日 · 周${weekdays[day.weekday - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '今天' : '周${weekdays[day.weekday - 1]}',
                  style: const TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _DayArrow(
                      icon: Icons.chevron_left,
                      tooltip: '前一天',
                      onTap: onPrevDay,
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    _DayArrow(
                      icon: Icons.chevron_right,
                      tooltip: '后一天',
                      onTap: onNextDay,
                    ),
                    if (!isToday)
                      TextButton(
                        onPressed: onToday,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 24),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '回到今天',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _TopIcon(
            icon: Icons.calendar_month_outlined,
            tooltip: '日历',
            onTap: onOpenCalendar,
          ),
          _TopIcon(
            icon: Icons.playlist_add,
            tooltip: '把集合整包投入当天',
            onTap: onOpenCollections,
          ),
          _TopIcon(
            icon: Icons.notifications_none,
            tooltip: '到点提醒',
            onTap: onOpenReminders,
          ),
          _TopIcon(icon: Icons.history, tooltip: '完成记录', onTap: onOpenLogs),
          _TopIcon(
            icon: showTopInLane
                ? Icons.filter_alt_off_outlined
                : Icons.filter_alt_outlined,
            tooltip: showTopInLane ? '置顶项也在原泳道显示（点击隐藏）' : '置顶项只在顶部显示（点击恢复）',
            onTap: onToggleTopInLane,
            color: showTopInLane ? Palette.accent : Palette.textDim,
          ),
        ],
      ),
    );
  }
}

class _DayArrow extends StatelessWidget {
  const _DayArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Icon(icon, size: 16, color: Palette.textDim),
        ),
      ),
    );
  }
}

// ── 顶栏小图标（紧凑一点，手机上放得下 5 个） ────────────────
class _TopIcon extends StatelessWidget {
  const _TopIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = Palette.textSecondary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color, size: 21),
    );
  }
}

// ── 置顶投影区 ────────────────────────────────────────────────
class _TopDock extends StatelessWidget {
  const _TopDock({
    required this.blocks,
    required this.now,
    required this.selectedId,
    required this.onTap,
  });

  final List<TBlock> blocks;
  final DateTime now;
  final String? selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          itemCount: blocks.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final block = blocks[index];
            final selected = block.id == selectedId;
            final deadline = deadlineLabel(block, now);
            return GestureDetector(
              onTap: () => onTap(block.id),
              child: Container(
                width: 178,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Palette.top.withValues(alpha: 0.55),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.top.withValues(alpha: 0.10),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.top,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '置顶',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            block.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Palette.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${formatMinute(block.startMin)} · ${formatDuration(block.durationMin)}',
                      style: const TextStyle(
                        color: Palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      deadline.isEmpty
                          ? '${block.priority.label} 级 · ${block.lane.label}'
                          : '${block.priority.label} 级 · $deadline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: deadline.isEmpty ? Palette.textDim : Palette.top,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 选中信息条 ────────────────────────────────────────────────
class _SelectedBar extends StatelessWidget {
  const _SelectedBar({
    required this.block,
    required this.now,
    required this.onComplete,
    required this.onCyclePriority,
    required this.onDelete,
    required this.onClose,
  });

  final TBlock block;
  final DateTime now;
  final VoidCallback onComplete;
  final VoidCallback onCyclePriority;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = Palette.ofBlock(block, isTopPriority(block, now));
    return Container(
      decoration: const BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.line)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
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
                  block.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${block.lane.label} · ${formatRange(block.startMin, block.durationMin)} · ${formatDuration(block.durationMin)}'
                  '${block.isCarried ? ' · 顺延 ${block.carryCount} 次' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '完成',
            onPressed: onComplete,
            icon: const Icon(
              Icons.check_circle_outline,
              color: Palette.textPrimary,
              size: 22,
            ),
          ),
          IconButton(
            tooltip: '切换优先级',
            onPressed: onCyclePriority,
            icon: Icon(Icons.flag_outlined, color: color, size: 20),
          ),
          IconButton(
            tooltip: '删除',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Palette.textSecondary,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: '取消选中',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Palette.textDim, size: 20),
          ),
        ],
      ),
    );
  }
}
