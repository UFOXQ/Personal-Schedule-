import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// 手机通知上的快捷动作（目前只有 `quickadd`）。
///
/// 原生侧把动作存在 MainActivity 的 `pendingAction` 里，Dart 每次回到前台
/// 或首次启动时取一次；取走即清空，避免重复弹面板。
const MethodChannel _channel = MethodChannel('tnt/strip');

Future<String?> takePendingAction() async {
  if (!Platform.isAndroid) return null;
  try {
    return await _channel.invokeMethod<String>('takeAction');
  } catch (_) {
    return null;
  }
}
