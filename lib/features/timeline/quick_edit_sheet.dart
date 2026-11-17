import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../domain/models/tblock.dart';
import '../widgets/number_slider.dart';
import 'timeline_state.dart';

/// 双击方块弹的「快速调整」。
///
/// 三条滑块分别管开始、结束、整体位置；改动**立刻**写回时间轴（背后能看到
/// 方块跟着动），取消则整体还原。右边的数字可以直接点开输入精确值。
Future<void> showQuickEditSheet(BuildContext context, String blockId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _QuickEditSheet(blockId: blockId),
  );
}

class _QuickEditSheet extends ConsumerStatefulWidget {
  const _QuickEditSheet({required this.blockId});

  final String blockId;

  @override
  ConsumerState<_QuickEditSheet> createState() => _QuickEditSheetState();
}

class _QuickEditSheetState extends ConsumerState<_QuickEditSheet> {
  final TextEditingController _title = TextEditingController();
  int _startMin = 0;
  int _durationMin = 30;
  int _originStart = 0;
  int _originDuration = 30;
  String _originTitle = '';
  bool _inited = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _fill(TBlock block) {
    if (_inited) return;
    _inited = true;
    _title.text = block.title;
    _startMin = _originStart = block.startMin;
    _durationMin = _originDuration = block.durationMin;
    _originTitle = block.title;
  }

  void _applyLive() {
    final title = _title.text.trim();
    ref
        .read(timelineProvider.notifier)
        .updateBlock(
          widget.blockId,
          title: title.isEmpty ? _originTitle : title,
          startMin: _startMin,
          durationMin: _durationMin,
        );
  }

  void _setStart(int value) {
    setState(() {
      _startMin = value.clamp(0, kMinutesPerDay - _durationMin);
    });
    _applyLive();
  }

  void _setEnd(int value) {
    final end = value.clamp(_startMin + kMinDuration, kMinutesPerDay);
    setState(() {
      _durationMin = end - _startMin;
    });
    _applyLive();
  }

  void _setOffset(int value) {
    final maxOffset = kMinutesPerDay - _originStart - _durationMin;
    setState(() {
      _startMin = (_originStart + value).clamp(0, _originStart + maxOffset);
    });
    _applyLive();
  }

  void _cancel() {
    ref
        .read(timelineProvider.notifier)
        .updateBlock(
          widget.blockId,
          title: _originTitle,
          startMin: _originStart,
          durationMin: _originDuration,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    final matches = state.blocks.where((b) => b.id == widget.blockId);
    if (matches.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    final block = matches.first;
    _fill(block);

    final readOnly = !state.canEdit;
    final maxStart = (kMinutesPerDay - _durationMin).clamp(0, kMinutesPerDay);
    final end = (_startMin + _durationMin).clamp(0, kMinutesPerDay);
    final maxOffset = (kMinutesPerDay - _originStart - _durationMin).clamp(
      0,
      kMinutesPerDay,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 10,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
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
                    '快速调整',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Palette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    readOnly ? '已锁定' : '改动即时生效',
                    style: TextStyle(
                      fontSize: 11,
                      color: readOnly ? Palette.top : Palette.textDim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                enabled: !readOnly,
                style: TextStyle(fontSize: 14, color: Palette.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Palette.surfaceHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '这件事叫什么',
                ),
                onChanged: (_) => _applyLive(),
              ),
              const SizedBox(height: 14),
              NumberSlider(
                key: const Key('quick-edit-start'),
                label: '开始',
                value: _startMin.toDouble(),
                min: 0,
                max: maxStart.toDouble(),
                step: kSnapMinutes.toDouble(),
                display: (v) => formatMinute(v.round()),
                unitHint: '分钟数，例如 09:00 就是 540',
                enabled: !readOnly,
                onChanged: (v) => _setStart(snapMinute(v)),
              ),
              const SizedBox(height: 4),
              NumberSlider(
                key: const Key('quick-edit-end'),
                label: '结束',
                value: end.toDouble(),
                min: (_startMin + kMinDuration).clamp(0, kMinutesPerDay).toDouble(),
                max: kMinutesPerDay.toDouble(),
                step: kSnapMinutes.toDouble(),
                display: (v) => formatMinute(v.round()),
                unitHint: '分钟数，例如 10:30 就是 630',
                enabled: !readOnly,
                onChanged: (v) => _setEnd(snapMinute(v)),
              ),
              const SizedBox(height: 4),
              NumberSlider(
                key: const Key('quick-edit-offset'),
                label: '位置',
                value: (_startMin - _originStart).toDouble(),
                min: -_originStart.toDouble(),
                max: maxOffset.toDouble(),
                step: kSnapMinutes.toDouble(),
                display: (v) {
                  final m = v.round();
                  if (m == 0) return '不动';
                  return '${m > 0 ? '+' : ''}$m 分';
                },
                unitHint: '相对原来的位移，负数是往前挪',
                enabled: !readOnly,
                onChanged: (v) => _setOffset(snapMinute(v)),
              ),
              const SizedBox(height: 10),
              Text(
                '${formatRange(_startMin, _durationMin)} · ${formatDuration(_durationMin)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      key: const Key('quick-edit-cancel'),
                      onPressed: _cancel,
                      child: Text(
                        '撤销改动',
                        style: TextStyle(color: Palette.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const Key('quick-edit-save'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('完成'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
