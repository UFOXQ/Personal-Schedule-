import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 时间轴的缩放倍数（px/分钟），记住上次调的大小。
///
/// 只记缩放，不记滚动位置：下次打开本来就会滚到「现在附近」，
/// 记死上次的位置反而容易一打开看不到当前时间。
class ZoomNotifier extends Notifier<double> {
  static const String _key = 'ui.zoom';
  static const double min = 0.6;
  static const double max = 4.0;
  static const double fallback = 1.5;

  @override
  double build() {
    unawaited(_restore());
    return fallback;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(_key);
      if (stored != null && stored != state) {
        state = stored.clamp(min, max);
      }
    } catch (error) {
      // 读不到就用默认值
      assert(() {
        // ignore: avoid_print
        print('TNT: 读取缩放失败 -> $error');
        return true;
      }());
    }
  }

  Future<void> set(double value) async {
    final next = value.clamp(min, max);
    if ((next - state).abs() < 0.001) return;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, next);
    } catch (_) {
      // 存不上也先让这次生效
    }
  }
}

final zoomProvider = NotifierProvider<ZoomNotifier, double>(ZoomNotifier.new);
