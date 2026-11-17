import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../db/tnt_database.dart';
import 'sync_snapshot.dart';

/// 在局域网里当「主机」：一台设备开 HTTP 服务，另一台连上来，
/// 双方各发一份全量快照，各自 LWW 合并，最后两边数据一致。
///
/// 只监听局域网 IPv4，请求必须带配对码 —— 同网段的设备很多，
/// 光靠端口就能改数据不合适。
class SyncServer {
  SyncServer._(this._server, this.code, this.deviceName);

  final HttpServer _server;
  final String code;
  final String deviceName;

  int get port => _server.port;

  bool get isRunning => true;

  /// 本机在局域网里的地址（给对面输入用）。取不到就回 127.0.0.1。
  static Future<String> localAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (error) {
      debugPrint('TNT: 取本机地址失败 -> $error');
    }
    return '127.0.0.1';
  }

  /// 起服务。端口被占用时往后试几个，返回真正监听上的那个。
  static Future<SyncServer> start({
    required TntDatabase db,
    required String deviceName,
    String? code,
    int port = 47821,
  }) async {
    final actualCode = code ?? _randomCode();
    HttpServer? server;
    for (var offset = 0; offset < 8; offset++) {
      try {
        server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          port + offset,
          shared: false,
        );
        break;
      } on SocketException {
        continue;
      }
    }
    if (server == null) {
      throw const SocketException('47821-47828 都被占用了，换个端口再试');
    }

    final instance = SyncServer._(server, actualCode, deviceName);
    instance._serve(db);
    return instance;
  }

  void _serve(TntDatabase db) {
    unawaited(() async {
      await for (final request in _server) {
        unawaited(_handle(request, db));
      }
    }());
  }

  Future<void> _handle(HttpRequest request, TntDatabase db) async {
    final response = request.response;
    try {
      if (request.method == 'GET' && request.uri.path == '/ping') {
        _json(response, HttpStatus.ok, {
          'app': 'tnt',
          'protocol': kSyncProtocol,
          'deviceName': deviceName,
          'needsCode': code.isNotEmpty,
        });
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/sync') {
        if (code.isNotEmpty &&
            request.headers.value('x-tnt-code') != code) {
          _json(response, HttpStatus.forbidden, {'error': '配对码不对'});
          return;
        }
        final protocol =
            int.tryParse(request.headers.value('x-tnt-protocol') ?? '');
        if (protocol != null && protocol != kSyncProtocol) {
          _json(response, HttpStatus.badRequest, {
            'error': '协议版本不一致（本机 $kSyncProtocol，对方 $protocol）',
          });
          return;
        }

        final body = await utf8.decoder.bind(request).join();
        final incoming = decodeSnapshot(body);
        final stats = await applySnapshot(db, incoming);
        final merged = await readSnapshot(db);
        _json(response, HttpStatus.ok, {
          'protocol': kSyncProtocol,
          'deviceName': deviceName,
          'applied': stats.applied,
          'skipped': stats.skipped,
          'snapshot': merged.toJson(),
        });
        return;
      }

      _json(response, HttpStatus.notFound, {'error': '没有这个接口'});
    } catch (error) {
      debugPrint('TNT: 同步请求处理失败 -> $error');
      try {
        _json(response, HttpStatus.badRequest, {'error': '$error'});
      } catch (_) {
        // 响应可能已经被写坏了，忽略。
      }
    }
  }

  void _json(HttpResponse response, int status, Map<String, Object?> body) {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    unawaited(response.close());
  }

  Future<void> stop() async {
    await _server.close(force: true);
  }

  static String _randomCode() {
    final random = Random.secure();
    return List.generate(4, (_) => random.nextInt(10)).join();
  }
}
