import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../domain/models/lane.dart';
import '../timeline/timeline_state.dart';

/// 泳道管理：拖动排序、改名、删除、重置回默认三条
Future<void> showLaneManagerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LaneManagerSheet(),
  );
}

class _LaneManagerSheet extends ConsumerWidget {
  const _LaneManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    final notifier = ref.read(timelineProvider.notifier);
    final lanes = state.lanes;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '泳道',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Palette.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: state.canEdit
                      ? () async {
                          final ok = await _confirm(
                            context,
                            '重置泳道？',
                            '会删掉你加的泳道，恢复成「日常 / 打卡 / 临时」。'
                                '已经在这些泳道里的任务会被挪到「日常」。',
                          );
                          if (!ok) return;
                          await notifier.resetLanes();
                        }
                      : null,
                  child: const Text('重置'),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '按住右侧的把手上下拖动来排序；删掉的泳道里今天的任务会挪到第一条。',
              style: TextStyle(fontSize: 12, color: Palette.textDim),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: lanes.length,
                onReorderItem: (oldIndex, newIndex) {
                  if (!state.canEdit) return;
                  notifier.reorderLanes(oldIndex, newIndex);
                },
                itemBuilder: (context, i) {
                  final lane = lanes[i];
                  return _LaneRow(
                    key: ValueKey(lane.id),
                    lane: lane,
                    index: i,
                    enabled: state.canEdit,
                    onRename: () async {
                      final name = await _askName(context, lane.name);
                      if (name == null || name.isEmpty) return;
                      await notifier.renameLane(lane.id, name);
                    },
                    onDelete: lanes.length <= 1
                        ? null
                        : () async {
                            final fallback = lanes.firstWhere(
                              (l) => l.id != lane.id,
                            );
                            final ok = await _confirm(
                              context,
                              '删掉「${lane.name}」？',
                              '这一泳道里今天的任务会挪到「${fallback.name}」。',
                            );
                            if (!ok) return;
                            await notifier.deleteLane(lane.id);
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: state.canEdit
                  ? () async {
                      final name = await _askName(context, '');
                      if (name == null || name.isEmpty) return;
                      await notifier.addLane(name);
                    }
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('加一条泳道'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _askName(BuildContext context, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('泳道名字'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '比如：工作 / 家庭 / 学习'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _LaneRow extends StatelessWidget {
  const _LaneRow({
    super.key,
    required this.lane,
    required this.index,
    required this.enabled,
    required this.onRename,
    required this.onDelete,
  });

  final Lane lane;
  final int index;
  final bool enabled;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Palette.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lane.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Palette.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: '改名',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: enabled ? onRename : null,
          ),
          IconButton(
            tooltip: '删除',
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: onDelete == null ? Palette.textDim : Palette.top,
            ),
            onPressed: enabled ? onDelete : null,
          ),
          if (enabled)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: Palette.textSecondary,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Icon(
                Icons.drag_handle,
                size: 20,
                color: Palette.textDim,
              ),
            ),
        ],
      ),
    );
  }
}
