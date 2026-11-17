import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/providers.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/tblock.dart';

/// 集合编辑器：新建 / 修改一个「整包投放」的集合。
///
/// 返回 true 表示保存成功，调用方自己去刷新列表。
Future<bool?> showCollectionEditor(
  BuildContext context, {
  String? collectionId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CollectionEditor(collectionId: collectionId),
  );
}


class _CollectionEditor extends ConsumerStatefulWidget {
  const _CollectionEditor({this.collectionId});

  final String? collectionId;

  @override
  ConsumerState<_CollectionEditor> createState() => _CollectionEditorState();
}

class _CollectionEditorState extends ConsumerState<_CollectionEditor> {
  final TextEditingController _name = TextEditingController();
  final List<_DraftItem> _items = [];
  bool _busy = false;
  bool _loaded = false;
  String? _error;

  bool get _isEdit => widget.collectionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    } else {
      _loaded = true;
      _items.add(_DraftItem.empty(startMin: 9 * 60));
    }
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(libraryRepositoryProvider);
    final id = widget.collectionId!;
    final collections = await repo.collections();
    final name = collections
        .where((c) => c.id == id)
        .map((c) => c.name)
        .firstOrNull;
    final seeds = await repo.collectionSeeds(id);
    if (!mounted) return;
    setState(() {
      _name.text = name ?? '';
      _items
        ..clear()
        ..addAll(_DraftItem.fromSeeds(seeds));
      if (_items.isEmpty) _items.add(_DraftItem.empty(startMin: 9 * 60));
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '给这个集合起个名字');
      return;
    }
    final seeds = <CollectionSeedItem>[];
    for (final item in _items) {
      final title = item.title.text.trim();
      if (title.isEmpty) continue;
      seeds.add(
        CollectionSeedItem(
          title: title,
          lane: item.lane,
          startMin: item.startMin,
          durationMin: item.durationMin,
          priority: item.priority,
        ),
      );
    }
    if (seeds.isEmpty) {
      setState(() => _error = '至少加一件事');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(libraryRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateCollection(
          id: widget.collectionId!,
          name: name,
          items: seeds,
        );
      } else {
        await repo.createCollectionSimple(name: name, items: seeds);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '保存失败：$error';
      });
    }
  }

  Future<void> _delete() async {
    final id = widget.collectionId;
    if (id == null) return;
    setState(() => _busy = true);
    await ref.read(libraryRepositoryProvider).deleteCollection(id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 12, 0),
              child: Row(
                children: [
                  Text(
                    _isEdit ? '编辑集合' : '新建集合',
                    style: TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: Palette.textDim,
                  ),
                ],
              ),
            ),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _name,
                        enabled: !_busy,
                        style: TextStyle(
                          color: Palette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _inputDecoration('集合名称，比如「早间流程」'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '里面有什么',
                            style: TextStyle(
                              color: Palette.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '整包投放时按这些时刻摆进时间轴',
                            style: TextStyle(
                              color: Palette.textDim.withValues(alpha: 0.9),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _items.length; i++)
                        _ItemCard(
                          key: ValueKey(_items[i].key),
                          item: _items[i],
                          enabled: !_busy,
                          onChanged: () => setState(() {}),
                          onRemove: _items.length <= 1
                              ? null
                              : () {
                                  setState(() {
                                    _items.removeAt(i).dispose();
                                  });
                                },
                        ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                final last = _items.isEmpty
                                    ? 9 * 60
                                    : _items.last.startMin +
                                          _items.last.durationMin;
                                _items.add(
                                  _DraftItem.empty(
                                    startMin: last.clamp(0, 22 * 60),
                                  ),
                                );
                              }),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('再加一件事'),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Palette.top,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: Palette.line,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Palette.line)),
      ),
      child: Row(
        children: [
          if (_isEdit)
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('删除'),
              style: TextButton.styleFrom(foregroundColor: Palette.top),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _busy ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: Palette.accent,
              foregroundColor: Palette.bg,
            ),
            child: _busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.bg,
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Palette.textDim, fontSize: 13),
    filled: true,
    fillColor: Palette.surfaceHigh,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}

/// 编辑中的一条：标题 + 泳道 + 开始 + 时长 + 优先级
class _DraftItem {
  _DraftItem({
    required this.key,
    required this.title,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    required this.priority,
  });

