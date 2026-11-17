import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../domain/layout/gap_suggestions.dart';
import '../../domain/models/tblock.dart';
import '../widgets/time_selector.dart';
import 'timeline_state.dart';

/// 方块编辑面板：时间、标题、优先级、死线一次改完。
/// 桌面右键、手机双击、选中条上的「编辑」都走这里。
Future<void> showBlockEditor(
  BuildContext context,
  String blockId, {
  bool focusTitle = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _BlockEditor(blockId: blockId, focusTitle: focusTitle),
  );
}

class _BlockEditor extends ConsumerStatefulWidget {
  const _BlockEditor({required this.blockId, this.focusTitle = false});

  final String blockId;

  /// 新建方块时把焦点落在标题上，省一步点击
  final bool focusTitle;

  @override
  ConsumerState<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends ConsumerState<_BlockEditor> {
  late final TextEditingController _title;
  final _note = TextEditingController();
  int _startMin = 0;
  int _durationMin = 30;
  Priority _priority = Priority.c;
  Lane _lane = Lane.daily;
  DateTime? _deadline;
  bool _inited = false;
  bool _advancedOpen = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fill(TBlock block) {
    if (_inited) return;
    _inited = true;
    _title.text = block.title;
    _note.text = block.note;
    _startMin = block.startMin;
    _durationMin = block.durationMin;
    _priority = block.priority;
    _lane = block.lane;
    _deadline = block.deadline;
  }

  /// 当天还剩哪些够塞下这个时长的空档（不含自己），最多给三个建议
  List<int> _suggestedGapStarts() => suggestGapStarts(
    blocks: ref.read(timelineProvider).blocks,
    durationMin: _durationMin,
    excludeId: widget.blockId,
    currentStart: _startMin,
  );

  List<Widget> _gapSuggestionChips() {
    final starts = _suggestedGapStarts();
    if (starts.isEmpty) return const [];
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          Icon(
            Icons.space_dashboard_outlined,
            size: 14,
            color: Palette.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '塞进空档',
            style: TextStyle(fontSize: 11, color: Palette.textSecondary),
          ),
          const SizedBox(width: 8),
          for (final start in starts)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _MiniChip(
                label: formatMinute(start),
                selected: _startMin == start,
                enabled: true,
                onTap: () => setState(() => _startMin = start),
              ),
            ),
        ],
      ),
    ];
  }
  Future<void> _pickStart() async {
    final picked = await showTimeSelector(
      context,
      initialMinute: _startMin,
      title: '开始时间',
    );
    if (picked == null) return;
    setState(() {
      _startMin = picked.clamp(0, kMinutesPerDay - _durationMin);
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: '截止日期',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
      helpText: '截止时间',
    );
    if (!mounted) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  void _save() {
    ref
        .read(timelineProvider.notifier)
        .updateBlock(
          widget.blockId,
          title: _title.text,
          startMin: _startMin,
          durationMin: _durationMin,
          priority: _priority,
          lane: _lane,
          deadline: _deadline,
        );
    Navigator.of(context).pop();
  }

  void _delete() {
    ref.read(timelineProvider.notifier).deleteBlock(widget.blockId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    TBlock? block;
    for (final candidate in state.blocks) {
      if (candidate.id == widget.blockId) {
        block = candidate;
        break;
      }
    }
    if (block == null) {
      // 方块被删/被同步掉了，面板自己退场
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    _fill(block);

    final readOnly = state.locked;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                    '编辑方块',
                    style: TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (readOnly)
                    Text(
                      '已锁定',
                      style: TextStyle(color: Palette.top, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                autofocus: widget.focusTitle,
                enabled: !readOnly,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                  color: Palette.textPrimary,
                  fontSize: 15,
                ),
                decoration: _fieldDecoration('标题'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FieldButton(
                      label: '开始',
                      value: formatMinute(_startMin),
                      enabled: !readOnly,
                      onTap: _pickStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DurationStepper(
                      value: _durationMin,
                      enabled: !readOnly,
                      onChanged: (value) => setState(() => _durationMin = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final preset in const [15, 30, 45, 60, 90, 120])
                    _MiniChip(
                      label: formatDuration(preset),
                      selected: _durationMin == preset,
                      enabled: !readOnly,
                      onTap: () => setState(() => _durationMin = preset),
                    ),
                ],
              ),
              if (!readOnly) ..._gapSuggestionChips(),
              const SizedBox(height: 14),
              // 第二种调法：拉滑块。手指细调比拖方块准，也不会误触别的东西
              _SliderRow(
                label: '开始',
                valueLabel: formatMinute(_startMin),
                value: _startMin.toDouble(),
                min: 0,
                max: (kMinutesPerDay - _durationMin).toDouble(),
                divisions: ((kMinutesPerDay - _durationMin) / 5).round(),
                enabled: !readOnly,
                onChanged: (value) => setState(() {
                  _startMin = snapMinute(value);
                }),
              ),
              _SliderRow(
                label: '时长',
                valueLabel: formatDuration(_durationMin),
                value: _durationMin.toDouble(),
                min: kMinDuration.toDouble(),
                max: 12 * 60,
                divisions: ((12 * 60 - kMinDuration) / 5).round(),
                enabled: !readOnly,
                onChanged: (value) => setState(() {
                  _durationMin = snapMinute(value).clamp(
                    kMinDuration,
                    12 * 60,
                  );
                }),
              ),
              const SizedBox(height: 16),
              const _SectionLabel('优先级'),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final priority in Priority.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _PriorityButton(
                          priority: priority,
                          selected: _priority == priority,
                          enabled: !readOnly,
                          onTap: () => setState(() => _priority = priority),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionLabel('泳道'),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final lane in Lane.defaults)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _MiniChip(
                          label: lane.name,
                          selected: _lane == lane,
                          enabled: !readOnly,
                          onTap: () => setState(() => _lane = lane),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // 死线/备注平时收起来：一屏先给「时间、时长、优先级、泳道」，
              // 不常用的高级项点一下再展开，手机上不用滚来滚去。
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _advancedOpen = !_advancedOpen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _advancedOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Palette.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _advancedOpen ? '收起高级项' : '更多（截止时间 / 备注）',
                        style: TextStyle(
                          fontSize: 12,
                          color: Palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_advancedOpen) ...[
                const SizedBox(height: 4),
                const _SectionLabel('截止时间（B 级临近会置顶）'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _FieldButton(
                        label: '死线',
                        value: _deadline == null
                            ? '未设置'
                            : formatDeadline(_deadline!),
                        enabled: !readOnly,
                        onTap: _pickDeadline,
                      ),
                    ),
                    if (_deadline != null)
                      IconButton(
                        tooltip: '清除死线',
                        onPressed: readOnly
                            ? null
                            : () => setState(() => _deadline = null),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: Palette.textDim,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const _SectionLabel('备注'),
                const SizedBox(height: 6),
                TextField(
                  controller: _note,
                  enabled: !readOnly,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: _fieldDecoration('想记点什么（同步也会带上）'),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  if (!readOnly)
                    TextButton.icon(
                      onPressed: _delete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Palette.top,
                      ),
                      label: Text(
                        '删除',
                        style: TextStyle(color: Palette.top, fontSize: 13),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: readOnly ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 44),
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Palette.textDim, fontSize: 14),
    filled: true,
    fillColor: Palette.surfaceHigh,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Palette.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _FieldButton extends StatelessWidget {
  const _FieldButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: Palette.textDim, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationStepper extends StatelessWidget {
  const _DurationStepper({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Palette.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '减少 15 分钟',
            onPressed: enabled
                ? () => onChanged((value - 15).clamp(kMinDuration, 720))
                : null,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove, color: Palette.textSecondary),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '时长',
                  style: TextStyle(color: Palette.textDim, fontSize: 10),
                ),
                Text(
                  formatDuration(value),
                  style: TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '增加 15 分钟',
            onPressed: enabled
                ? () => onChanged((value + 15).clamp(kMinDuration, 720))
                : null,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, color: Palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Palette.accent.withValues(alpha: 0.18) : Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Palette.accent : Palette.line,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Center(
          widthFactor: 1.0,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Palette.accent : Palette.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.priority,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Priority priority;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Palette.of(priority);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.22) : Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Palette.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          '${priority.label} 级',
          style: TextStyle(
            color: selected ? color : Palette.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 一行「标签 + 当前值 + 滑块」，用来细调开始时间 / 时长
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(color: Palette.textSecondary, fontSize: 11.5),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: Palette.accent,
              inactiveTrackColor: Palette.line,
              thumbColor: Palette.accent,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: enabled ? Palette.textPrimary : Palette.textDim,
              fontSize: 11.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// 死线显示：今天/明天/日期 + 时分
String formatDeadline(DateTime deadline) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(deadline.year, deadline.month, deadline.day);
  final diff = day.difference(today).inDays;
  final time =
      '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return '今天 $time';
  if (diff == 1) return '明天 $time';
  if (diff == -1) return '昨天 $time';
  return '${deadline.month}/${deadline.day} $time';
}
