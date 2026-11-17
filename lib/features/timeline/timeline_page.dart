import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../data/providers.dart';
import '../../data/repositories/library_repository.dart';
import '../../domain/models/tblock.dart';
import '../../domain/priority.dart';
import '../../domain/reminders.dart';
import '../../platform/notifications/reminder_scheduler.dart';
import '../../domain/models/day_jump.dart';
import '../calendar/calendar_page.dart';
import '../logs/completion_logs_page.dart';
import '../settings/reminder_settings_sheet.dart';
import '../settings/sync_sheet.dart';
import '../settings/interaction_modes.dart';
import '../settings/ui_scale_sheet.dart';
import '../composer/composer_page.dart';
import '../library/collection_editor_sheet.dart';
import '../library/library_page.dart';
import '../search/search_page.dart';
import '../settings/lane_manager_sheet.dart';
import '../../platform/quick_action.dart';
import '../../platform/strip/strip_controller.dart';
import '../settings/settings_page.dart';
import '../settings/doodle_editor.dart';
import '../settings/now_marker_picker.dart';
import '../onboarding/onboarding_page.dart';
import '../settings/ui_prefs.dart';
import '../widgets/time_selector.dart';
import 'evening_review_sheet.dart';
import '../settings/zoom_memory.dart';
import '../week/week_page.dart';
import 'quick_add_sheet.dart';
import 'block_edit_sheet.dart';
import 'quick_edit_sheet.dart';
import 'timeline_state.dart';
import 'timeline_view.dart';

