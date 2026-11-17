import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/sync/sync_client.dart';
import 'package:tnt_app/data/sync/sync_server.dart';
import 'package:tnt_app/data/sync/sync_snapshot.dart';

TntDatabase _mem() => TntDatabase.forTesting(NativeDatabase.memory());

/// day_blocks 里 NOT NULL 但没默认值的列要齐，否则插入会被 sqlite 拒掉。
Map<String, Object?> _blockRow({
  required String id,
  required int updatedAt,
  String date = '2026-11-14',
  String title = '测试方块',
  int startMin = 600,
  int? deletedAt,
}) {
  return <String, Object?>{
    'id': id,
    'date': date,
    'title': title,
    'lane': 0,
    'start_min': startMin,
    'duration_min': 30,
    'priority': 2,
    'deadline_at': null,
    'note': null,
    'done': 0,
    'status': 0,
    'manual_order': 0,
    'source_type': 0,
    'source_id': null,
    'template_snapshot': null,
    'from_block_id': null,
    'carry_count': 0,
    'original_date': null,
    'instance_group_id': null,
    'created_at': updatedAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}

SyncSnapshot _snapshotOf(List<Map<String, Object?>> blocks) {
  return SyncSnapshot(<String, List<Map<String, Object?>>>{
    for (final table in kSyncTableOrder)
      table: table == 'day_blocks' ? blocks : <Map<String, Object?>>[],
  });
}

Future<int> _count(TntDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT count(*) AS n FROM $table')
      .getSingle();
  return (row.data['n'] as num).toInt();
}

void main() {
  // flutter_test 默认把 HttpClient 换成假实现（一律回 400），
  // 这一层不加回来的话所有真实请求都会被挡掉。
  HttpOverrides.global = null;

  group('快照与合并', () {
    test('快照 JSON 来回一趟不丢行也不丢字段', () async {
      final db = _mem();
      addTearDown(db.close);
      await db.customStatement(
        'INSERT INTO day_blocks (id, date, title, lane, start_min, duration_min, '
        'priority, done, status, manual_order, source_type, carry_count, '
        'created_at, updated_at) VALUES '
        "('b1', '2026-11-14', '喂猫', 0, 430, 15, 3, 0, 0, 0, 0, 0, 1794662355, 1794662355)",
      );

      final snapshot = await readSnapshot(db);
      expect(snapshot.rowCount, 1);

      final decoded = decodeSnapshot(encodeSnapshot(snapshot));
      final row = decoded.tables['day_blocks']!.single;
      expect(row['id'], 'b1');
      expect(row['title'], '喂猫');
      expect(row['start_min'], 430);
    });

    test('新的覆盖旧的，旧的跳过，一样新也跳过（不来回抖）', () async {
      final db = _mem();
      addTearDown(db.close);
      await db.customStatement(
        'INSERT INTO day_blocks (id, date, title, lane, start_min, duration_min, '
        'priority, done, status, manual_order, source_type, carry_count, '
        'created_at, updated_at) VALUES '
        "('b1', '2026-11-14', '旧标题', 0, 430, 15, 3, 0, 0, 0, 0, 0, 1700000000, 1700000000)",
      );

      final newer = _snapshotOf([
        _blockRow(id: 'b1', updatedAt: 1700000100, title: '新标题'),
      ]);
      final first = await applySnapshot(db, newer);
      expect(first.applied, 1);
      expect(first.changed, isTrue);

      final row = await db
          .customSelect("SELECT title FROM day_blocks WHERE id = 'b1'")
          .getSingle();
      expect(row.data['title'], '新标题');

      // 再来一次：对端还是同一份，不该重复写
      final again = await applySnapshot(db, newer);
      expect(again.applied, 0);
      expect(again.skipped, 1);

      // 比本地旧的快照直接跳过
      final older = _snapshotOf([
        _blockRow(id: 'b1', updatedAt: 1699999999, title: '更旧标题'),
      ]);
      final third = await applySnapshot(db, older);
      expect(third.applied, 0);
    });

    test('墓碑会传播：对端软删除，本机也变删除', () async {
      final db = _mem();
      addTearDown(db.close);
      await db.customStatement(
        'INSERT INTO day_blocks (id, date, title, lane, start_min, duration_min, '
        'priority, done, status, manual_order, source_type, carry_count, '
        'created_at, updated_at) VALUES '
        "('b1', '2026-11-14', '要删的', 0, 430, 15, 3, 0, 0, 0, 0, 0, 1700000000, 1700000000)",
      );

      final tombstone = _snapshotOf([
        _blockRow(
          id: 'b1',
          updatedAt: 1700000200,
          title: '要删的',
          deletedAt: 1700000200,
        ),
      ]);
      final stats = await applySnapshot(db, tombstone);
      expect(stats.applied, 1);

      final row = await db
          .customSelect("SELECT deleted_at FROM day_blocks WHERE id = 'b1'")
          .getSingle();
      expect(row.data['deleted_at'], isA<Object>());
    });
  });

  group('真实 HTTP：一台当主机，另一台连上来', () {
    late TntDatabase host;
    late TntDatabase guest;
    late SyncServer server;

    setUp(() async {
      host = _mem();
      guest = _mem();
      server = await SyncServer.start(
        db: host,
        deviceName: '主机',
        code: '1234',
      );
    });

    tearDown(() async {
      await server.stop();
      await host.close();
      await guest.close();
    });

    Future<Uri> base() async =>
        Uri.parse('http://127.0.0.1:${server.port}');

    test('ping 能看到对端名字与协议版本', () async {
      final peer = await SyncClient.probe(await base());
      expect(peer.deviceName, '主机');
      expect(peer.protocol, kSyncProtocol);
      expect(peer.needsCode, isTrue);
    });

    test('配对码不对会被拒', () async {
      final uri = await base();
      expect(
        () => SyncClient.sync(
          db: guest,
          base: uri,
          code: '9999',
          deviceName: '手机',
        ),
        throwsA(isA<HttpException>()),
      );
    });

    test('双向合并：两边的行最后都在两边', () async {
      await host.customStatement(
        'INSERT INTO day_blocks (id, date, title, lane, start_min, duration_min, '
        'priority, done, status, manual_order, source_type, carry_count, '
        'created_at, updated_at) VALUES '
        "('host1', '2026-11-14', '电脑上的', 1, 540, 60, 1, 0, 0, 0, 0, 0, 1700000000, 1700000000)",
      );
      await guest.customStatement(
        'INSERT INTO day_blocks (id, date, title, lane, start_min, duration_min, '
        'priority, done, status, manual_order, source_type, carry_count, '
        'created_at, updated_at) VALUES '
        "('phone1', '2026-11-14', '手机上的', 2, 780, 30, 2, 0, 0, 0, 0, 0, 1700000001, 1700000001)",
      );

      final outcome = await SyncClient.sync(
        db: guest,
        base: await base(),
        code: '1234',
        deviceName: '手机',
      );
      expect(outcome.peerName, '主机');
      expect(outcome.applied, 1, reason: '手机把电脑那一行并了进来');

      expect(await _count(host, 'day_blocks'), 2);
      expect(await _count(guest, 'day_blocks'), 2);

      final titles = await guest
          .customSelect('SELECT title FROM day_blocks ORDER BY id')
          .get();
      expect(
        titles.map((r) => r.data['title']).toList(),
        ['电脑上的', '手机上的'],
      );
    });

    test('一端改完再同步，另一端拿到新值', () async {
      await host.customStatement(
        'INSERT INTO day_blocks (id, date, title, lane, start_min, duration_min, '
        'priority, done, status, manual_order, source_type, carry_count, '
        'created_at, updated_at) VALUES '
        "('b1', '2026-11-14', '原标题', 0, 600, 30, 2, 0, 0, 0, 0, 0, 1700000000, 1700000000)",
      );
      await SyncClient.sync(
        db: guest,
        base: await base(),
        code: '1234',
        deviceName: '手机',
      );

      // 主机侧改标题并推高 updated_at（模拟用户改了一个方块）
      await host.customStatement(
        "UPDATE day_blocks SET title = '电脑改了', updated_at = 1700009999 "
        "WHERE id = 'b1'",
      );
      await SyncClient.sync(
        db: guest,
        base: await base(),
        code: '1234',
        deviceName: '手机',
      );

      final row = await guest
          .customSelect("SELECT title FROM day_blocks WHERE id = 'b1'")
          .getSingle();
      expect(row.data['title'], '电脑改了');
    });
  });
}
