import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../domain/models/tblock.dart';
import '../../domain/quick_parse.dart';
import 'timeline_state.dart';

/// 一句话添加：输入「明天 10:30 交周报 45分 A」这种，回车就落一条。
///
/// 返回解析出来的草稿（由调用方负责落库），取消返回 null。
Future<QuickDraft?> showQuickAddSheet(
  BuildContext context, {
  String? initialText,
}) {
  return showModalBottomSheet<QuickDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _QuickAddSheet(initialText: initialText),
    ),
  );
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({this.initialText});

  final String? initialText;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  late final TextEditingController _input = TextEditingController(
    text: widget.initialText ?? '',
  );
  QuickDraft? _draft;

  @override
  void initState() {
    super.initState();
    _reparse();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _reparse() {
    final draft = parseQuickAdd(
      _input.text,
      now: DateTime.now(),
      lanes: ref.read(timelineProvider).lanes,
    );
    if (draft != _draft) {
      setState(() => _draft = draft);
    }
  }

  void _submit() {
    final draft = _draft;
    if (draft == null) return;
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final draftDuration = draft?.durationMin ?? 30;
    final draftStart = draft?.startMin ?? 0;
    final warn = draft != null &&
        draftStart + draftDuration > kMinutesPerDay;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
            Text(
              '一句话加一条',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '例：明天 10:30 交周报 45分 A    ｜    今晚 8点 健身 1小时 打卡',
              style: TextStyle(fontSize: 11.5, color: Palette.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _reparse(),
              onSubmitted: (_) => _submit(),
              style: TextStyle(fontSize: 15, color: Palette.textPrimary),
              decoration: InputDecoration(
                hintText: '要做什么，什么时候',
                hintStyle: TextStyle(color: Palette.textDim),
                filled: true,
                fillColor: Palette.bg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Palette.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft == null ? '还没看懂' : draft.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: draft == null
                          ? Palette.textDim
                          : Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draft == null
                        ? '先写点什么，比如「明天 9点 学英语」'
                        : '${draft.preview}'
                            '${warn ? '  · 会超出今天' : ''}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (!kIsWeb)
                  TextButton(
                    onPressed: () {
                      _input.text = '';
                      _reparse();
                    },
                    child: const Text('清空'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: draft == null ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 44),
                  ),
                  child: const Text('添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 新建方块的默认泳道（一句话添加里没写就用这个）
Lane quickAddDefaultLane = Lane.temp;
