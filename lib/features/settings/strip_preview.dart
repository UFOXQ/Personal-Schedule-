import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../domain/strip_image.dart';
import '../../domain/timeline_strip.dart';
import '../timeline/timeline_state.dart';
import 'ui_prefs.dart';

/// 「时间条样式」里的实时预览：改滑条 / 改开关后 250ms 重画一张。
class StripPreview extends ConsumerStatefulWidget {
  const StripPreview({super.key});

  @override
  ConsumerState<StripPreview> createState() => _StripPreviewState();
}

class _StripPreviewState extends ConsumerState<StripPreview> {
  Uint8List? _png;
  String _renderedKey = '';
  Timer? _debounce;
  int _token = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _key(UiPrefs prefs, TimelineState timeline, bool light) => [
    light,
    prefs.stripTextScale.toStringAsFixed(3),
    prefs.stripLineRatio.toStringAsFixed(3),
    prefs.stripShowLeft,
    prefs.stripShowRight,
    timeline.dateKey,
    timeline.blocks.length,
    timeline.blocks.fold<int>(0, (sum, b) => sum + b.startMin + b.durationMin),
  ].join('|');

  Future<void> _render(UiPrefs prefs, TimelineState timeline, bool light) async {
    final current = ++_token;
    final payload = buildStripPayload(
      blocks: timeline.blocks,
      now: DateTime.now(),
      hiddenLanes: timeline.effectiveHiddenLanes,
    );
    final png = await renderStripPng(
      payload,
      style: StripStyle(
        textScale: prefs.stripTextScale,
        showLeft: prefs.stripShowLeft,
        showRight: prefs.stripShowRight,
        lineRatio: prefs.stripLineRatio,
        light: light,
      ),
    );
    if (!mounted || current != _token) return;
    setState(() => _png = png);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(uiPrefsProvider);
    final timeline = ref.watch(timelineProvider);
    final light = Theme.of(context).brightness == Brightness.light;
    final key = _key(prefs, timeline, light);

    if (key != _renderedKey) {
      _renderedKey = key;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        unawaited(_render(prefs, timeline, light));
      });
    }

    final image = _png;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: light ? Palette.surfaceHigh : Palette.laneBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image == null
            ? const SizedBox(
                height: 96,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Image.memory(
                image,
                height: 96,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}
