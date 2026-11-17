import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 界面大小：手机屏幕小，字和控件整体按比例放大一点更舒服。
///
/// 只影响文字与控件尺寸（通过 MediaQuery.textScaler），
/// 不改时间轴的 px/分钟，免得调大之后方块位置跟着变。
class UiScale {
  const UiScale._();

  /// 可选的档位：小 / 标准 / 大 / 特大
  static const List<double> options = [0.9, 1.0, 1.15, 1.3];

  static String labelOf(double scale) {
    if (scale < 0.95) return '小';
    if (scale < 1.06) return '标准';
    if (scale < 1.22) return '大';
    return '特大';
  }
}

class UiScaleNotifier extends Notifier<double> {
  static const String _key = 'ui.scale';

  @override
  double build() {
    unawaited(_restore());
    return 1.0;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(_key);
      if (stored != null && UiScale.options.contains(stored) && stored != state) {
        state = stored;
      }
    } catch (error) {
      // 读不到就用默认值，不影响主流程
      assert(() {
        // ignore: avoid_print
        print('TNT: 读取界面大小失败 -> $error');
        return true;
      }());
    }
  }

  Future<void> setScale(double scale) async {
    if (scale == state) return;
    state = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, scale);
    } catch (_) {
      // 存不上也先让当前会话生效
    }
  }
}

final uiScaleProvider = NotifierProvider<UiScaleNotifier, double>(
  UiScaleNotifier.new,
);
