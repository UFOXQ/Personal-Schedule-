import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';
import '../../domain/models/tblock.dart';

/// 完成记录（打卡历史）。方块完成后从时间轴消失，但这里一直留着。
final completionLogsProvider = FutureProvider.autoDispose<List<CompletionLog>>((
  ref,
) {
  return ref.watch(libraryRepositoryProvider).completions();
});

class CompletionLogsPage extends ConsumerWidget {
  const CompletionLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(completionLogsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.bg,
        foregroundColor: Palette.textPrimary,
        title: const Text('完成记录', style: TextStyle(fontSize: 16)),
      ),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '读取失败：$error',
            style: const TextStyle(color: Palette.textSecondary),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
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
                const Divider(height: 1, color: Palette.line),
            itemBuilder: (context, index) {
              final row = rows[index];
              final lane = Lane.byIndex(row.lane);
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
                  style: const TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${row.date} · ${lane.label} · ${formatRange(row.startMin, row.durationMin)}',
                  style: const TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
                trailing: Text(
                  '${row.completedAt.hour.toString().padLeft(2, '0')}:'
                  '${row.completedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Palette.textDim, fontSize: 11),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