/// 时间轴主页面：顶栏 + 置顶投影区 + 时间轴 + 选中信息条
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  Timer? _ticker;
  AppLifecycleListener? _lifecycleListener;
  bool _carryDialogOpen = false;

  /// 到点提醒的应用内横幅（桌面端主要靠它，系统 toast 不一定弹得出来）
  Reminder? _banner;
  StreamSubscription<Reminder>? _bannerSub;
  Timer? _bannerTimer;
  String? _undoMessage;
  Future<void> Function()? _undoAction;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (await UiPrefsNotifier.hasOnboarded()) return;
      if (!mounted) return;
      showOnboarding(context, ref);
    });
    // 「现在」线和死线倒计时每分钟刷新
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(timelineProvider.notifier).tickNow();
    });
    // 手机通知上的「快速记一条」：首次启动 / 回到前台时取一次动作
    _lifecycleListener = AppLifecycleListener(onResume: _handlePendingAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingAction());
    _bannerSub = ref.read(reminderSchedulerProvider).fired.listen((reminder) {
      if (!mounted) return;
      _bannerTimer?.cancel();
      setState(() => _banner = reminder);
      _bannerTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _banner = null);
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycleListener?.dispose();
    _bannerSub?.cancel();
    _bannerTimer?.cancel();
    _undoTimer?.cancel();
    super.dispose();
  }

  /// 有以前没做完的方块时，弹窗问「顺延还是丢掉」
  void _maybeShowCarryDialog(TimelineState state) {
    // 锁定时不打扰；解锁后的下一帧再问
    if (state.locked) return;
    if (state.carryOvers.isEmpty || _carryDialogOpen) return;
    final pending = state.carryOvers;
    _carryDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _carryDialogOpen = false;
        return;
      }
      final preview = pending
          .take(4)
          .map((c) => '· ${c.date} ${c.block.title}')
          .join('\n');
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Palette.surface,
          title: Text(
            '有 ${pending.length} 件事没做完',
            style: TextStyle(
              color: Palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending.length > 4 ? '$preview\n…' : preview,
                style: TextStyle(
                  color: Palette.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '顺延会照原时段复制到今天，并记下顺延次数。',
                style: TextStyle(color: Palette.textDim, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('later'),
              child: const Text('稍后'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('drop'),
              child: Text('丢弃', style: TextStyle(color: Palette.textDim)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: const Text('顺延到今天'),
            ),
          ],
        ),
      );
      _carryDialogOpen = false;
      if (!mounted) return;
      final notifier = ref.read(timelineProvider.notifier);
      switch (action) {
        case 'keep':
          await notifier.resolveCarryOvers(keep: true);
        case 'drop':
          await notifier.resolveCarryOvers(keep: false);
        default:
          notifier.postponeCarryOvers();
      }
    });
  }

  /// 打开编辑面板
  Future<void> _editBlock(String blockId, {bool focusTitle = false}) async {
    if (!ref.read(timelineProvider).canEdit) return;
    await showBlockEditor(context, blockId, focusTitle: focusTitle);
  }

  /// 空泳道自动收起：切完要让人看得出来发生了什么
  void _toggleZoomSlider() {
    final prefs = ref.read(uiPrefsProvider);
    ref.read(uiPrefsProvider.notifier).setShowZoomSlider(!prefs.showZoomSlider);
    _toast(prefs.showZoomSlider ? '已隐藏缩放滑块' : '已显示缩放滑块');
  }

  void _toggleAutoHideEmpty() {
    final notifier = ref.read(timelineProvider.notifier);
    final wasOn = ref.read(timelineProvider).autoHideEmptyLanes;
    notifier.toggleAutoHideEmptyLanes();
    final state = ref.read(timelineProvider);
    if (wasOn) {
      _toast('已关闭「自动收起空泳道」');
      return;
    }
    final autoHidden = state.effectiveHiddenLanes.difference(state.hiddenLanes);
    if (autoHidden.isEmpty) {
      _toast('三条泳道今天都有任务，暂时没有可收起的');
    } else {
      final names = autoHidden.map((lane) => lane.name).join('、');
      _toast('已收起空泳道：$names');
    }
  }

  /// 组合台：新建任务 / 合集，拖拽归组，长按投到某天
  Future<void> _openComposer() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ComposerPage()),
    );
    if (!mounted) return;
    ref.invalidate(collectionsProvider);
    await ref.read(timelineProvider.notifier).reload();
  }

  Future<void> _handlePendingAction() async {
    if (!mounted) return;
    final action = await takePendingAction();
    if (!mounted || action != 'quickadd') return;
    await _openQuickAdd();
  }

  Future<void> _openQuickAdd() async {
    final draft = await showQuickAddSheet(context);
    if (draft == null) return;
    final block = await ref.read(timelineProvider.notifier).addBlock(
          title: draft.title,
          lane: draft.lane,
          startMin: draft.startMin,
          durationMin: draft.durationMin,
          priority: draft.priority,
          dateKey: formatDateKey(draft.day),
        );
    if (block == null) {
      _toast('现在改不了（锁定中？）');
      return;
    }
    _toast('已加上「${draft.title}」');
  }

  Future<void> _openEvening() => showEveningReview(context, ref);

  Future<void> _openSettings() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
      );

  /// 界面大小
  /// 长按（手机）/ 右键（桌面）菜单
  Future<void> _showBlockMenu(TBlock block, Offset globalPosition) async {
    final state = ref.read(timelineProvider);
    if (!state.canEdit) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      Offset.zero & overlay.size,
    );
    final action = await showMenu<String>(
      context: context,
      position: position,
      color: Palette.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: _MenuItem(icon: Icons.edit_outlined, label: '编辑'),
        ),
        PopupMenuItem<String>(
          value: 'done',
          child: _MenuItem(icon: Icons.check_circle_outline, label: '标记完成'),
        ),
        PopupMenuItem<String>(
          value: 'carry',
          child: _MenuItem(icon: Icons.redo, label: '顺延到明天'),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          child: _MenuItem(icon: Icons.content_copy_outlined, label: '复制到明天'),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: _MenuItem(
            icon: Icons.delete_outline,
            label: '删除',
            color: Palette.top,
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    final notifier = ref.read(timelineProvider.notifier);
    switch (action) {
      case 'edit':
        await _editBlock(block.id);
      case 'done':
        notifier.select(block.id);
        await notifier.completeSelected();
      case 'carry':
        final createdId = await notifier.carryOverToNextDay(block.id);
        if (!mounted) return;
        if (createdId == null) {
          _toast('顺延失败');
        } else {
          _toastUndo('已顺延到明天', () async {
            await ref
                .read(timelineProvider.notifier)
                .undoCarryOver(block, createdId);
          });
        }
      case 'duplicate':
        await notifier.duplicateToNextDay(block.id);
        _toast('已复制到明天');
      case 'delete':
        notifier.deleteBlock(block.id);
        _toastUndo('已删除「${block.title}」', () async {
          await ref.read(timelineProvider.notifier).restoreBlock(block);
        });
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchPage()));
  }
  /// 双击方块：只改最常见的三样（标题 / 开始 / 时长）。
  Future<void> _quickEdit(String blockId) async {
    if (!ref.read(timelineProvider).canEdit) {
      _flashLockedHint();
      return;
    }
    await showQuickEditSheet(context, blockId);
  }
  /// 长按优先级小旗：直接点选 A/B/C/D
  Future<void> _pickPriority(TBlock block) async {
    if (!ref.read(timelineProvider).canEdit) {
      _flashLockedHint();
      return;
    }
    final mode = ref.read(interactionModesProvider).priorityPicker;
    final picked = mode == PriorityPickerMode.wheel
        ? await _pickPriorityWheel(block)
        : await _pickPriorityMenu(block);
    if (picked == null) return;
    ref.read(timelineProvider.notifier).setPriority(block.id, picked);
  }

  /// 方式一：底部列表，点一下就好
  Future<Priority?> _pickPriorityMenu(TBlock block) {
    return showModalBottomSheet<Priority>(
      context: context,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '优先级',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Palette.textPrimary,
                  ),
                ),
              ),
            ),
            for (final priority in Priority.values)
              ListTile(
                leading: Icon(Icons.flag, color: Palette.of(priority), size: 20),
                title: Text(
                  '${priority.label} 级',
                  style: TextStyle(color: Palette.textPrimary),
                ),
                trailing: priority == block.priority
                    ? Icon(Icons.check, size: 18, color: Palette.accent)
                    : null,
                onTap: () => Navigator.pop(sheetContext, priority),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 方式二：滚轮 —— 拖动中间那一格来选，松手前可以在 A/B/C/D 之间滑
  Future<Priority?> _pickPriorityWheel(TBlock block) {
    var current = block.priority;
    return showModalBottomSheet<Priority>(
      context: context,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '拖动滚轮选优先级',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Palette.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Palette.accent.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      itemExtent: 44,
                      diameterRatio: 1.6,
                      perspective: 0.003,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem:
                            Priority.values.indexOf(block.priority),
                      ),
                      onSelectedItemChanged: (index) {
                        current = Priority.values[index];
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: Priority.values.length,
                        builder: (context, index) {
                          final priority = Priority.values[index];
                          return Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: Palette.of(priority),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${priority.label} 级',
                                  style: TextStyle(
                                    color: Palette.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, current),
                      child: const Text('就用这个'),
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

  /// 轮换「新建方块」的触发方式，并告诉用户现在是什么
  /// 轮换「优先级选择」的交互方式
  /// 清空当天：按泳道多选，二次确认，清完给撤销
  Future<void> _confirmClear() async {
    final state = ref.read(timelineProvider);
    if (!state.canEdit) {
      _flashLockedHint();
      return;
    }
    final lanes = <Lane>{Lane.daily, Lane.habit, Lane.temp};
    var includeDone = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          backgroundColor: Palette.surface,
          title: const Text('清空时间轴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '勾选要清的泳道：',
                style: TextStyle(fontSize: 13, color: Palette.textSecondary),
              ),
              const SizedBox(height: 4),
              for (final lane in lanes)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: lanes.contains(lane),
                  title: Text(lane.name, style: const TextStyle(fontSize: 14)),
                  onChanged: (checked) => setLocal(() {
                    if (checked == true) {
                      lanes.add(lane);
                    } else {
                      lanes.remove(lane);
                    }
                  }),
                ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: includeDone,
                title: const Text('连已完成的也清掉', style: TextStyle(fontSize: 14)),
                onChanged: (value) => setLocal(() => includeDone = value),
              ),
              Text(
                '清空后可以用顶部的「撤销」找回来。',
                style: TextStyle(fontSize: 12, color: Palette.textDim),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Palette.top),
              child: const Text('清空'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final removed = await ref
        .read(timelineProvider.notifier)
        .clearBlocks(lanes: lanes, includeDone: includeDone);
    if (removed.isEmpty) {
      _toast('这几天没有可清空的方块');
      return;
    }
    _toastUndo('已清空 ${removed.length} 个方块', () async {
      final notifier = ref.read(timelineProvider.notifier);
      for (final block in removed) {
        await notifier.restoreBlock(block);
      }
    });
  }

  /// 带「撤销」的提示条：顶部 3 秒，不遮挡底部按钮，也不会连弹好几条
  void _toastUndo(String message, Future<void> Function() onUndo) {
    if (!mounted) return;
    _undoTimer?.cancel();
    setState(() {
      _undoMessage = message;
      _undoAction = onUndo;
    });
    _undoTimer = Timer(const Duration(seconds: 3), _hideUndo);
  }

  void _hideUndo() {
    _undoTimer?.cancel();
    _undoTimer = null;
    if (!mounted) return;
    if (_undoMessage == null) return;
    setState(() {
      _undoMessage = null;
      _undoAction = null;
    });
  }

  /// 截图/联调用的临时钩子：环境变量 `TNT_UI_DEMO=1` 打开编辑面板，
  /// `TNT_UI_DEMO_MODE=lock` 切到锁定态。正常运行不带这些变量就不会触发。
  static bool get _uiDemo =>
      !kIsWeb && Platform.environment['TNT_UI_DEMO'] == '1';
  static String get _uiDemoMode =>
      (!kIsWeb ? Platform.environment['TNT_UI_DEMO_MODE'] : null) ?? '';
  bool _demoDone = false;

  /// 演示用：收件箱为空时先放两条进去，再打开组合台
  Future<void> _demoOpenComposer() async {
    final inbox = ref.read(inboxRepositoryProvider);
    if (await inbox.count() == 0) {
      await inbox.add(
        title: '写周报',
        lane: Lane.temp,
        startMin: 14 * 60,
        durationMin: 60,
        priority: Priority.a,
      );
      await inbox.add(
        title: '拉伸',
        lane: Lane.habit,
        startMin: 19 * 60 + 30,
        durationMin: 30,
        priority: Priority.d,
      );
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ComposerPage(startInGrid: _uiDemoMode == 'composer2'),
      ),
    );
  }

  Future<void> _maybeRunUiDemo(TimelineState state) async {    if (!_uiDemo || _demoDone) return;
    if (state.loading || state.blocks.isEmpty) return;
    _demoDone = true;
    debugPrint('TNT demo: mode=$_uiDemoMode blocks=${state.blocks.length}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_uiDemoMode == 'lock') {
        ref.read(timelineProvider.notifier).toggleLock();
        return;
      }
      if (_uiDemoMode == 'library') {
        _openCollections();
        return;
      }
      if (_uiDemoMode == 'collection') {
        showCollectionEditor(context);
        return;
      }
      if (_uiDemoMode == 'search') {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SearchPage(initialQuery: '周报'),
            ),
          ),
        );
        return;
      }
      if (_uiDemoMode == 'handles') {
        ref.read(timelineProvider.notifier).select(state.blocks.first.id);
        ref
            .read(timelineProvider.notifier)
            .requestJumpTo(state.blocks.first.startMin);
        return;
      }
      if (_uiDemoMode == 'wheel') {
        final notifier = ref.read(interactionModesProvider.notifier);
        final block = state.blocks.first;
        unawaited(
          notifier.setPriorityPicker(PriorityPickerMode.wheel).then((_) {
            ref.read(timelineProvider.notifier).select(block.id);
            unawaited(_pickPriority(block));
          }),
        );
        return;
      }
      if (_uiDemoMode == 'marker') {
        showNowMarkerPicker(context, ref);
        return;
      }
      if (_uiDemoMode == 'timepicker') {
        unawaited(showTimeSelector(context, initialMinute: 9 * 60 + 30));
        return;
      }
      if (_uiDemoMode == 'timewheel') {
        unawaited(
          ref.read(uiPrefsProvider.notifier).setTimePickerMode(
                TimePickerMode.wheel,
              ),
        );
        unawaited(showTimeSelector(context, initialMinute: 9 * 60 + 30));
        return;
      }
      if (_uiDemoMode == 'onboard' || _uiDemoMode.startsWith('onboard')) {
        final page = int.tryParse(_uiDemoMode.replaceAll('onboard', '')) ?? 0;
        showOnboarding(context, ref, initialPage: page);
        return;
      }
      if (_uiDemoMode == 'doodle') {
        unawaited(showDoodleEditor(context));
        return;
      }
      if (_uiDemoMode == 'settings') {
        unawaited(_openSettings());
        return;
      }
      if (_uiDemoMode == 'lanes') {
        unawaited(showLaneManagerSheet(context));
        return;
      }
      if (_uiDemoMode == 'split') {
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          final notifier = ref.read(timelineProvider.notifier);
          final key = formatDateKey(DateTime.now());
          unawaited(notifier.addBlock(
            title: '写周报',
            lane: Lane.daily,
            startMin: 600,
            durationMin: 60,
            priority: Priority.a,
            dateKey: key,
          ));
          unawaited(notifier.addBlock(
            title: '方案评审',
            lane: Lane.daily,
            startMin: 630,
            durationMin: 75,
            priority: Priority.b,
            dateKey: key,
          ));
          notifier.requestJumpTo(600);
        });
        return;
      }
      if (_uiDemoMode == 'strip') {
        if (Platform.isAndroid) {
          unawaited(ref.read(stripProvider.notifier).setPhoneEnabled(true));
        } else {
          unawaited(ref.read(stripProvider.notifier).setDesktopEnabled(true));
        }
        return;
      }
      if (_uiDemoMode == 'plain') {
        ref.read(timelineProvider.notifier).requestJumpTo(13 * 60 + 40);
        return;
      }
      if (_uiDemoMode == 'select') {
        final block = state.blocks.first;
        final notifier = ref.read(timelineProvider.notifier);
        notifier.select(block.id);
        notifier.requestJumpTo(block.startMin);
        return;
      }
      if (_uiDemoMode == 'quickedit') {
        showQuickEditSheet(context, state.blocks.first.id);
        return;
      }
      if (_uiDemoMode == 'clear') {
        unawaited(_confirmClear());
        return;
      }
      if (_uiDemoMode == 'priority') {
        final block = state.blocks.first;
        ref.read(timelineProvider.notifier).select(block.id);
        unawaited(_pickPriority(block));
        return;
      }
      if (_uiDemoMode == 'undo') {
        final block = state.blocks.first;
        ref.read(timelineProvider.notifier).deleteBlock(block.id);
        _toastUndo('已删除「${block.title}」', () async {
          await ref.read(timelineProvider.notifier).restoreBlock(block);
        });
        return;
      }
      if (_uiDemoMode == 'hidelane') {
        ref.read(timelineProvider.notifier).toggleLaneHidden(Lane.temp);
        return;
      }
      if (_uiDemoMode == 'autohide') {
        ref.read(timelineProvider.notifier).toggleAutoHideEmptyLanes();
        return;
      }
      if (_uiDemoMode == 'composer' || _uiDemoMode == 'composer2') {
        unawaited(_demoOpenComposer());
        return;
      }
      if (_uiDemoMode == 'uiscale') {
        showUiScaleSheet(context);
        return;
      }
      if (_uiDemoMode == 'quickadd') {
        showQuickAddSheet(
          context,
          initialText: '明天 10:30 交周报 45分 A 打卡',
        );
        return;
      }
      if (_uiDemoMode == 'evening') {
        showEveningReview(context, ref);
        return;
      }
      if (_uiDemoMode == 'logs') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CompletionLogsPage()),
        );
        return;
      }
      if (_uiDemoMode == 'week') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WeekPage(initialDate: DateTime.now()),
          ),
        );
        return;
      }
      if (_uiDemoMode == 'reminder') {
        showReminderSettingsSheet(context);
        return;
      }
      if (_uiDemoMode == 'editor') {
        final id = state.blocks.first.id;
        ref.read(timelineProvider.notifier).select(id);
        showBlockEditor(context, id);
        return;
      }
      // 默认：编辑器
      final id = state.blocks.first.id;
      debugPrint('TNT demo: open editor for $id');
      ref.read(timelineProvider.notifier).select(id);
      showBlockEditor(context, id);
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// 锁定提示
  void _flashLockedHint() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('已锁定 · 只能查看，点右上角锁解锁'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openCollections() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LibraryPage()),
    );
    // 库页面里可能投入 / 改了东西，回来重载当天
    if (!mounted) return;
    await ref.read(timelineProvider.notifier).reload();
  }

  void _openLogs() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CompletionLogsPage()));
  }

  /// 打开「到点提醒」设置面板
  Future<void> _openReminders() => showReminderSettingsSheet(context);
  Future<void> _openSync() => showSyncSheet(context);

  /// 把方块拖到顶栏上方松手：问一句挪到哪天
  Future<void> _dropToOtherDay(TBlock block) async {
    final state = ref.read(timelineProvider);
    if (!state.canEdit) return;
    final today = DateTime.parse(state.dateKey);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '把「${block.title}」挪到哪天',
    );
    if (!mounted || picked == null) return;
    final key = formatDateKey(picked);
    if (key == state.dateKey) {
      _toast('还是这一天，没动');
      return;
    }
    final moved = await ref
        .read(timelineProvider.notifier)
        .moveToDate(block.id, key);
    if (!mounted) return;
    if (!moved) {
      _toast('挪不过去，可能已经不在今天了');
      return;
    }
    _toastUndo('已挪到 ${picked.month}/${picked.day}', () async {
      await ref.read(timelineProvider.notifier).restoreBlock(block);
    });
  }
  /// 打开月历，选一天后跳到那天（周视图里点色块还会带上具体时刻）
  Future<void> _openCalendar() async {
    final current = ref.read(timelineProvider).dateKey;
    final jump = await Navigator.of(context).push<DayJump>(
      MaterialPageRoute<DayJump>(
        builder: (_) => CalendarPage(initialDate: DateTime.parse(current)),
      ),
    );
    if (!mounted || jump == null) return;
    final notifier = ref.read(timelineProvider.notifier);
    await notifier.goToDate(jump.date);
    final minute = jump.minute;
    if (minute != null) notifier.requestJumpTo(minute);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    _maybeShowCarryDialog(state);
    unawaited(_maybeRunUiDemo(state));
    // 时间轴一变就把最新数据推给手机常驻通知 / 桌面悬浮条
    unawaited(Future<void>.microtask(() {
      ref.read(stripProvider.notifier).updateSource(
            blocks: state.blocks,
            hiddenLanes: state.effectiveHiddenLanes,
          );
    }));
    final topBlocks = sortByPriority(
      state.blocks.where((b) => isTopPriority(b, state.now)),
      state.now,
    );
    final selected = state.selected;

    final isNarrow = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      bottomNavigationBar: isNarrow
          ? NavigationBar(
              backgroundColor: Palette.surface,
              indicatorColor: Palette.accent.withValues(alpha: 0.22),
              selectedIndex: 0,
              onDestinationSelected: (index) {
                if (index == 1) {
                  _openComposer();
                } else if (index == 2) {
                  _openCalendar();
                } else if (index == 3) {
                  _openCollections();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.view_timeline_outlined),
                  label: '时间轴',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inbox_outlined),
                  label: '收件箱',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: '日历',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  label: '库',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  dateKey: state.dateKey,
                  now: state.now,
                  showTopInLane: state.showTopInLane,
                  onPrevDay: () =>
                      ref.read(timelineProvider.notifier).shiftDay(-1),
                  onNextDay: () =>
                      ref.read(timelineProvider.notifier).shiftDay(1),
                  onToday: () => ref.read(timelineProvider.notifier).goToday(),
                  onOpenCalendar: _openCalendar,
                  onOpenReminders: _openReminders,
                  onOpenSync: _openSync,
                  onToggleTopInLane: () =>
                      ref.read(timelineProvider.notifier).toggleShowTopInLane(),
                  onOpenCollections: _openCollections,
                  onOpenLogs: _openLogs,
                  hiddenLanes: state.hiddenLanes,
                  onToggleLaneHidden: (lane) =>
                      ref.read(timelineProvider.notifier).toggleLaneHidden(lane),
                  onToggleLaneHiddenById: (id) => ref
                      .read(timelineProvider.notifier)
                      .toggleLaneHiddenById(id),
                  lanes: state.lanes,
                  showLocked: state.locked,
                  onToggleLock: () {
                    ref.read(timelineProvider.notifier).toggleLock();
                    if (!state.locked) _flashLockedHint();
                  },
                  onQuickAdd: _openQuickAdd,
                  autoHideEmpty: state.autoHideEmptyLanes,
                  onToggleAutoHideEmpty: () => _toggleAutoHideEmpty(),
                showZoomSlider: ref.watch(uiPrefsProvider).showZoomSlider,
                onToggleZoomSlider: _toggleZoomSlider,
                  onClearDay: _confirmClear,

                  onOpenComposer: _openComposer,
                  onOpenSettings: _openSettings,
                  onOpenEvening: _openEvening,
                  onOpenSearch: _openSearch,
                ),
                if (topBlocks.isNotEmpty)
                  _TopDock(
                    blocks: topBlocks,
                    now: state.now,
                    selectedId: state.selectedId,
                    onTap: (id) =>
                        ref.read(timelineProvider.notifier).select(id),
                  ),
                Expanded(
                  child: TimelineView(
                    onEditBlock: _editBlock,
                    onEditNewBlock: (id) => _editBlock(id, focusTitle: true),
                    onBlockMenu: _showBlockMenu,
                    onQuickEdit: _quickEdit,
                    onDropToOtherDay: _dropToOtherDay,
                    allowLongPressCreate:
                        ref.watch(interactionModesProvider).allowLongPressCreate,
                    allowDoubleTapCreate:
                        ref.watch(interactionModesProvider).allowDoubleTapCreate,
                    initialPxPerMin: ref.read(zoomProvider),
              onZoomChanged: (value) =>
                  ref.read(zoomProvider.notifier).set(value),
                  ),
                ),
                if (selected != null)
                  _SelectedBar(
                    block: selected,
                    now: state.now,
                    locked: state.locked,
                    onEdit: () => _editBlock(selected.id),
                    onCyclePriority: () => ref
                        .read(timelineProvider.notifier)
                        .cyclePriority(selected.id),
                    onPickPriority: () => _pickPriority(selected),
                    onDelete: () => ref
                        .read(timelineProvider.notifier)
                        .deleteBlock(selected.id),
                    onClose: () =>
                        ref.read(timelineProvider.notifier).select(null),
                  ),
              ],
            ),
            // 大号完成按钮：选中方块后浮在右下拇指区
            if (selected != null && state.canEdit)
              Positioned(
                right: 18,
                bottom: 96,
                child: _BigCompleteButton(
                  onTap: () async {
                    final title = selected.title;
                    await ref.read(timelineProvider.notifier).completeSelected();
                    _toast('已完成「$title」');
                  },
                ),
              ),
            if (state.locked)
              Positioned(
                left: 0,
                right: 0,
                bottom: 74,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.surfaceHigh.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Palette.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 13,
                            color: Palette.textDim,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '已锁定 · 只能查看',
                            style: TextStyle(
                              color: Palette.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_banner != null || _undoMessage != null)
              Positioned(
                left: 12,
                right: 12,
                top: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_undoMessage != null)
                      _UndoBar(
                        message: _undoMessage!,
                        onUndo: () {
                          final action = _undoAction;
                          _hideUndo();
                          if (action != null) unawaited(action());
                        },
                        onClose: _hideUndo,
                      ),
                    if (_undoMessage != null && _banner != null)
                      const SizedBox(height: 8),
                    if (_banner != null)
                      _ReminderBanner(
                        reminder: _banner!,
                        onClose: () {
                          _bannerTimer?.cancel();
                          setState(() => _banner = null);
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 到点提醒横幅 ──────────────────────────────────────────────
class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.reminder, required this.onClose});

  final Reminder reminder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Palette.top.withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.alarm, color: Palette.top, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Palette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reminder.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '知道了',
              onPressed: onClose,
              icon: Icon(Icons.close, size: 18, color: Palette.textDim),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 顶栏 ──────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.dateKey,
    required this.now,
    required this.showTopInLane,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onToday,
    required this.onOpenCalendar,
    required this.onOpenReminders,
    required this.onOpenSync,
    required this.onToggleTopInLane,
    required this.onOpenCollections,
    required this.onOpenLogs,
    required this.hiddenLanes,
    required this.onToggleLaneHidden,
    required this.onToggleLaneHiddenById,
    required this.lanes,
    required this.showLocked,
    required this.onToggleLock,
    required this.onQuickAdd,
    required this.autoHideEmpty,
    required this.onToggleAutoHideEmpty,
    required this.showZoomSlider,
    required this.onToggleZoomSlider,
    required this.onOpenComposer,
    required this.onOpenSettings,
    required this.onOpenEvening,
    required this.onOpenSearch,
    required this.onClearDay,

  });

  final String dateKey;
  final DateTime now;
  final bool showTopInLane;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenSync;
  final VoidCallback onToggleTopInLane;
  final VoidCallback onOpenCollections;
  final VoidCallback onOpenLogs;
  final Set<Lane> hiddenLanes;
  final ValueChanged<Lane> onToggleLaneHidden;
  final ValueChanged<String> onToggleLaneHiddenById;
  final List<Lane> lanes;
  final bool showLocked;
  final VoidCallback onToggleLock;
  final VoidCallback onQuickAdd;
  final bool autoHideEmpty;
  final VoidCallback onToggleAutoHideEmpty;
  final bool showZoomSlider;
  final VoidCallback onToggleZoomSlider;
  final VoidCallback onOpenComposer;
  final VoidCallback onOpenSettings;

  /// 晚间小结：今天没做完的批量留到明天 / 丢掉
  final VoidCallback onOpenEvening;

  final VoidCallback onOpenSearch;
  final VoidCallback onClearDay;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final day = DateTime.parse(dateKey);
    final isToday = dateKey == formatDateKey(now);
    final dateLabel =
        '${day.month} 月 ${day.day} 日 · 周${weekdays[day.weekday - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '今天' : '周${weekdays[day.weekday - 1]}',
                  style: TextStyle(
                    color: Palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (showLocked) ...[
                      // 锁定态在标题下面给个明确的红标，否则很容易忘了自己锁着
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.top.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Palette.top.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: Palette.top),
                            SizedBox(width: 3),
                            Text(
                              '已锁定',
                              style: TextStyle(
                                fontSize: 10,
                                color: Palette.top,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _DayArrow(
                      icon: Icons.chevron_left,
                      tooltip: '前一天',
                      onTap: onPrevDay,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: (details) {
                        final vx = details.primaryVelocity ?? 0;
                        if (vx > 120) {
                          onPrevDay();
                        } else if (vx < -120) {
                          onNextDay();
                        }
                      },
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          color: Palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _DayArrow(
                      icon: Icons.chevron_right,
                      tooltip: '后一天',
                      onTap: onNextDay,
                    ),
                    if (!isToday)
                      TextButton(
                        onPressed: onToday,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 24),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '回到今天',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _TopIcon(
            icon: Icons.bolt,
            tooltip: '一句话加一条',
            onTap: onQuickAdd,
          ),
          // 窄屏上「日历 / 库」已经放进底部导航，顶栏不再重复放，免得挤成一片
          if (MediaQuery.sizeOf(context).width >= 640) ...[
            _TopIcon(
              icon: Icons.calendar_month_outlined,
              tooltip: '日历',
              onTap: onOpenCalendar,
            ),
            _TopIcon(
              icon: Icons.playlist_add,
              tooltip: '把集合整包投入当天',
              onTap: onOpenCollections,
            ),
          ],
          _TopIcon(
            icon: Icons.notifications_none,
            tooltip: '到点提醒',
            onTap: onOpenReminders,
          ),
          _TopIcon(icon: Icons.sync, tooltip: '电脑 ↔ 手机同步', onTap: onOpenSync),
          PopupMenuButton<String>(
            tooltip: '更多',
            color: Palette.surfaceHigh,
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'evening':
                  onOpenEvening();
                case 'logs':
                  onOpenLogs();
                case 'toggle-top':
                  onToggleTopInLane();
                case final hide when hide.startsWith('hide-'):
                  onToggleLaneHiddenById(hide.substring(5));
                case 'auto-hide-empty':
                  onToggleAutoHideEmpty();
                case 'search':
                  onOpenSearch();
                case 'composer':
                  onOpenComposer();
                case 'zoom-slider':
                  onToggleZoomSlider();
                case 'clear-day':
                  onClearDay();
                case 'settings':
                  onOpenSettings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'evening',
                child: _MenuItem(
                  icon: Icons.nightlight_round,
                  label: '今天收个尾',
                ),
              ),
              const PopupMenuItem<String>(
                value: 'search',
                child: _MenuItem(icon: Icons.search, label: '搜索任务'),
              ),
              PopupMenuItem<String>(
                value: 'logs',
                child: _MenuItem(icon: Icons.history, label: '完成记录'),
              ),
              PopupMenuItem<String>(
                value: 'toggle-top',
                child: _MenuItem(icon: Icons.push_pin_outlined, label: '置顶项也在原泳道显示'),
              ),
              PopupMenuDivider(),
              for (final lane in lanes)
                PopupMenuItem<String>(
                  value: 'hide-${lane.id}',
                  child: _MenuItem(
                    icon: hiddenLanes.contains(lane)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    label: hiddenLanes.contains(lane)
                        ? '显示「${lane.name}」泳道'
                        : '隐藏「${lane.name}」泳道',
                  ),
                ),
              PopupMenuItem<String>(
                value: 'auto-hide-empty',
                child: _MenuItem(
                  icon: autoHideEmpty
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  label: autoHideEmpty ? '空泳道已自动收起' : '自动收起空泳道',
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'composer',
                child: _MenuItem(
                  icon: Icons.inbox_outlined,
                  label: '收件箱 · 组合台',
                ),
              ),
              PopupMenuItem<String>(
                value: 'zoom-slider',
                child: _MenuItem(
                  icon: showZoomSlider
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  label: showZoomSlider ? '隐藏缩放滑块' : '显示缩放滑块',
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: _MenuItem(
                  icon: Icons.tune,
                  label: '设置（手感 / 泳道 / 交互）',
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'clear-day',
                child: _MenuItem(
                  icon: Icons.delete_sweep_outlined,
                  label: '清空时间轴…',
                  color: Palette.top,
                ),
              ),

            ],
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: Palette.textSecondary,
              ),
            ),
          ),
          _TopIcon(
            icon: showLocked ? Icons.lock : Icons.lock_open_outlined,
            tooltip: showLocked ? '已锁定（点击解锁）' : '锁定：只能滑看，不会误改',
            onTap: onToggleLock,
            color: showLocked ? Palette.top : Palette.textDim,
          ),
        ],
      ),
    );
  }
}

