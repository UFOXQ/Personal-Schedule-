import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/tblock.dart';

/// 打开计划编辑面板；返回 true 表示保存过（新建或修改）。
Future<bool?> showPlanEditor(BuildContext context, {Plan? plan}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _PlanEditor(plan: plan),
    ),
  );
}

class _PlanEditor extends ConsumerStatefulWidget {
  const _PlanEditor({this.plan});

  final Plan? plan;

  @override
  ConsumerState<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<_PlanEditor> {
  late final TextEditingController _title;
  late DateTime _start;
  late DateTime _end;
  late int _weekdays;
  late Lane _lane;
  late int _startMin;
  late int _duration;
  late Priority _priority;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final today = DateTime.now();
    _title = TextEditingController(text: plan?.title ?? '新计划');
    _start = plan == null ? today : DateTime.parse(plan.startDate);
    _end = plan == null
        ? today.add(const Duration(days: 30))
        : DateTime.parse(plan.endDate);
    _weekdays = plan?.weekdaysMask ?? 127;
    _lane = Lane(id: plan?.lane ?? Lane.habit.id, name: plan?.lane ?? Lane.habit.id);
    _startMin = plan?.startMin ?? 540;
    _duration = plan?.durationMin ?? 60;
    _priority =
        Priority.values[(plan?.priority ?? Priority.c.index).clamp(
          0,
          Priority.values.length - 1,
        )];
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      helpText: isStart ? '开始日期' : '结束日期',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
        if (_end.isBefore(_start)) _start = _end;
      }
    });
  }

  void _bumpStart(int deltaMinutes) {
    setState(() {
      _startMin = (_startMin + deltaMinutes).clamp(0, kMinutesPerDay - 15);
      _startMin = (_startMin / 15).round() * 15;
    });
  }

  void _bumpDuration(int deltaMinutes) {
    setState(() {
      _duration = (_duration + deltaMinutes).clamp(15, 12 * 60);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final lib = ref.read(libraryRepositoryProvider);
    if (_isEditing) {
      await lib.updatePlanSimple(
        id: widget.plan!.id,
        title: title,
        startDate: formatDateKey(_start),
        endDate: formatDateKey(_end),
        lane: _lane,
        startMin: _startMin,
        durationMin: _duration,
        priority: _priority,
        weekdaysMask: _weekdays,
      );
    } else {
      await lib.createPlanSimple(
        id: const Uuid().v4(),
        title: title,
        startDate: formatDateKey(_start),
        endDate: formatDateKey(_end),
        lane: _lane,
        startMin: _startMin,
        durationMin: _duration,
        priority: _priority,
        weekdaysMask: _weekdays,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    await ref.read(libraryRepositoryProvider).deletePlan(widget.plan!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? '编辑计划' : '新建计划',
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              style: TextStyle(color: Palette.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: '计划名称',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: '开始',
                    value: formatDateKey(_start),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: '结束',
                    value: formatDateKey(_end),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('哪几天'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (var i = 0; i < 7; i++)
                  _WeekdayChip(
                    label: kWeekdayShort[i],
                    selected: (_weekdays & (1 << i)) != 0,
                    onTap: () =>
                        setState(() => _weekdays = _weekdays ^ (1 << i)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('泳道'),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final lane in Lane.defaults)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _PillButton(
                      label: lane.name,
                      selected: _lane == lane,
                      onTap: () => setState(() => _lane = lane),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StepperField(
                    label: '开始时间',
                    value: formatMinute(_startMin),
                    onMinus: () => _bumpStart(-15),
                    onPlus: () => _bumpStart(15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StepperField(
                    label: '时长',
                    value: formatDuration(_duration),
                    onMinus: () => _bumpDuration(-15),
                    onPlus: () => _bumpDuration(15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FieldLabel('优先级'),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final priority in Priority.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _PillButton(
                      label: '${priority.label} 级',
                      color: Palette.of(priority),
                      selected: _priority == priority,
                      onTap: () => setState(() => _priority = priority),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (_isEditing)
                  TextButton(
                    onPressed: _delete,
                    child: Text(
                      '删除',
                      style: TextStyle(color: Palette.top),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.accent,
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> kWeekdayShort = ['一', '二', '三', '四', '五', '六', '日'];

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: Palette.textDim, fontSize: 11));
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Palette.textDim, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: Palette.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _PillButton(
    label: label,
    selected: selected,
    onTap: onTap,
    compact: true,
  );
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Palette.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 11 : 12,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? tint : Palette.line,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? tint : Palette.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Palette.textDim, fontSize: 10),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onMinus,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onPlus,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
