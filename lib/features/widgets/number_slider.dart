import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';

/// 带数字输入的滑块：拖动调值，点右边的数字可以直接敲一个精确值。
///
/// 设置页和「快速修改」面板都用它，保证手感和交互一致。
class NumberSlider extends StatelessWidget {
  const NumberSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.display,
    required this.onChanged,
    this.unitHint = '',
    this.enabled = true,
    this.dialogTitle,
  });

  final String label;
  final double value;
  final double min;
  final double max;

  /// 拖动与输入都会按这个步长取整，<= 0 表示连续。
  final double step;

  /// 数字怎么显示（默认由调用方给）。
  final String Function(double value) display;

  final ValueChanged<double> onChanged;
  final String unitHint;
  final bool enabled;
  final String? dialogTitle;

  double get _safeMax => max <= min ? min + 1 : max;

  double _snap(double raw) {
    final clamped = raw.clamp(min, _safeMax).toDouble();
    if (step <= 0) return clamped;
    final snapped = (clamped / step).round() * step;
    return snapped.clamp(min, _safeMax).toDouble();
  }

  Future<void> _promptNumber(BuildContext context) async {
    if (!enabled) return;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _NumberDialog(
        title: dialogTitle ?? label,
        initial: display(value),
        hint: unitHint,
      ),
    );
    if (result != null) onChanged(_snap(result));
  }

  @override
  Widget build(BuildContext context) {
    final valueText = display(value);
    final divisions = step <= 0
        ? null
        : ((_safeMax - min) / step).round().clamp(1, 2000);

    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Palette.textSecondary),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value.clamp(min, _safeMax).toDouble(),
              min: min,
              max: _safeMax,
              divisions: divisions,
              onChanged: enabled ? (v) => onChanged(_snap(v)) : null,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: enabled ? () => _promptNumber(context) : null,
              borderRadius: BorderRadius.circular(6),
              child: Tooltip(
                message: '点一下直接输入数字',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    valueText,
                    key: const Key('number-slider-value'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Palette.textPrimary : Palette.textDim,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/// 数字输入框自己管 controller，避免弹窗退场动画期间被提前 dispose。
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.initial,
    required this.hint,
  });

  final String title;
  final String initial;
  final String hint;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text.trim());
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surface,
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 15, color: Palette.textPrimary),
      ),
      content: TextField(
        key: const Key('number-slider-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontSize: 15, color: Palette.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          helperText: widget.hint.isEmpty ? null : widget.hint,
          helperStyle: TextStyle(fontSize: 11, color: Palette.textDim),
          filled: true,
          fillColor: Palette.surfaceHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: Palette.textSecondary)),
        ),
        FilledButton(
          key: const Key('number-slider-confirm'),
          onPressed: _submit,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