class _DayArrow extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _DayArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 16,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Icon(icon, size: 16, color: Palette.textDim),
        ),
      ),
    );
  }
}

// ── 顶栏小图标（紧凑一点，手机上放得下 5 个） ────────────────
class _TopIcon extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _TopIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color, size: 21),
    );
  }
}

// ── 置顶投影区 ────────────────────────────────────────────────
class _TopDock extends StatelessWidget {
  const _TopDock({
    required this.blocks,
    required this.now,
    required this.selectedId,
    required this.onTap,
  });

  final List<TBlock> blocks;
  final DateTime now;
  final String? selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          itemCount: blocks.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final block = blocks[index];
            final selected = block.id == selectedId;
            final deadline = deadlineLabel(block, now);
            return GestureDetector(
              onTap: () => onTap(block.id),
              child: Container(
                width: 178,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Palette.top.withValues(alpha: 0.55),
                    width: selected ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.top.withValues(alpha: 0.10),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.top,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '置顶',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            block.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Palette.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${formatMinute(block.startMin)} · ${formatDuration(block.durationMin)}',
                      style: TextStyle(
                        color: Palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      deadline.isEmpty
                          ? '${block.priority.label} 级 · ${block.lane.name}'
                          : '${block.priority.label} 级 · $deadline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: deadline.isEmpty ? Palette.textDim : Palette.top,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 选中信息条 ────────────────────────────────────────────────
class _SelectedBar extends StatelessWidget {
  const _SelectedBar({
    required this.block,
    required this.now,
    required this.locked,
    required this.onEdit,
    required this.onCyclePriority,
    required this.onPickPriority,
    required this.onDelete,
    required this.onClose,
  });

  final TBlock block;
  final DateTime now;
  final bool locked;
  final VoidCallback onEdit;
  final VoidCallback onCyclePriority;
  final VoidCallback onPickPriority;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = Palette.ofBlock(block, isTopPriority(block, now));
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        border: Border(top: BorderSide(color: Palette.line)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
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
                    color: Palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${block.lane.name} · ${formatRange(block.startMin, block.durationMin)} · ${formatDuration(block.durationMin)}'
                  '${block.isCarried ? ' · 顺延 ${block.carryCount} 次' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: locked ? '已锁定，解锁后可编辑' : '编辑（时间/时长/死线/优先级）',
            onPressed: locked ? null : onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: Palette.textPrimary,
              size: 20,
            ),
          ),
          // 小旗：点一下循环、长按直选。这里刻意不用 IconButton ——
          // 它的 tooltip 会吃掉长按手势，手机上表现为「长按没反应」
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: locked ? null : onCyclePriority,
            onLongPress: locked ? null : onPickPriority,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.flag_outlined,
                color: locked ? Palette.textDim : color,
                size: 20,
              ),
            ),
          ),
          IconButton(
            tooltip: locked ? '已锁定' : '删除',
            onPressed: locked ? null : onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Palette.textSecondary,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: '取消选中',
            onPressed: onClose,
            icon: Icon(Icons.close, color: Palette.textDim, size: 20),
          ),
        ],
      ),
    );
  }
}


// ── 菜单项 ────────────────────────────────────────────────────
/// 顶部撤销条：3 秒后自动消失，点「撤销」立刻回滚
class _UndoBar extends StatelessWidget {
  const _UndoBar({
    required this.message,
    required this.onUndo,
    required this.onClose,
  });

  final String message;
  final VoidCallback onUndo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Palette.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.undo, size: 16, color: Palette.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Palette.textPrimary),
              ),
            ),
            TextButton(
              onPressed: onUndo,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: Palette.accent,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('撤销'),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
              color: Palette.textDim,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Palette.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 17, color: tint),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color ?? Palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── 大号完成按钮 ──────────────────────────────────────────────
class _BigCompleteButton extends StatelessWidget {
  const _BigCompleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Palette.accent,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF0B1220),
            size: 30,
          ),
        ),
      ),
    );
  }
}
