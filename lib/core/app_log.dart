import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 极简落盘日志：桌面端出问题（托盘没出来、toast 没弹）时，
/// 用户没法看 stdout，就写一份到 `%APPDATA%\com.tnt\tnt_app\tnt.log`。
///
/// 只在真正需要排查的地方调用，正常路径不写，避免日志膨胀。
Future<void> appLog(String message) async {
  debugPrint('TNT: $message');
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'tnt.log'));
    // 超过 256 KB 就从头截断，够用且不会无限长。
    if (await file.exists() && await file.length() > 256 * 1024) {
      await file.writeAsString('');
    }
    final stamp = DateTime.now().toIso8601String();
    await file.writeAsString('[$stamp] $message\n', mode: FileMode.append);
  } catch (error) {
    debugPrint('TNT: 写日志失败 -> $error');
  }
}