  factory _DraftItem.empty({required int startMin}) => _DraftItem(
    key: DateTime.now().microsecondsSinceEpoch.toString(),
    title: TextEditingController(),
    lane: Lane.daily,
    startMin: startMin,
    durationMin: 30,
    priority: Priority.c,
  );

  static List<_DraftItem> fromSeeds(List<CollectionSeedItem> seeds) {
    return [
      for (final seed in seeds)
        _DraftItem(
          key: DateTime.now().microsecondsSinceEpoch.toString() +
              seed.title.hashCode.toString(),
          title: TextEditingController(text: seed.title),
          lane: seed.lane,
          startMin: seed.startMin,
          durationMin: seed.durationMin,
          priority: seed.priority,
        ),
    ];
  }

  final String key;
  final TextEditingController title;
  Lane lane;
  int startMin;
  int durationMin;
  Priority priority;

  String get rangeLabel => formatRange(startMin, durationMin);

  void dispose() => title.dispose();
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  final _DraftItem item;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: Palette.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.title,
                  enabled: enabled,
                  style: TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '这件事叫什么',
                    hintStyle: TextStyle(color: Palette.textDim, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                color: Palette.textDim,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniDropdown<Lane>(
                value: item.lane,
                enabled: enabled,
                values: Lane.defaults,
                label: (lane) => lane.name,
                onChanged: (value) {
                  item.lane = value;
                  onChanged();
                },
              ),
              _TimeChip(
                label: formatMinute(item.startMin),
                enabled: enabled,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: item.startMin ~/ 60,
                      minute: item.startMin % 60,
                    ),
                  );
                  if (picked == null) return;
                  item.startMin = (picked.hour * 60 + picked.minute).clamp(
                    0,
                    kMinutesPerDay - kMinDuration,
                  );
                  onChanged();
                },
              ),
              _Stepper(
                label: formatDuration(item.durationMin),
                enabled: enabled,
                onMinus: () {
                  item.durationMin = (item.durationMin - 15).clamp(
                    kMinDuration,
                    12 * 60,
                  );
                  onChanged();
                },
                onPlus: () {
                  item.durationMin = (item.durationMin + 15).clamp(
                    kMinDuration,
                    12 * 60,
                  );
                  onChanged();
                },
              ),
              _MiniDropdown<Priority>(
                value: item.priority,
                enabled: enabled,
                values: Priority.values,
                label: (p) => '${p.label} 级',
                color: (p) => Palette.of(p),
                onChanged: (value) {
                  item.priority = value;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _TimeChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Palette.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Palette.textSecondary,
            fontSize: 11.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _Stepper({
    required this.label,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icon(Icons.remove, onMinus),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              style: TextStyle(
                color: Palette.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
          _icon(Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, VoidCallback onTap) => InkResponse(
    onTap: enabled ? onTap : null,
    radius: 14,
    child: Padding(
      padding: EdgeInsets.all(5),
      child: Icon(icon, size: 13, color: Palette.textSecondary),
    ),
  );
}

class _MiniDropdown<T> extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _MiniDropdown({
    required this.value,
    required this.enabled,
    required this.values,
    required this.label,
    required this.onChanged,
    this.color,
  });

  final T value;
  final bool enabled;
  final List<T> values;
  final String Function(T) label;
  final Color Function(T)? color;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tint = color == null ? Palette.textSecondary : color!(value);
    return PopupMenuButton<T>(
      enabled: enabled,
      tooltip: '',
      color: Palette.surfaceHigh,
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final v in values)
          PopupMenuItem<T>(
            value: v,
            height: 38,
            child: Text(
              label(v),
              style: TextStyle(
                color: color == null ? Palette.textPrimary : color!(v),
                fontSize: 12.5,
              ),
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Palette.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: TextStyle(color: tint, fontSize: 11.5),
            ),
            SizedBox(width: 3),
            Icon(Icons.arrow_drop_down, size: 16, color: tint),
          ],
        ),
      ),
    );
  }
}

/// 「投入今天」的小入口，库页面用
class CollectionActionChip extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  CollectionActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Palette.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tint ?? Palette.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: tint ?? Palette.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
