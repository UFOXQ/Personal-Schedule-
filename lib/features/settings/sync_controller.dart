import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/tnt_database.dart';
import '../../data/providers.dart';
import '../../data/sync/sync_client.dart';
import '../../data/sync/sync_server.dart';
import '../timeline/timeline_state.dart';

/// 同步面板的状态。主机地址和配对码只在本机这次运行里有效 ——
/// 每次开主机重新生成，不会被记住。
class SyncState {
  const SyncState({
    this.hosting = false,
    this.address,
    this.code,
    this.busy = false,
    this.message,
    this.lastError,
  });

  final bool hosting;
  final String? address;
  final String? code;
  final bool busy;
  final String? message;
  final String? lastError;

  SyncState copyWith({
    bool? hosting,
    String? address,
    String? code,
    bool? busy,
    String? message,
    String? lastError,
  }) {
    return SyncState(
      hosting: hosting ?? this.hosting,
      address: address ?? this.address,
      code: code ?? this.code,
      busy: busy ?? this.busy,
      message: message ?? this.message,
      lastError: lastError ?? this.lastError,
    );
  }

  SyncState clearedMessage() => SyncState(
    hosting: hosting,
    address: address,
    code: code,
    busy: busy,
  );
}

/// 设备名：桌面用主机名，手机就叫「手机」。
String defaultDeviceName() {
  if (kIsWeb) return 'TNT';
  if (Platform.isAndroid) return '手机';
  try {
    return Platform.localHostname;
  } catch (_) {
    return '电脑';
  }
}

class SyncController extends Notifier<SyncState> {
  SyncServer? _server;

  @override
  SyncState build() {
    ref.onDispose(() {
      _server?.stop();
      _server = null;
    });
    return const SyncState();
  }

  TntDatabase get _db => ref.read(databaseProvider);

  Future<void> startHost() async {
    if (_server != null || state.busy) return;
    state = state.copyWith(busy: true, lastError: null);
    try {
      final server = await SyncServer.start(
        db: _db,
        deviceName: defaultDeviceName(),
      );
      _server = server;
      final ip = await SyncServer.localAddress();
      state = SyncState(
        hosting: true,
        address: '${server.port == 47821 ? ip : ip}:${server.port}',
        code: server.code,
        message: '已开启，等对面连过来',
      );
    } catch (error) {
      state = state.copyWith(busy: false, lastError: '开主机失败：$error');
    }
  }

  Future<void> stopHost() async {
    final server = _server;
    _server = null;
    await server?.stop();
    state = const SyncState(message: '已停止');
  }

  /// 连对面：地址可以只填 IP，端口默认 47821。
  Future<void> syncWith({
    required String address,
    required String code,
  }) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, lastError: null);
    try {
      final base = SyncClient.parseBase(address);
      final outcome = await SyncClient.sync(
        db: _db,
        base: base,
        code: code.trim(),
        deviceName: defaultDeviceName(),
      );
      state = state.copyWith(busy: false, message: outcome.describe());
      // 拉回来的数据要重新物化/重排列，否则界面还是旧的一份。
      await ref.read(timelineProvider.notifier).reload();
    } catch (error) {
      state = state.copyWith(busy: false, lastError: '同步失败：$error');
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);
