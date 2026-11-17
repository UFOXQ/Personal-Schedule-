import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../core/palette.dart';
import '../../data/backup.dart';
import '../../data/providers.dart';
import '../../domain/models/tblock.dart';
import '../../domain/now_marker.dart';
import '../../domain/layout/timeline_layout.dart';
import '../../platform/strip/strip_controller.dart';
import '../timeline/timeline_painter.dart';
import '../timeline/timeline_state.dart';
import '../widgets/number_slider.dart';
import 'interaction_modes.dart';
import 'lane_manager_sheet.dart';
import 'reminder_settings_sheet.dart';
import 'sync_sheet.dart';
import 'now_marker_picker.dart';
import '../onboarding/onboarding_page.dart';
import 'ui_prefs.dart';
import 'ui_scale.dart';
import 'ui_scale_sheet.dart';

/// 设置页：把不常用的东西都收进来，顶栏菜单只留入口。
///
/// 顶部有一块「实时预览」，改手柄大小 / 泳道间距 / 泳道顺序，下面这块小时间轴
/// 立刻跟着变，不用来回切页面看效果。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(interactionModesProvider);
    final prefs = ref.watch(uiPrefsProvider);
    final scale = ref.watch(uiScaleProvider);
    final lanes = ref.watch(timelineProvider).lanes;

    return Scaffold(
      backgroundColor: Palette.bg,
      appBar: AppBar(backgroundColor: Palette.bg, title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _LivePreview(prefs: prefs, lanes: lanes),
          _Section(
            title: '手感',
            children: [
              _StripSliderRow(
                label: '手柄大小',
                hint: '选中方块时上下两个箭头的粗细',
                value: prefs.handleScale,
                min: UiPrefs.minHandle,
                max: UiPrefs.maxHandle,
                step: 0.1,
                display: (v) => '${(v * 100).round()}%',
                onChanged: (v) =>
                    ref.read(uiPrefsProvider.notifier).setHandleScale(v),
              ),
              _StripSliderRow(
                label: '泳道间距',
                hint: '泳道之间留多少空；0 就是贴在一起',
                value: prefs.laneGapScale,
                min: UiPrefs.minLaneGap,
                max: UiPrefs.maxLaneGap,
                step: 0.1,
                display: (v) => '${(v * 8).round()} px',
                onChanged: (v) =>
                    ref.read(uiPrefsProvider.notifier).setLaneGapScale(v),
              ),
            ],
          ),
          _Section(
            title: '界面',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('看一眼新手引导'),
                subtitle: const Text('四个小页，讲清楚泳道、长按拖动和提醒'),
                trailing: const Icon(Icons.school_outlined, size: 20),
                onTap: () => showOnboarding(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('主题'),
                subtitle: Text(prefs.themeMode.label),
                trailing: const Icon(Icons.palette_outlined, size: 20),
                onTap: () => _pickTheme(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('界面大小'),
                subtitle: Text(UiScale.labelOf(scale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showUiScaleSheet(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('现在时刻标识'),
                subtitle: Text(
                  prefs.nowMarkerStyle == NowMarkerStyle.icon
                      ? '${prefs.nowMarkerStyle.label} · '
                          '${nowMarkerIconNames[prefs.nowMarkerIcon.clamp(0, nowMarkerIcons.length - 1)]}'
                      : prefs.nowMarkerStyle.label,
                ),
                trailing: NowMarkerPreview(
                  style: prefs.nowMarkerStyle,
                  icon: prefs.nowMarkerIcon,
                  colorIndex: prefs.nowMarkerColorIndex,
                  size: prefs.nowMarkerSize,
                  right: prefs.nowMarkerRight,
                  doodle: prefs.nowMarkerDoodle,
                  width: 96,
                  height: 30,
                ),
                onTap: () => showNowMarkerPicker(context, ref),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示缩放滑块'),
                subtitle: const Text('关掉后右侧不再有那条竖滑块，双指缩放还能用'),
                value: prefs.showZoomSlider,
                onChanged: (value) =>
                    ref.read(uiPrefsProvider.notifier).setShowZoomSlider(value),
              ),
            ],
          ),
          _Section(
            title: '交互',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('新建方块方式'),
                subtitle: Text(modes.create.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(interactionModesProvider.notifier).cycleCreate(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('优先级选择方式'),
                subtitle: Text(modes.priorityPicker.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ref
                    .read(interactionModesProvider.notifier)
                    .cyclePriorityPicker(),
              ),
            ],
          ),
          _Section(
            title: '泳道',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('管理泳道'),
                subtitle: Text(lanes.map((lane) => lane.name).join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLaneManagerSheet(context),
              ),
            ],
          ),
          _Section(
            title: '常驻显示',
            children: [
              if (Platform.isAndroid)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('手机常驻时间条'),
                  subtitle: const Text('通知栏里放一条今天的时间轴，红线随时间走'),
                  value: ref.watch(stripProvider).phone,
                  onChanged: (value) =>
                      ref.read(stripProvider.notifier).setPhoneEnabled(value),
                ),
              if (Platform.isWindows)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('电脑悬浮时间条'),
                  subtitle: const Text('右下角浮一个小条，按住可拖动、右键隐藏'),
                  value: ref.watch(stripProvider).desktop,
                  onChanged: (value) => ref
                      .read(stripProvider.notifier)
                      .setDesktopEnabled(value),
                ),
            ],
          ),
          _Section(
            title: '时间条样式',
            children: [
              _StripSliderRow(
                label: '文字大小',
                hint: '时间条上的字整体放大或缩小',
                value: prefs.stripTextScale,
                min: 0.8,
                max: 1.4,
                step: 0.1,
                display: (value) => '${(value * 100).round()}%',
                onChanged: (value) =>
                    ref.read(uiPrefsProvider.notifier).setStripTextScale(value),
              ),
              _StripSliderRow(
                label: '线路长度',
                hint: '中间那条线占多宽，短一点两边文字更宽松',
                value: prefs.stripLineRatio,
                min: 0.5,
                max: 1.0,
                step: 0.05,
                display: (value) => '${(value * 100).round()}%',
                onChanged: (value) =>
                    ref.read(uiPrefsProvider.notifier).setStripLineRatio(value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示左侧文字'),
                subtitle: const Text('现在做什么 / 前面没做完的'),
                value: prefs.stripShowLeft,
                onChanged: (value) =>
                    ref.read(uiPrefsProvider.notifier).setStripShowLeft(value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示右侧文字'),
                subtitle: const Text('接下来是什么'),
                value: prefs.stripShowRight,
                onChanged: (value) =>
                    ref.read(uiPrefsProvider.notifier).setStripShowRight(value),
              ),
            ],
          ),
          _Section(
            title: '数据',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('导出备份'),
                subtitle: const Text('存成一个 JSON 文件，换机、重装都能拿回来'),
                trailing: const Icon(Icons.save_alt, size: 20),
                onTap: () => _exportBackup(context, ref),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('恢复备份'),
                subtitle: const Text('按更新时间合并，不会把较新的行改旧'),
                trailing: const Icon(Icons.restore, size: 20),
                onTap: () => _restoreBackup(context, ref),
              ),
            ],
          ),
          _Section(
            title: '提醒与同步',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('到点提醒'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showReminderSettingsSheet(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('电脑 ↔ 手机同步'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showSyncSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);
      final file = await exportBackup(db);
      await Clipboard.setData(ClipboardData(text: file.path));
      messenger.showSnackBar(
        SnackBar(content: Text('已导出 ${file.rows} 行 → ${file.name}（路径已复制）')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final entries = await listBackups();
    if (!context.mounted) return;
    if (entries.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('还没有备份文件')));
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                '选一个备份恢复',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Palette.textPrimary,
                ),
              ),
            ),
            for (final entry in entries.take(12))
              ListTile(
                dense: true,
                title: Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: Palette.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${(entry.size / 1024).toStringAsFixed(0)} KB · '
                  '${entry.modified.toString().substring(0, 16)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Palette.textDim,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(entry.path),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.surfaceHigh,
        title: const Text('确定恢复？'),
        content: const Text('会把这个备份里更新的内容合并进来，本地更新的行不会被覆盖。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final db = ref.read(databaseProvider);
      final stats = await restoreBackup(db, picked);
      await ref.read(timelineProvider.notifier).reload();
      messenger.showSnackBar(SnackBar(content: Text('恢复完成：${stats.describe()}')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('恢复失败：$error')));
    }
  }
}

/// 设置页顶部的实时预览：一条压缩过的半天时间轴。
///
/// 用真实的 `TimelineLayout` + `TimelinePainter` 画，所以手柄大小、泳道间距、
/// 泳道顺序和取色都是「所见即所得」。
class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.prefs, required this.lanes});

  final UiPrefs prefs;
  final List<Lane> lanes;

  static const double _previewHeight = 210;

  /// 只画 5 小时窗口，而不是把一整天压进 200px —— 压扁了又细又丑，
  /// 也看不清手柄大小和泳道间距的变化。
  static const double _pxPerMin = 0.62;
  static const int _windowStartMin = 8 * 60 + 30;

  List<TBlock> _samples() {
    final ordered = lanes.isEmpty ? Lane.defaults : lanes;
    final titles = ['写周报', '健身', '读书'];
    final starts = [9 * 60, 10 * 60 + 20, 11 * 60 + 40];
    final durations = [60, 75, 90];
    final priorities = [Priority.a, Priority.b, Priority.d];
    return [
      for (var i = 0; i < titles.length && i < ordered.length; i++)
        TBlock(
          id: 'preview-$i',
          title: titles[i],
          lane: ordered[i],
          startMin: starts[i],
          durationMin: durations[i],
          priority: priorities[i],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _samples();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '实时预览',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Palette.textDim,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                lanes.isEmpty
                    ? '日常 · 打卡 · 临时'
                    : lanes.map((l) => l.name).join(' · '),
                style: TextStyle(fontSize: 11, color: Palette.textDim),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: _previewHeight,
              decoration: BoxDecoration(
                color: Palette.laneBg,
                border: Border.all(color: Palette.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = TimelineLayout.compute(
                    viewport: Size(constraints.maxWidth, _previewHeight),
                    pxPerMin: _pxPerMin,
                    blocks: blocks,
                    showTopInLane: true,
                    now: DateTime.now(),
                    laneOrder: lanes.isEmpty ? Lane.defaults : lanes,
                    laneGapScale: prefs.laneGapScale,
                  );
                  return CustomPaint(
                    size: Size(constraints.maxWidth, _previewHeight),
                    painter: TimelinePainter(
                      layout: layout,
                      scroll: _windowStartMin * _pxPerMin,
                      selectedId: blocks.isEmpty ? null : blocks.first.id,
                      showTopInLane: true,
                      handleScale: prefs.handleScale,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '这是一条 5 小时的时间轴（9:00–14:00），照当前设置实时画：拖滑块、改泳道顺序都会立刻变。',
            style: TextStyle(fontSize: 11, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Palette.textDim,
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _StripSliderRow extends StatelessWidget {
  const _StripSliderRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final double value;
  final double min;
  final double max;
  final double step;
  final String Function(double) display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NumberSlider(
            label: label,
            value: value,
            min: min,
            max: max,
            step: step,
            display: display,
            onChanged: onChanged,
            dialogTitle: '$label（数值）',
          ),
          Text(
            hint,
            style: TextStyle(fontSize: 11, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}

Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
  final current = ref.read(uiPrefsProvider).themeMode;
  final picked = await showModalBottomSheet<AppThemeMode>(
    context: context,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              '主题',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.textPrimary,
              ),
            ),
          ),
          for (final mode in AppThemeMode.values)
            ListTile(
              dense: true,
              title: Text(
                mode.label,
                style: TextStyle(fontSize: 14, color: Palette.textPrimary),
              ),
              trailing: mode == current ? const Icon(Icons.check, size: 18) : null,
              onTap: () => Navigator.of(sheetContext).pop(mode),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  await ref.read(uiPrefsProvider.notifier).setThemeMode(picked);
}

