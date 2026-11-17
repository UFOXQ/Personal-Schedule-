import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../../domain/layout/lane_reveal.dart';
import '../../domain/layout/timeline_layout.dart';
import '../../domain/models/tblock.dart';
import '../settings/ui_prefs.dart';
import 'timeline_painter.dart';
import 'timeline_state.dart';

/// 手势当前在干什么
enum _DragMode { none, scroll, move, resize, resizeStart }

/// 时间轴本体：一块 CustomPaint + 一套手势。
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({
    super.key,
    this.onEditBlock,
    this.onEditNewBlock,
    this.onBlockMenu,
    this.onQuickEdit,
    this.initialPxPerMin = 1.5,
    this.onZoomChanged,
    this.onDropToOtherDay,
    this.allowLongPressCreate = true,
    this.allowDoubleTapCreate = true,
  });

  /// 双击方块 / 选中条上的「编辑」都走这里
  final ValueChanged<String>? onEditBlock;

  /// 刚新建出来的方块：编辑面板要把焦点放在标题上
  final ValueChanged<String>? onEditNewBlock;

  /// 长按方块（手机）或右键（桌面）弹出菜单
  final void Function(TBlock block, Offset globalPosition)? onBlockMenu;

  /// 双击方块：弹「快速修改」（标题 + 开始 + 时长）
  final ValueChanged<String>? onQuickEdit;

  /// 上一次用过的缩放倍数
  final double initialPxPerMin;

  /// 缩放变了（捏合结束、点缩放条），交给页面记到本地
  final ValueChanged<double>? onZoomChanged;

  /// 把方块拖到顶栏上方松手：让外面问「移到哪天」
  final ValueChanged<TBlock>? onDropToOtherDay;

  /// 长按空白处新建方块（默认开）
  final bool allowLongPressCreate;

  /// 双击空白处新建方块（默认开）
  final bool allowDoubleTapCreate;

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView>
    with SingleTickerProviderStateMixin {
  static const double _minPxPerMin = 0.6;
  static const double _maxPxPerMin = 4.0;

  /// 手要移动这么多像素才算「开始拖」，避免一按就动
  static const double _dragSlop = 6;

  late double _pxPerMin = widget.initialPxPerMin.clamp(
    _minPxPerMin,
    _maxPxPerMin,
  );
  double _scroll = 0;
  bool _didInitScroll = false;

  Size _viewport = Size.zero;
  TimelineLayout? _layout;

  _DragMode _mode = _DragMode.none;
  String? _activeId;
  bool _armed = false;

  // ── 长按拿起 / 拖动（触摸）状态 ──────────────────────────────
  int _pointersDown = 0;
  Timer? _pressTimer;
  int? _pressPointer;
  Offset _pressLocal = Offset.zero;
  String? _pressBlockId;
  String? _lastTapId;
  int _lastTapMs = 0;
  int _lastBlankTapMs = 0;
  Offset _lastBlankTapPos = Offset.zero;
  bool _pickedUp = false;
  bool _pressMoved = false;
  bool _ignoreNextTap = false;
  _DragMode _pickedUpMode = _DragMode.none;
  Offset _pickStartLocal = Offset.zero;
  double _pickStartScroll = 0;
  int _pickOriginStart = 0;
  int _pickOriginDuration = 30;
  bool _dropForDay = false;

  /// 拖动起点快照：用相对位移算，滚动位置一变也不会跳
  double _dragStartY = 0;
  double _dragStartScroll = 0;
  int _originStartMin = 0;
  int _originDurationMin = 30;

  double _pinchAnchorMin = 0;
  double _pinchStartPx = 1.5;

  /// 拖动时临时展开的泳道（自动收起开着的时候，把方块拖到左右边缘就能
  /// 把被收起的泳道「叫」出来，松手后恢复收起）
  final Set<Lane> _tempRevealed = <Lane>{};

  /// 离边缘这么近就算「想往那边拖」
  static const double _edgeZone = 34;

  late final AnimationController _fling;
  Simulation? _flingSim;

  @override
  void initState() {
    super.initState();
    _fling = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (_flingSim == null) return;
        setState(() => _scroll = _clampScroll(_fling.value));
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _flingSim = null;
        }
      });
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _fling.dispose();
    super.dispose();
  }

  double get _contentViewportHeight =>
      math.max(0, _viewport.height - TimelineLayout.headerHeight);

  double get _maxScroll => math.max(
    0,
    kMinutesPerDay * _pxPerMin +
        TimelineLayout.bottomPadding -
        _contentViewportHeight,
  );

  double _clampScroll(double value) => value.clamp(0.0, _maxScroll);

  Offset _toContent(Offset local) =>
      Offset(local.dx, local.dy - TimelineLayout.headerHeight + _scroll);

  void _stopFling() {
    _flingSim = null;
    _fling.stop();
  }

  void _startFling(double velocity) {
    if (velocity.abs() < 180) return;
    _flingSim = ClampingScrollSimulation(
      position: _scroll,
      velocity: velocity,
      friction: 0.02,
    );
    _fling.animateWith(_flingSim!);
  }

  // ── 手势 ────────────────────────────────────────────────────
  /// 桌面端：鼠标滚轮滚动时间轴。
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _stopFling();
    setState(() => _scroll = _clampScroll(_scroll + event.scrollDelta.dy));
  }

  void _onScaleStart(ScaleStartDetails details) {
    // 长按拖拽自己接管了，这时候别再让 Scale 抢
    if (_pickedUp) return;
    _stopFling();
    final layout = _layout;
    if (layout == null) return;

    _armed = false;
    _mode = _DragMode.none;

    if (details.pointerCount >= 2) {
      final focal = details.localFocalPoint;
      _pinchStartPx = _pxPerMin;
      _pinchAnchorMin = _toContent(focal).dy / _pxPerMin;
      return;
    }

    final local = details.localFocalPoint;
    if (local.dy < TimelineLayout.headerHeight) {
      _mode = _DragMode.scroll;
      return;
    }

    final content = _toContent(local);
    final hit = layout.hitTest(content);
    if (hit == null) {
      _mode = _DragMode.scroll;
      return;
    }

    final state = ref.read(timelineProvider);
    final notifier = ref.read(timelineProvider.notifier);
    notifier.select(hit.block.id);

    if (!state.canEdit) {
      _mode = _DragMode.none;
      return;
    }

    // 手指：这里只负责滚动/捏合，挪方块交给下面的「长按拿起再拖」
    if (details.kind == PointerDeviceKind.touch) {
      _mode = _DragMode.scroll;
      return;
    }

    // 鼠标：按住就能拖；只有「已经选中的方块」拉底边才算改时长
    _activeId = hit.block.id;
    _originStartMin = hit.block.startMin;
    _originDurationMin = hit.block.durationMin;
    _dragStartY = local.dy;
    _dragStartScroll = _scroll;
    _mode = _resizeModeFor(hit, content, state.selectedId);
  }

  /// 顶部把手 = 开始时间（结束不动）；底部把手 = 时长；其余 = 挪动
  _DragMode _resizeModeFor(PlacedBlock hit, Offset content, String? selectedId) {
    if (hit.block.id != selectedId) return _DragMode.move;
    if (TimelineLayout.isOnTopHandle(hit, content)) return _DragMode.resizeStart;
    if (TimelineLayout.isOnBottomHandle(hit, content)) return _DragMode.resize;
    return _DragMode.move;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_pickedUp) return;
    final layout = _layout;
    if (layout == null) return;
    final notifier = ref.read(timelineProvider.notifier);

    // 双指缩放
    if (details.pointerCount >= 2) {
      final focal = details.localFocalPoint;
      final nextPx = (_pinchStartPx * details.scale).clamp(
        _minPxPerMin,
        _maxPxPerMin,
      );
      setState(() {
        _pxPerMin = nextPx;
        _scroll = _clampScroll(
          _pinchAnchorMin * nextPx - (focal.dy - TimelineLayout.headerHeight),
        );
      });
      return;
    }

    final local = details.localFocalPoint;

    switch (_mode) {
      case _DragMode.scroll:
        setState(
          () => _scroll = _clampScroll(_scroll - details.focalPointDelta.dy),
        );
      case _DragMode.move:
      case _DragMode.resize:
      case _DragMode.resizeStart:
        // 拖到边缘自动滚动，不然长距离拖动要松手再滚
        if (local.dy < TimelineLayout.headerHeight + 56) {
          setState(() => _scroll = _clampScroll(_scroll - 6));
        } else if (local.dy > _viewport.height - 56) {
          setState(() => _scroll = _clampScroll(_scroll + 6));
        }

        // 用「相对起点」算位移：滚动位置怎么变都不会跳
        final deltaPx =
            local.dy - _dragStartY + (_scroll - _dragStartScroll);
        if (!_armed) {
          if (deltaPx.abs() < _dragSlop) return;
          _armed = true;
        }

        // 拖到左右边缘：把被「自动收起」藏起来的泳道临时放出来。
        if (_mode == _DragMode.move && _maybeRevealLaneAtEdge(local.dx)) {
          return;
        }

        final current = _blockById(_activeId);
        if (current == null) return;
        final deltaMin = deltaPx / _pxPerMin;

        if (_mode == _DragMode.move) {
          final start = snapMinute(_originStartMin + deltaMin).clamp(
            0,
            kMinutesPerDay - _originDurationMin,
          );
          final lane = _laneUnder(layout, local.dx, current.lane);
          if (start != current.startMin || lane != current.lane) {
            notifier.moveBlock(current.id, startMin: start, lane: lane);
            HapticFeedback.selectionClick();
          }
        } else {
          final duration = snapMinute(_originDurationMin + deltaMin).clamp(
            kMinDuration,
            kMinutesPerDay - _originStartMin,
          );
          if (duration != current.durationMin) {
            notifier.resizeBlock(current.id, durationMin: duration);
            HapticFeedback.selectionClick();
          }
        }
      case _DragMode.none:
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_pickedUp) return;
    // 捏合缩放结束后记一下倍数
    widget.onZoomChanged?.call(_pxPerMin);

    if (_mode == _DragMode.scroll) {
      // 拖动时用的是 `_scroll - delta.dy`，惯性速度要同号取反，
      // 否则「手指往上一划」会往回滚（v0 方向错了）。
      _startFling(-details.velocity.pixelsPerSecond.dy);
    }

    // 拖动时临时叫出来的泳道，松手收回去
    if (_tempRevealed.isNotEmpty) {
      setState(_tempRevealed.clear);
    }

    _mode = _DragMode.none;
    _activeId = null;
    _armed = false;
  }

  // ── 长按：拿起再拖 / 不动就出菜单（触摸）──────────────────────
  //
  // 不用 GestureDetector 的长按回调：长按胜出后同一个指针的 Scale 手势
  // 会被竞技场判负、`onScaleUpdate` 不再回调，方块就「拿起来纹丝不动」；
  // 而且个别 ROM 上长按识别也不稳。这里直接读原始指针事件、自己计时，
  // 行为完全可控：按住 380ms 拿起 → 移动＝拖，没移动就松手＝出菜单。

  static const int _pressDelayMs = 380;

  void _onPointerDown(PointerDownEvent event) {
    _pointersDown++;
    if (_pointersDown > 1) {
      _cancelPress();
      return;
    }
    if (event.kind != PointerDeviceKind.touch) return;

    _pressPointer = event.pointer;
    _pressLocal = event.localPosition;
    _pressMoved = false;
    _pressTimer?.cancel();
    _pressTimer = Timer(
      const Duration(milliseconds: _pressDelayMs),
      _beginPickUp,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pressPointer) return;
    if (!_pickedUp) {
      // 还没到长按时长手指就动了：这是在滑页面，别拦着
      if ((event.localPosition - _pressLocal).distance > 12) _cancelPress();
      return;
    }
    _dragPickedUpTo(event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _pressPointer) {
      final wasPicked = _pickedUp;
      final moved = _pressMoved;
      final dropForDay = _dropForDay;
      final id = _pressBlockId;
      _cancelPress();
      final block = id == null ? null : _blockById(id);
      if (wasPicked && moved && dropForDay && block != null) {
        widget.onDropToOtherDay?.call(block);
      } else if (wasPicked && !moved && block != null) {
        if (mounted) widget.onBlockMenu?.call(block, event.position);
      }
    }
    if (_pointersDown > 0) _pointersDown--;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pressPointer) _cancelPress();
    if (_pointersDown > 0) _pointersDown--;
  }

  void _cancelPress() {
    _pressTimer?.cancel();
    _pressTimer = null;
    _pickedUp = false;
    if (_dropForDay) setState(() => _dropForDay = false);
    _pressPointer = null;
    _pressBlockId = null;
    _pressMoved = false;
    _pickedUpMode = _DragMode.none;
  }

  /// 长按时间到：按在方块上就「拿起来」，按在空白就新建一个
  void _beginPickUp() {
    final layout = _layout;
    if (layout == null || !mounted) return;
    final local = _pressLocal;
    if (local.dy < TimelineLayout.headerHeight) return;

    final state = ref.read(timelineProvider);
    if (!state.canEdit) return;
    final notifier = ref.read(timelineProvider.notifier);
    final content = _toContent(local);

    // 先判「选中方块外侧的上下箭头」：箭头画在方块外面，命中优先于方块本体
    final selected = state.selectedId == null
        ? null
        : layout.placed
            .where((p) => p.block.id == state.selectedId)
            .firstOrNull;
    if (selected != null) {
      final onTop = TimelineLayout.isOnTopHandle(selected, content);
      final onBottom = TimelineLayout.isOnBottomHandle(selected, content);
      if (onTop || onBottom) {
        _startPickUp(
          selected,
          local,
          notifier,
          mode: onTop ? _DragMode.resizeStart : _DragMode.resize,
        );
        return;
      }
    }

    final hit = layout.hitTest(content, slop: 10);

    if (hit == null) {
      if (!widget.allowLongPressCreate) {
        _cancelPress();
        return;
      }
      _createBlockAt(layout, local);
      return;
    }

    _startPickUp(hit, local, notifier);
  }

  /// 拿起一个方块：记下起点，按「点在哪」决定是挪动、改时长还是改开始时间
  void _startPickUp(
    PlacedBlock placed,
    Offset local,
    TimelineNotifier notifier, {
    _DragMode? mode,
  }) {
    final hit = placed;
    notifier.select(hit.block.id);
    HapticFeedback.mediumImpact();
    setState(() {
      _pickedUp = true;
      _pressBlockId = hit.block.id;
      _pressMoved = false;
      _pickStartLocal = local;
      _pickStartScroll = _scroll;
      _pickOriginStart = hit.block.startMin;
      _pickOriginDuration = hit.block.durationMin;
      _pickedUpMode = mode ?? _DragMode.move;
    });
    _ignoreNextTap = true;
  }

  void _dragPickedUpTo(Offset local) {
    final id = _pressBlockId;
    final layout = _layout;
    if (id == null || layout == null) return;

    final delta = local - _pickStartLocal;
    if (!_pressMoved) {
      if (delta.distance < 3) return;
      setState(() => _pressMoved = true);
    }

    // 拖到顶栏上方 = 想换天，提示一下，松手后问日期
    final wantDay = local.dy < TimelineLayout.headerHeight;
    if (wantDay != _dropForDay) {
      setState(() => _dropForDay = wantDay);
      if (wantDay) HapticFeedback.selectionClick();
    }

    // 靠近上下边缘自动滚
    if (local.dy < TimelineLayout.headerHeight + 56) {
      setState(() => _scroll = _clampScroll(_scroll - 6));
    } else if (local.dy > _viewport.height - 56) {
      setState(() => _scroll = _clampScroll(_scroll + 6));
    }

    // 拖到左右边缘：临时放出被「自动收起」的泳道
    if (_pickedUpMode == _DragMode.move && _maybeRevealLaneAtEdge(local.dx)) {
      return;
    }

    final current = _blockById(id);
    if (current == null) return;
    final notifier = ref.read(timelineProvider.notifier);
    final deltaPx = delta.dy + (_scroll - _pickStartScroll);

    if (_pickedUpMode == _DragMode.resizeStart) {
      final originEnd = _pickOriginStart + _pickOriginDuration;
      final start = snapMinute(_pickOriginStart + deltaPx / _pxPerMin)
          .clamp(0, originEnd - kMinDuration);
      if (start != current.startMin) {
        notifier.resizeStart(current.id, startMin: start);
        HapticFeedback.selectionClick();
      }
      return;
    }
    if (_pickedUpMode == _DragMode.resize) {
      final duration = snapMinute(
        _pickOriginDuration + deltaPx / _pxPerMin,
      ).clamp(kMinDuration, kMinutesPerDay - _pickOriginStart);
      if (duration != current.durationMin) {
        notifier.resizeBlock(current.id, durationMin: duration);
        HapticFeedback.selectionClick();
      }
      return;
    }

    final start = snapMinute(_pickOriginStart + deltaPx / _pxPerMin).clamp(
      0,
      kMinutesPerDay - _pickOriginDuration,
    );
    final lane = _laneUnder(layout, local.dx, current.lane);
    if (start != current.startMin || lane != current.lane) {
      notifier.moveBlock(current.id, startMin: start, lane: lane);
      HapticFeedback.selectionClick();
    }
  }

  /// 横坐标落进另一条泳道，还得越过它 20% 的宽度才算换道，防手抖。
  Lane _laneUnder(TimelineLayout layout, double x, Lane current) {
    var probe = x;
    // 临时展开泳道时手指常常已经滑到 gutter / 屏幕边缘之外，
    // 这时按「最近的那条泳道」算，不然永远换不过去。
    if (_tempRevealed.isNotEmpty && layout.lanes.isNotEmpty) {
      final first = layout.laneRectAt(layout.lanes.first);
      final last = layout.laneRectAt(layout.lanes.last);
      if (x < first.left) {
        probe = first.left + first.width * 0.5;
      } else if (x > last.right) {
        probe = last.right - last.width * 0.5;
      }
    }
    final candidate = layout.laneAtX(probe) ?? current;
    if (candidate == current) return current;
    final rect = layout.laneRectAt(candidate);
    final margin = rect.width * 0.2;
    if (probe >= rect.left + margin && probe <= rect.right - margin) {
      return candidate;
    }
    return current;
  }

  /// 拖到屏幕最左/最右时，把被自动收起的一条泳道临时展开。
  /// 返回 true 表示这一帧泳道布局刚变过（调用方应跳过本帧的位置计算）。
  bool _maybeRevealLaneAtEdge(double x) {
    final state = ref.read(timelineProvider);
    if (!state.autoHideEmptyLanes) return false;
    final lane = edgeRevealTarget(
      x: x,
      viewportWidth: _viewport.width,
      hiddenLanes: state.effectiveHiddenLanes,
      alreadyRevealed: _tempRevealed,
      edgeZone: _edgeZone,
    );
    if (lane == null) return false;
    setState(() => _tempRevealed.add(lane));
    HapticFeedback.selectionClick();
    return true;
  }

  /// 在空白处按下的位置建一个 30 分钟的方块，并直接打开编辑面板
  void _createBlockAt(TimelineLayout layout, Offset local) {
    final lane = layout.laneAtX(local.dx);
    if (lane == null) return;
    final content = _toContent(local);
    final start = snapMinute(
      content.dy / _pxPerMin,
    ).clamp(0, kMinutesPerDay - 30);
    final block = ref
        .read(timelineProvider.notifier)
        .addBlockAt(lane: lane, startMin: start);
    if (block == null) return;
    HapticFeedback.lightImpact();
    _ignoreNextTap = true;
    _cancelPress();
    final onNew = widget.onEditNewBlock;
    if (onNew != null) {
      onNew(block.id);
    } else {
      widget.onEditBlock?.call(block.id);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_pickedUp || _ignoreNextTap) {
      _ignoreNextTap = false;
      return;
    }
    final layout = _layout;
    if (layout == null) return;
    final local = details.localPosition;
    if (local.dy < TimelineLayout.headerHeight) return;

    final hit = layout.hitTest(_toContent(local));
    final notifier = ref.read(timelineProvider.notifier);
    // 点一下 = 选中；同一方块 350ms 内再点一下 = 快速修改
    if (hit == null) {
      _lastTapId = null;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isDoubleBlank =
          _lastBlankTapMs > 0 &&
          nowMs - _lastBlankTapMs <= 320 &&
          (_lastBlankTapPos - local).distance < 44;
      _lastBlankTapMs = isDoubleBlank ? 0 : nowMs;
      _lastBlankTapPos = local;
      if (isDoubleBlank && widget.allowDoubleTapCreate) {
        _createBlockAt(layout, local);
        return;
      }
      notifier.select(null);
      return;
    }
    notifier.select(hit.block.id);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isDouble =
        _lastTapId == hit.block.id && nowMs - _lastTapMs <= 350;
    _lastTapId = hit.block.id;
    _lastTapMs = nowMs;
    if (isDouble) {
      _lastTapId = null;
      if (ref.read(timelineProvider).canEdit) {
        widget.onQuickEdit?.call(hit.block.id);
      }
    }
  }

  /// 桌面右键：和手机长按走同一个菜单。
  void _onSecondaryTapUp(TapUpDetails details) {
    final layout = _layout;
    if (layout == null) return;
    final local = details.localPosition;
    if (local.dy < TimelineLayout.headerHeight) return;
    final hit = layout.hitTest(_toContent(local));
    if (hit == null) return;
    ref.read(timelineProvider.notifier).select(hit.block.id);
    widget.onBlockMenu?.call(hit.block, details.globalPosition);
  }

  TBlock? _blockById(String? id) {
    if (id == null) return null;
    final blocks = ref.read(timelineProvider).blocks;
    for (final b in blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// 把「视口中心那一刻」当作锚点缩放，滑块和捏合都是这个手感
  void _applyZoom(double nextPx) {
    final center = _contentViewportHeight / 2;
    final anchorMin = (_scroll + center) / _pxPerMin;
    final clamped = nextPx.clamp(_minPxPerMin, _maxPxPerMin);
    if ((clamped - _pxPerMin).abs() < 0.001) return;
    setState(() {
      _pxPerMin = clamped;
      _scroll = _clampScroll(anchorMin * _pxPerMin - center);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _layout = TimelineLayout.compute(
          viewport: _viewport,
          pxPerMin: _pxPerMin,
          blocks: state.blocks,
          showTopInLane: state.showTopInLane,
          now: state.now,
          hiddenLanes: state.effectiveHiddenLanes.difference(_tempRevealed),
          laneOrder: state.lanes,
          laneGapScale: ref.watch(uiPrefsProvider).laneGapScale,
        );

        if (!_didInitScroll && _contentViewportHeight > 0) {
          _didInitScroll = true;
          // 初次打开滚到「当前时刻前 2 小时」，一进来就能看到现在该干什么
          final nowMin = state.now.hour * 60 + state.now.minute;
          _scroll = _clampScroll((nowMin - 120) * _pxPerMin);
        }
        _scroll = _clampScroll(_scroll);

        // 周视图点了某个色块：把那个时刻滚到视口中间，然后清掉请求
        final jumpMinute = state.jumpMinute;
        if (jumpMinute != null) {
          final visible =
              (_viewport.height - TimelineLayout.headerHeight).clamp(1.0, 1e6);
          _scroll = _clampScroll(jumpMinute * _pxPerMin - visible / 2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(timelineProvider.notifier).clearJump();
          });
        }

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                onPointerSignal: _onPointerSignal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  onTapUp: _onTapUp,
                  onSecondaryTapUp: _onSecondaryTapUp,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: TimelinePainter(
                        layout: _layout!,
                        scroll: _scroll,
                        selectedId: state.selectedId,
                        showTopInLane: state.showTopInLane,
                        draggingId: _pickedUp
                            ? _pressBlockId
                            : (_mode == _DragMode.move ||
                                      _mode == _DragMode.resize
                                  ? _activeId
                                  : null),
                        handleScale: ref.watch(uiPrefsProvider).handleScale,
                        nowMarkerStyle: ref.watch(uiPrefsProvider).nowMarkerStyle,
                        nowMarkerIcon: ref.watch(uiPrefsProvider).nowMarkerIcon,
                        nowMarkerDoodle:
                            ref.watch(uiPrefsProvider).nowMarkerDoodle,
                        nowColorIndex:
                            ref.watch(uiPrefsProvider).nowMarkerColorIndex,
                        nowLineColorIndex:
                            ref.watch(uiPrefsProvider).nowLineColorIndex,
                        nowMarkerSize: ref.watch(uiPrefsProvider).nowMarkerSize,
                        nowMarkerRight: ref.watch(uiPrefsProvider).nowMarkerRight,
                        nowLineWidth: ref.watch(uiPrefsProvider).nowLineWidth,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            if (_dropForDay)
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C8DFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '松手换到别的日期',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B1220),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (ref.watch(uiPrefsProvider).showZoomSlider)
              Positioned(
                right: 6,
                top: TimelineLayout.headerHeight + 44,
                bottom: 190,
                child: _ZoomDock(
                  expanded: ref.watch(uiPrefsProvider).zoomSliderExpanded,
                  onToggle: () => ref
                      .read(uiPrefsProvider.notifier)
                      .setZoomSliderExpanded(
                        !ref.read(uiPrefsProvider).zoomSliderExpanded,
                      ),
                  value: _pxPerMin,
                  min: _minPxPerMin,
                  max: _maxPxPerMin,
                  onChanged: _applyZoom,
                  onChangeEnd: (value) => widget.onZoomChanged?.call(value),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 右侧竖着的缩放滑块：往上拉放大、往下拉缩小（懒得点 +/− 了）。
/// 贴着右边缘放，避开右下角的「完成」圆钮和底部信息条；
/// 收起后只剩一个小箭头，点一下再展开。
class _ZoomDock extends StatelessWidget {
  const _ZoomDock({
    required this.expanded,
    required this.onToggle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 28,
            height: 40,
            decoration: BoxDecoration(
              color: Palette.surface.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              border: Border.all(color: Palette.line),
            ),
            child: Icon(
              Icons.chevron_left,
              size: 16,
              color: Palette.textSecondary,
            ),
          ),
        ),
      );
    }
    return _ZoomSlider(
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      onCollapse: onToggle,
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onCollapse,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Palette.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onCollapse,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 18,
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Palette.textSecondary,
              ),
            ),
          ),
          Icon(Icons.add, size: 13, color: Palette.textSecondary),
          const SizedBox(height: 2),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Palette.accent,
                  inactiveTrackColor: Palette.line,
                  thumbColor: Palette.textPrimary,
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${value.toStringAsFixed(2)}x',
            style: TextStyle(
              color: Palette.textSecondary,
              fontSize: 9,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
