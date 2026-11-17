import 'dart:convert';
import 'dart:io';

import '../db/tnt_database.dart';
import 'sync_snapshot.dart';

/// 对端基本信息：先 ping 一下再同步，报错能说得清楚些。
class SyncPeer {
  const SyncPeer({
    required this.deviceName,
    required this.protocol,
    required this.needsCode,
  });

  final String deviceName;
  final int protocol;
  final bool needsCode;
}

/// 这次同步的结果。
class SyncOutcome {
  const SyncOutcome({
    required this.peerName,
    required this.applied,
    required this.skipped,
  });

  final String peerName;

  /// 本机把对端合并进来的行数。
  final int applied;
  final int skipped;

  String describe() {
    if (applied == 0) return '已是最新（对端 $peerName）';
    return '合并 $applied 行（对端 $peerName）';
  }
}

/// 客户端：连到对面的 SyncServer，把自己的快照推上去，
/// 再把对面合并后的完整快照拉回来并进本地。
class SyncClient {
  static const Duration _timeout = Duration(seconds: 12);

  /// [base] 形如 `http://192.168.1.5:47821`，允许用户只填 `192.168.1.5`。
  static Uri parseBase(String input) {
    var text = input.trim();
    if (text.isEmpty) {
      throw const FormatException('先填对面地址');
    }
    if (!text.contains('://')) {
      text = 'http://$text';
    }
    final uri = Uri.parse(text);
    if (uri.host.isEmpty) {
      throw const FormatException('地址看起来不对');
    }
    return uri.replace(
      port: uri.hasPort ? uri.port : 47821,
      path: '',
    );
  }

  static Future<SyncPeer> probe(Uri base) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(base.replace(path: '/ping'));
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('对面返回 ${response.statusCode}：$body');
      }
      final json = jsonDecode(body);
      if (json is! Map) throw const FormatException('对面不是 TNT');
      final protocol = (json['protocol'] as num?)?.toInt() ?? 0;
      if (protocol != kSyncProtocol) {
        throw FormatException(
          '协议版本不一致（本机 $kSyncProtocol，对方 $protocol）',
        );
      }
      return SyncPeer(
        deviceName: (json['deviceName'] as String?) ?? '对面',
        protocol: protocol,
        needsCode: json['needsCode'] == true,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<SyncOutcome> sync({
    required TntDatabase db,
    required Uri base,
    required String code,
    required String deviceName,
  }) async {
    final peer = await probe(base);
    final snapshot = await readSnapshot(db);

    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.postUrl(base.replace(path: '/sync'));
      request.headers.contentType = ContentType.json;
      request.headers.set('x-tnt-code', code);
      request.headers.set('x-tnt-protocol', '$kSyncProtocol');
      request.write(encodeSnapshot(snapshot));
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body);
      if (response.statusCode != HttpStatus.ok) {
        final message = json is Map ? json['error'] : null;
        throw HttpException('对面拒绝：${message ?? response.statusCode}');
      }
      if (json is! Map) {
        throw const FormatException('对面返回的数据看不懂');
      }
      final mergedRaw = json['snapshot'];
      if (mergedRaw is! Map) {
        throw const FormatException('对面没有回快照');
      }
      final merged = SyncSnapshot.fromJson(mergedRaw.cast<String, Object?>());
      final stats = await applySnapshot(db, merged);
      return SyncOutcome(
        peerName: peer.deviceName,
        applied: stats.applied,
        skipped: stats.skipped,
      );
    } finally {
      client.close(force: true);
    }
  }
}
