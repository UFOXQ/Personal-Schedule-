import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';
import '../../domain/models/tblock.dart';
import '../../domain/streak.dart';

/// 完成记录（打卡历史）。方块完成后从时间轴消失，但这里一直留着。
final completionLogsProvider = FutureProvider.autoDispose<List<CompletionLog>>((
  ref,
) {
  return ref.watch(libraryRepositoryProvider).completions();
});

/// 哪些天打过卡（连续天数用）
final completionDaysProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(libraryRepositoryProvider).completionDayKeys();
});

class CompletionLogsPage extends ConsumerWidget {
  const CompletionLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(completionLogsProvider);
    final days = ref.watch(completionDaysProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.bg,
        foregroundColor: Palette.textPrimary,
        title: const Text('完成记录', style: TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          days.maybeWhen(
            data: (keys) => _StreakCard(days: keys),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(child: _list(logs)),
        ],
      ),
    );
  }

  Widget _list(AsyncValue<List<CompletionLog>> logs) {
    return logs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          '读取失败：$error',
          style: TextStyle(color: Palette.textSecondary),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Text(
              '还没有完成记录\n在时间轴里选中方块，点 ✓ 就会记到这里',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.textDim, fontSize: 12),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rows.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Palette.line),
          itemBuilder: (context, index) {
            final row = rows[index];
            final lane = Lane(id: row.lane, name: row.lane);
            return ListTile(
              dense: true,
              leading: Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: Palette.of(Priority.c),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(
                row.title,
                style: TextStyle(
                  color: Palette.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${row.date} · ${lane.name} · ${formatRange(row.startMin, row.durationMin)}',
                style: TextStyle(
                  color: Palette.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: Text(
                '${row.completedAt.hour.toString().padLeft(2, '0')}:'
                '${row.completedAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Palette.textDim, fontSize: 11),
              ),
            );
          },
        );
      },
    );
  }
}

/// 顶部：连续打卡 N 天 + 最近 7 天的小圆点。
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final Set<String> days;

  @override
  Widget build(BuildContext context) {
    final streak = streakLength(days, DateTime.now());
    final week = recentWeek(days, DateTime.now());

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.line),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 22,
            color: streak > 0 ? Palette.top : Palette.textDim,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                streak > 0 ? '连续 $streak 天' : '还没有连击',
                style: TextStyle(
                  color: Palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                streak > 0 ? '保持住，明天再来一个' : '完成一件就会开始计数',
                style: TextStyle(
                  color: Palette.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < week.length; i++)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: week[i]
                        ? Palette.accent
                        : Palette.line.withValues(alpha: 0.8),
                    border: i == week.length - 1
                        ? Border.all(color: Palette.textDim, width: 1)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
