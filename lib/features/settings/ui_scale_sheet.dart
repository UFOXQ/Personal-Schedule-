import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import 'ui_scale.dart';

/// 「界面大小」面板：四档，选完立刻生效并记住。
Future<void> showUiScaleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _UiScaleSheet(),
  );
}

class _UiScaleSheet extends ConsumerWidget {
  const _UiScaleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(uiScaleProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Palette.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '界面大小',
              style: TextStyle(
                color: Palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '手机上觉得字小就调大一档；只放大文字和按钮，方块在时间轴上的位置不变。',
              style: TextStyle(
                color: Palette.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final option in UiScale.options) ...[
                  Expanded(
                    child: _ScaleChip(
                      label: UiScale.labelOf(option),
                      preview: option,
                      selected: (current - option).abs() < 0.01,
                      onTap: () =>
                          ref.read(uiScaleProvider.notifier).setScale(option),
                    ),
                  ),
                  if (option != UiScale.options.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Palette.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Palette.lineFaint),
              ),
              child: Text(
                '预览：10:30 - 11:15 · A 级 · 打卡',
                style: TextStyle(color: Palette.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleChip extends StatelessWidget {
  const _ScaleChip({
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Palette.accent.withValues(alpha: 0.18)
              : Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Palette.accent : Palette.lineFaint,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A',
              style: TextStyle(
                color: selected ? Palette.accent : Palette.textSecondary,
                fontSize: 18 * preview,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Palette.textPrimary : Palette.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
