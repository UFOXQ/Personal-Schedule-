import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/time_utils.dart';
import '../../domain/layout/timeline_layout.dart';
import '../../domain/models/tblock.dart';
import 'timeline_painter.dart';
import 'timeline_state.dart';

/// 手势当前在干什么
enum _DragMode { none, scroll, move, resize }

/// 时间轴本体：一块 CustomPaint + 一套手势。
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({super.key});

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView>
    with SingleTickerProviderStateMixin {
  static const double _minPxPerMin = 0.6;
  static const double _maxPxPerMin = 4.0;

  double _pxPerMin = 1.5;
  double _scroll = 0;
  bool _didInitScroll = false;

  Size _viewport = Size.zero;
  TimelineLayout? _layout;

  _DragMode _mode = _DragMode.none;
  String? _activeId;
  double _grabMin = 0; // 按下点距方块顶部的分钟数
  double _pinchAnchorMin = 0;
  double _pinchStartPx = 1.5;

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
  void _onScaleStart(ScaleStartDetails details) {
    _stopFling();
    final layout = _layout;
    if (layout == null) return;

    if (details.pointerCount >= 2) {
      _mode = _DragMode.none;
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

    _activeId = hit.block.id;
    ref.read(timelineProvider.notifier).select(hit.block.id);

    if (TimelineLayout.isOnBottomEdge(hit, content)) {
      _mode = _DragMode.resize;
    } else {
      _mode = _DragMode.move;
      _grabMin = content.dy / _pxPerMin - hit.block.startMin;
    }
  }

  /// 桌面端：鼠标滚轮滚动时间轴。
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _stopFling();
    setState(() => _scroll = _clampScroll(_scroll + event.scrollDelta.dy));
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
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
        // 拖到边缘自动滚动，不然长距离拖动要松手再滚
        if (local.dy < TimelineLayout.headerHeight + 56) {
          setState(() => _scroll = _clampScroll(_scroll - 6));
        } else if (local.dy > _viewport.height - 56) {
          setState(() => _scroll = _clampScroll(_scroll + 6));
        }

        final content = _toContent(local);
        final current = _blockById(_activeId);
        if (current == null) return;

        if (_mode == _DragMode.move) {
          final rawStart = content.dy / _pxPerMin - _grabMin;
          final start = snapMinute(rawStart)
              .clamp(0, kMinutesPerDay - current.durationMin);
          final lane = layout.laneAtX(local.dx) ?? current.lane;
          if (start != current.startMin || lane != current.lane) {
            notifier.moveBlock(current.id, startMin: start, lane: lane);
            HapticFeedback.selectionClick();
          }
        } else {
          final endMin = snapMinute(content.dy / _pxPerMin);
          final duration = (endMin - current.startMin).clamp(
            kMinDuration,
            kMinutesPerDay - current.startMin,
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
    if (_mode == _DragMode.scroll) {
      _startFling(details.velocity.pixelsPerSecond.dy);
    }
    _mode = _DragMode.none;
    _activeId = null;
  }

  void _onTapUp(TapUpDetails details) {
    final layout = _layout;
    if (layout == null) return;
    final local = details.localPosition;
    if (local.dy < TimelineLayout.headerHeight) return;

    final content = _toContent(local);
    final hit = layout.hitTest(content);
    final notifier = ref.read(timelineProvider.notifier);

    if (hit != null) {
      notifier.select(hit.block.id);
      return;
    }

    final lane = layout.laneAtX(local.dx);
    if (lane == null) return;
    final start = snapMinute(content.dy / _pxPerMin)
        .clamp(0, kMinutesPerDay - 30);
    final block = notifier.addBlockAt(lane: lane, startMin: start);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '已添加「${block.title}」${formatRange(block.startMin, block.durationMin)}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onLongPress(LongPressStartDetails details) {
    final layout = _layout;
    if (layout == null) return;
    final local = details.localPosition;
    if (local.dy < TimelineLayout.headerHeight) return;
    final hit = layout.hitTest(_toContent(local));
    if (hit == null) return;

    final title = hit.block.title;
    ref.read(timelineProvider.notifier).deleteBlock(hit.block.id);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已删除「$title」'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  TBlock? _blockById(String? id) {
    if (id == null) return null;
    final blocks = ref.read(timelineProvider).blocks;
    for (final b in blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  void _zoomBy(double factor) {
    final center = _contentViewportHeight / 2;
    final anchorMin = (_scroll + center) / _pxPerMin;
    setState(() {
      _pxPerMin = (_pxPerMin * factor).clamp(_minPxPerMin, _maxPxPerMin);
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
        );

        if (!_didInitScroll && _contentViewportHeight > 0) {
          _didInitScroll = true;
          // 初次打开滚到「当前时刻前 2 小时」，一进来就能看到现在该干什么
          final nowMin = state.now.hour * 60 + state.now.minute;
          _scroll = _clampScroll((nowMin - 120) * _pxPerMin);
        }
        _scroll = _clampScroll(_scroll);

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerSignal: _onPointerSignal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  onTapUp: _onTapUp,
                  onLongPressStart: _onLongPress,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: TimelinePainter(
                        layout: _layout!,
                        scroll: _scroll,
                        selectedId: state.selectedId,
                        showTopInLane: state.showTopInLane,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 12,
              child: _ZoomBar(
                onIn: () => _zoomBy(1.25),
                onOut: () => _zoomBy(0.8),
                scaleLabel: '${_pxPerMin.toStringAsFixed(2)}x',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.onIn,
    required this.onOut,
    required this.scaleLabel,
  });

  final VoidCallback onIn;
  final VoidCallback onOut;
  final String scaleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF151821).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF242938)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onOut,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: '缩小',
            icon: const Icon(Icons.remove, color: Color(0xFF8C95A8)),
          ),
          Text(
            scaleLabel,
            style: const TextStyle(
              color: Color(0xFF8C95A8),
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            onPressed: onIn,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: '放大',
            icon: const Icon(Icons.add, color: Color(0xFF8C95A8)),
          ),
        ],
      ),
    );
  }
}
