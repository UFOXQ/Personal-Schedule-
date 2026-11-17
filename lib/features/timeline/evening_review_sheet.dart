import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../domain/models/tblock.dart';
import 'timeline_state.dart';

/// 晚间小结：今天还剩几件、一键留到明天或丢掉。
Future<void> showEveningReview(BuildContext context, WidgetRef ref) async {
  final state = ref.read(timelineProvider);
  final pending = [
    for (final b in state.blocks)
      if (!b.done && b.status == BlockStatus.planned) b,
  ];

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EveningReviewSheet(pending: pending),
  );
}

class _EveningReviewSheet extends ConsumerStatefulWidget {
  const _EveningReviewSheet({required this.pending});

  final List<TBlock> pending;

  @override
  ConsumerState<_EveningReviewSheet> createState() =>
      _EveningReviewSheetState();
}

class _EveningReviewSheetState extends ConsumerState<_EveningReviewSheet> {
  bool _busy = false;

  Future<void> _run(Future<int> Function() action, String done) async {
    setState(() => _busy = true);
    final count = await action();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (count > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(done.replaceFirst('%d', '$count'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pending;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              pending.isEmpty ? '今天全做完了' : '今天还剩 ${pending.length} 件',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pending.isEmpty
                  ? '收工，明天见。'
                  : '留到明天会照原时段复制过去，丢掉只是不再提醒你。',
              style: TextStyle(
                fontSize: 12,
                color: Palette.textSecondary,
              ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final block = pending[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Palette.ofBlock(block, false),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              block.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Palette.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            formatRange(block.startMin, block.durationMin),
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => ref
                                  .read(timelineProvider.notifier)
                                  .dropAllUnfinished(),
                              '丢掉了 %d 件，明天不再提醒',
                            ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('丢掉'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => ref
                                  .read(timelineProvider.notifier)
                                  .carryAllUnfinished(),
                              '把 %d 件留到了明天',
                            ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('全部留到明天'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: const Text('好'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
