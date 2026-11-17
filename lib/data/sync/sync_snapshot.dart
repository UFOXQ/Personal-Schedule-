import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/tnt_database.dart';

/// 同步协议版本。改字段/表结构时 +1，另一端会直接拒掉不兼容的对端，
/// 免得半新半旧的数据互相污染。
const int kSyncProtocol = 1;

/// 参与同步的表，以及写入顺序（父表在前，收集条目要等集合落库）。
/// 表名列名都是 drift 默认的 snake_case，两端 schema 必须一致。
const List<String> kSyncTableOrder = <String>[
  'collections',
  'collection_items',
  'block_templates',
  'plans',
  'day_blocks',
  'completion_logs',
  'inbox_items',
];

/// 一次全量快照：表名 → 行（行是 sqlite 原生值的 map，DateTime 存的是 drift 的
/// 时间戳整数）。数据量很小（五年也就几千行），全量比增量简单可靠。
class SyncSnapshot {
  SyncSnapshot(this.tables);

  final Map<String, List<Map<String, Object?>>> tables;

  int get rowCount => tables.values.fold(0, (sum, rows) => sum + rows.length);

  Map<String, Object?> toJson() => <String, Object?>{
    'tables': <String, Object?>{
      for (final entry in tables.entries) entry.key: entry.value,
    },
  };

  static SyncSnapshot fromJson(Map<String, Object?> json) {
    final raw = json['tables'];
    if (raw is! Map) {
      throw const FormatException('快照缺少 tables');
    }
    final tables = <String, List<Map<String, Object?>>>{};
    for (final name in kSyncTableOrder) {
      final rows = raw[name];
      tables[name] = rows is List
          ? <Map<String, Object?>>[
              for (final row in rows)
                if (row is Map) <String, Object?>{...row.cast<String, Object?>()},
            ]
          : <Map<String, Object?>>[];
    }
    return SyncSnapshot(tables);
  }
}

/// 合并结果，用来在界面上回一句「这次同步了什么」。
class SyncMergeStats {
  const SyncMergeStats({
    required this.applied,
    required this.skipped,
    required this.tables,
  });

  final int applied;
  final int skipped;
  final Map<String, int> tables;

  bool get changed => applied > 0;

  String describe() {
    if (applied == 0 && skipped == 0) return '两边都是空的';
    if (applied == 0) return '已经是最新的（比对 $skipped 行）';
    final detail = tables.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key} ${e.value}')
        .join('，');
    return '合并 $applied 行（$detail），跳过 $skipped 行';
  }
}

/// 把整库读成快照。软删除的行也要带上 —— 墓碑就是靠它们传播的。
Future<SyncSnapshot> readSnapshot(TntDatabase db) async {
  final tables = <String, List<Map<String, Object?>>>{};
  for (final name in kSyncTableOrder) {
    final rows = await db.customSelect('SELECT * FROM $name').get();
    tables[name] = <Map<String, Object?>>[
      for (final row in rows) Map<String, Object?>.from(row.data),
    ];
  }
  return SyncSnapshot(tables);
}

/// 把对端快照并进本地库：逐行按 `updated_at` 比新旧，新的覆盖旧的，
/// 一样新就保留本地（避免两端来回抖）。整个过程一个事务，
/// 用 `ON CONFLICT(id) DO UPDATE` 而不是 REPLACE —— REPLACE 会先删后插，
/// 触发外键级联把集合下面的条目清空。
Future<SyncMergeStats> applySnapshot(
  TntDatabase db,
  SyncSnapshot incoming,
) async {
  var applied = 0;
  var skipped = 0;
  final perTable = <String, int>{};

  await db.transaction(() async {
    for (final name in kSyncTableOrder) {
      final rows = incoming.tables[name] ?? const <Map<String, Object?>>[];
      perTable[name] = 0;
      for (final row in rows) {
        final id = row['id'];
        if (id is! String || id.isEmpty) {
          skipped++;
          continue;
        }
        final localUpdatedAt = await _updatedAtOf(db, name, id);
        final remoteUpdatedAt = _asEpoch(row['updated_at']);
        if (localUpdatedAt != null && remoteUpdatedAt <= localUpdatedAt) {
          skipped++;
          continue;
        }
        await _upsert(db, name, row);
        applied++;
        perTable[name] = perTable[name]! + 1;
      }
    }
  });

  return SyncMergeStats(applied: applied, skipped: skipped, tables: perTable);
}

Future<int?> _updatedAtOf(TntDatabase db, String table, String id) async {
  final rows = await db
      .customSelect('SELECT updated_at FROM $table WHERE id = ?', variables: [
        Variable<String>(id),
      ])
      .get();
  if (rows.isEmpty) return null;
  return _asEpoch(rows.first.data['updated_at']);
}

/// 统一成毫秒来比。注意 drift 的 DateTimeColumn 在 sqlite 里存的是**秒**
/// （实测 `typeof(updated_at)=integer`，值形如 1794662355），所以小于 1e11
/// 的整数按秒处理；类型转换器给的是 DateTime 时按毫秒算。
int _asEpoch(Object? value) {
  if (value is int) return value < 100000000000 ? value * 1000 : value;
  if (value is num) {
    final raw = value.toInt();
    return raw < 100000000000 ? raw * 1000 : raw;
  }
  if (value is DateTime) return value.millisecondsSinceEpoch;
  if (value is String) {
    return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
  }
  return 0;
}

Future<void> _upsert(
  TntDatabase db,
  String table,
  Map<String, Object?> row,
) async {
  final columns = row.keys.toList(growable: false);
  final placeholders = List.filled(columns.length, '?').join(', ');
  final updates = columns
      .where((c) => c != 'id')
      .map((c) => '$c = excluded.$c')
      .join(', ');
  final sql =
      'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders) '
      'ON CONFLICT(id) DO UPDATE SET $updates';
  await db.customStatement(sql, [
    for (final column in columns) row[column],
  ]);
}

/// 给配对码/设备名这类小东西用：把快照包成 HTTP 里传输的 JSON 文本。
String encodeSnapshot(SyncSnapshot snapshot) => jsonEncode(snapshot.toJson());

SyncSnapshot decodeSnapshot(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('同步数据不是 JSON 对象');
  }
  return SyncSnapshot.fromJson(decoded.cast<String, Object?>());
}
