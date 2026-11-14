import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/time_utils.dart';
import '../../domain/models/tblock.dart';

/// Android 桌面小组件的数据桥。
///
/// 桌面端 / 测试环境什么都不做（home_widget 没有对应实现，调用会抛）。
/// 真正画界面的是 `android/app/src/main/kotlin/com/tnt/tnt_app/TntWidgetProvider.kt`，
/// 它读 [HomeWidgetPlugin.getData] 里的这两个键。
class HomeWidgetBridge {
  static const String _titleKey = 'tnt_widget_title';
  static const String _bodyKey = 'tnt_widget_body';
  static const String _androidName = 'TntWidgetProvider';
  static const String _qualifiedName = 'com.tnt.tnt_app.TntWidgetProvider';
  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  bool get _enabled => !kIsWeb && Platform.isAndroid;

  /// 把「今天还剩哪些方块」写进小组件，并请求重绘。
  Future<void> sync({required DateTime day, required List<TBlock> blocks}) async {
    if (!_enabled) return;
    try {
      final active = blocks.where((b) => !b.done && b.status.isActive).toList()
        ..sort((a, b) => a.startMin.compareTo(b.startMin));

      final dateLabel = '${day.month} 月 ${day.day} 日 · 周${_weekdays[day.weekday - 1]}';
      final title = active.isEmpty ? dateLabel : '$dateLabel · ${active.length} 件';

      // 小组件高度有限，最多铺 5 行
      final body = active.isEmpty
          ? '今天还没排东西'
          : active
              .take(5)
              .map((b) => '${formatMinute(b.startMin)}  ${b.title}')
              .join('\n');

      await HomeWidget.saveWidgetData<String>(_titleKey, title);
      await HomeWidget.saveWidgetData<String>(_bodyKey, body);
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
        qualifiedAndroidName: _qualifiedName,
      );
    } catch (error) {
      // 小组件失败不影响主界面
      debugPrint('TNT: 小组件刷新失败 -> $error');
    }
  }
}

final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>(
  (ref) => HomeWidgetBridge(),
);
