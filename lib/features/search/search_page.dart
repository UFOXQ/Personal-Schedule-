import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/providers.dart';
import '../../domain/models/tblock.dart';
import '../timeline/timeline_state.dart';

/// 搜索结果：一行 = 某天的某个方块
typedef SearchHit = ({String date, TBlock block});

/// 全局搜索（标题 / 备注）
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _query = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.trim().isEmpty
        ? const AsyncValue<List<SearchHit>>.data(<SearchHit>[])
        : ref.watch(searchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.surface,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 15, color: Palette.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: '搜标题或备注，比如「周报」',
            hintStyle: TextStyle(fontSize: 14, color: Palette.textDim),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.close, size: 20),
              color: Palette.textSecondary,
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: results.when(
        loading: () => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            '搜索出错了：$error',
            style: TextStyle(fontSize: 13, color: Palette.textSecondary),
          ),
        ),
        data: (hits) {
          if (_query.trim().isEmpty) {
            return Center(
              child: Text(
                '输入几个字开始搜',
                style: TextStyle(fontSize: 13, color: Palette.textDim),
              ),
            );
          }
          if (hits.isEmpty) {
            return Center(
              child: Text(
                '没找到「${_query.trim()}」',
                style: TextStyle(fontSize: 13, color: Palette.textDim),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            itemCount: hits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final hit = hits[index];
              final showDate =
                  index == 0 || hits[index - 1].date != hit.date;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDate)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                      child: Text(
                        formatDayHeader(hit.date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Palette.textSecondary,
                        ),
                      ),
                    ),
                  _SearchTile(
                    hit: hit,
                    onTap: () => _open(context, hit),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, SearchHit hit) async {
    final notifier = ref.read(timelineProvider.notifier);
    Navigator.of(context).pop();
    await notifier.goToDate(hit.date);
    notifier.select(hit.block.id);
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({required this.hit, required this.onTap});

  final SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final block = hit.block;
    final color = Palette.of(block.priority);
    return Material(
      color: Palette.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 30,
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
                      block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${block.lane.name} · '
                      '${formatRange(block.startMin, block.durationMin)}'
                      '${block.note.isEmpty ? '' : ' · ${block.note}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Palette.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// '2026-11-15' → '11 月 15 日 · 周六'
String formatDayHeader(String dateKey) {
  final parsed = DateTime.tryParse(dateKey);
  if (parsed == null) return dateKey;
  const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  final weekday = weekdays[(parsed.weekday - 1) % 7];
  return '${parsed.month} 月 ${parsed.day} 日 · $weekday';
}

final searchProvider =
    FutureProvider.autoDispose.family<List<SearchHit>, String>((ref, query) {
      return ref.watch(dayBlockRepositoryProvider).search(query);
    });
