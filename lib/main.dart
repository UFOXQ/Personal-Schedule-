import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/db/tnt_database.dart';
import 'data/providers.dart';
import 'data/sync/sync_client.dart';
import 'data/sync/sync_server.dart';
import 'features/settings/sync_controller.dart';
import 'platform/notifications/reminder_scheduler.dart';
import 'platform/window/tray_host.dart';
import 'platform/window/window_setup.dart';

// 联调开关：编译期默认关，桌面端也可以直接用真实环境变量打开。
//   TNT_SYNC_HOST=1                    → 启动后开同步主机，打印地址与配对码
//   TNT_SYNC_PEER=10.0.2.2:47821       → 启动后自动连对面同步一次
//   TNT_SYNC_CODE=1234                 → 固定配对码（两边要一致）
const bool _defineHost = bool.fromEnvironment('TNT_SYNC_HOST');
const String _definePeer = String.fromEnvironment('TNT_SYNC_PEER');
const String _defineCode = String.fromEnvironment('TNT_SYNC_CODE');
const bool _defineToastTest = bool.fromEnvironment('TNT_TOAST_TEST');

String _envOr(String key, String fallback) {
  if (!kIsWeb && !Platform.isAndroid) {
    final value = Platform.environment[key];
    if (value != null && value.isNotEmpty) return value;
  }
  return fallback;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDesktopWindow();

  // 通知插件与时区要在第一帧之前就绪，否则启动那几分钟的提醒排不上
  final scheduler = LocalReminderScheduler();
  await scheduler.init();

  // 桌面端常驻托盘：点 ✕ 只是藏窗口，托盘图标还在。
  // 放在首帧之后装 —— 托盘图标要走 AssetBundle 读 png，首帧前装过一次
  // setIcon 不报错但图标不出现。
  final tray = TrayHost();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(tray.install());
  });

  // 需要一个能读 provider 的容器，联调钩子要用同一个库实例
  final container = ProviderContainer(
    overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TntApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_maybeRunAutoSync(container));
  });

  // 联调：启动 4 秒后发一条系统通知，用来验证 Windows toast 通不通。
  //   TNT_TOAST_TEST=1
  if (_envOr('TNT_TOAST_TEST', _defineToastTest ? '1' : '') == '1') {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), () async {
        await container.read(reminderSchedulerProvider).showTest();
      }),
    );
  }
}

/// 只在开发联调时走：按环境变量开主机 / 连对面，并把结果打到 stdout，
/// 方便脚本两端跑一遍同步验证。正常启动两个变量都不设，这里直接返回。
Future<void> _maybeRunAutoSync(ProviderContainer container) async {
  final host = _envOr('TNT_SYNC_HOST', _defineHost ? '1' : '') == '1';
  final peer = _envOr('TNT_SYNC_PEER', _definePeer);
  final code = _envOr('TNT_SYNC_CODE', _defineCode);
  if (!host && peer.isEmpty) return;

  final db = container.read(databaseProvider);
  final deviceName = defaultDeviceName();

  if (host) {
    try {
      final server = await SyncServer.start(
        db: db,
        deviceName: deviceName,
        code: code.isEmpty ? null : code,
      );
      final ip = await SyncServer.localAddress();
      // 故意打到 stderr：手机上 stdout 常被吞掉，stderr 更容易抓
      debugPrint(
        'TNT SYNC HOST ok http://$ip:${server.port} code=${server.code}',
      );
      await _printRowCounts(db, 'host');
    } catch (error) {
      debugPrint('TNT SYNC HOST failed $error');
    }
  }

  if (peer.isNotEmpty) {
    try {
      final base = SyncClient.parseBase(peer);
      final outcome = await SyncClient.sync(
        db: db,
        base: base,
        code: code,
        deviceName: deviceName,
      );
      debugPrint(
        'TNT SYNC PEER ok peer=${outcome.peerName} '
        'applied=${outcome.applied} skipped=${outcome.skipped}',
      );
      await _printRowCounts(db, 'peer');
    } catch (error) {
      debugPrint('TNT SYNC PEER failed $error');
    }
  }
}

Future<void> _printRowCounts(TntDatabase db, String tag) async {
  final rows = await db.customSelect(
    'SELECT (SELECT count(*) FROM day_blocks) a, '
    '(SELECT count(*) FROM plans) b, '
    '(SELECT count(*) FROM collections) c, '
    '(SELECT count(*) FROM collection_items) d, '
    '(SELECT count(*) FROM completion_logs) e',
  ).getSingle();
  debugPrint(
    'TNT SYNC COUNTS $tag day_blocks=${rows.data['a']} plans=${rows.data['b']} '
    'collections=${rows.data['c']} items=${rows.data['d']} '
    'logs=${rows.data['e']}',
  );
}
