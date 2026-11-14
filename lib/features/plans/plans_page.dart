import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';
import '../../domain/models/tblock.dart';
import '../timeline/timeline_state.dart';
import 'plan_editor_sheet.dart';

final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(libraryRepositoryProvider).plans();
});

/// 长期计划列表：区间 + 星期 + 时段，点开可编辑，改完立刻反映到时间轴。
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, {Plan? plan}) async {
    final saved = await showPlanEditor(context, plan: plan);
    if (saved != true) return;
    ref.invalidate(plansProvider);
    // 今天可能因此多出 / 少掉物化方块，直接重载当前这一天
    await ref.read(timelineProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(
        backgroundColor: Palette.bg,
        title: const Text('长期计划', style: TextStyle(fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        backgroundColor: Palette.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 22),
      ),
      body: SafeArea(
        child: plans.when(
          loading: () => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Center(
            child: Text(
              '$error',
              style: const TextStyle(color: Palette.textDim, fontSize: 12),
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) return const _EmptyPlans();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final plan = rows[index];
                return _PlanTile(
                  plan: plan,
                  onTap: () => _edit(context, ref, plan: plan),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          '还没有长期计划。\n像「学英语 11/1–12/31 每天 9:00」这种，\n建一条就会自动铺到每一天的时间轴上。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.textDim, fontSize: 12, height: 1.6),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final Plan plan;
  final VoidCallback onTap;

  String get _weekdays {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    if (plan.weekdaysMask == 127) return '每天';
    if (plan.weekdaysMask == 31) return '工作日';
    if (plan.weekdaysMask == 96) return '周末';
    final picked = <String>[];
    for (var i = 0; i < 7; i++) {
      if (plan.weekdaysMask & (1 << i) != 0) picked.add(names[i]);
    }
    return picked.isEmpty ? '不生效' : '周${picked.join('、')}';
  }

  @override
  Widget build(BuildContext context) {
    final priority = Priority.values[plan.priority];
    final color = Palette.of(priority);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.line),
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
                    plan.title,
                    style: const TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${plan.startDate} → ${plan.endDate} · $_weekdays',
                    style: const TextStyle(
                      color: Palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Lane.byIndex(plan.lane).label} ${formatMinute(plan.startMin)}',
                  style: const TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDuration(plan.durationMin),
                  style: const TextStyle(color: Palette.textDim, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
