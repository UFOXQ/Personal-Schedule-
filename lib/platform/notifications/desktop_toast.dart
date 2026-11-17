import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 桌面端系统通知（Windows toast）。
///
/// local_notifier / WinToast 在「非 MSIX 打包」下拿不到 AUMMID，实测建不出
/// 开始菜单快捷方式，所以一直报 `WinToast is not initialized`。
/// 这里改走 runner 里的原生实现：先建一个带 AppUserModelID 的开始菜单快捷方式，
/// 再用 `ToastNotificationManager::CreateToastNotifier(aumid)` 发通知。
class DesktopToast {
  const DesktopToast();

  static const MethodChannel _channel = MethodChannel('tnt/toast');

  /// 返回 true 表示系统 toast 真的发出去了。
  Future<bool> show({required String title, String body = ''}) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('show', {
        'title': title,
        'body': body,
      });
      return result ?? false;
    } on PlatformException catch (error) {
      debugPrint('TNT: 系统通知失败 -> ${error.code} ${error.message}');
      return false;
    } on MissingPluginException {
      // 跑在 Android / 单元测试里，通道不存在，交给调用方降级
      return false;
    }
  }
}

const DesktopToast desktopToast = DesktopToast();
