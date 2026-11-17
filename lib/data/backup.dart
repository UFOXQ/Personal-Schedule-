import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:path_provider/path_provider.dart';

import '../data/db/tnt_database.dart';
import '../data/sync/sync_snapshot.dart';

/// 备份文件格式版本。以后改字段时 +1，旧备份仍然能读（只做加法）。
const int kBackupVersion = 1;

/// 备份里除了同步那几张表，还要带上自定义泳道 —— 它只存在本机，丢了很烦。
const List<String> _extraBackupTables = <String>['lane_rows'];

/// 一次导出的结果。
class BackupFile {
  const BackupFile({required this.path, required this.rows});

  final String path;
  final int rows;

  String get name => path.split(Platform.pathSeparator).last;
}

/// 备份目录：应用数据目录下的 `backups/`（Windows 是 %APPDATA%，Android 是 app 私有目录）。
Future<Directory> backupDirectory([Directory? override]) async {
  if (override != null && !await override.exists()) {
    await override.create(recursive: true);
  }
  final base = override ?? await getApplicationSupportDirectory();
  final dir = Directory('${base.path}${Platform.pathSeparator}backups');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

String _stamp(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}-'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
}

/// 把整库导出成一个 JSON 文件，返回文件路径与行数。
Future<BackupFile> exportBackup(
  TntDatabase db, {
  DateTime? now,
  Directory? directory,
}) async {
  final snapshot = await readSnapshot(db);
  final tables = <String, Object?>{
    for (final entry in snapshot.tables.entries) entry.key: entry.value,
  };
  var rows = snapshot.rowCount;
  for (final name in _extraBackupTables) {
    try {
      final result = await db.customSelect('SELECT * FROM $name').get();
      final list = <Map<String, Object?>>[
        for (final row in result) Map<String, Object?>.from(row.data),
      ];
      tables[name] = list;
      rows += list.length;
    } catch (_) {
      // 老版本库没有这张表，忽略
    }
  }

  final payload = <String, Object?>{
    'format': 'tnt-backup',
    'version': kBackupVersion,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'tables': tables,
  };
  final dir = await backupDirectory(directory);
  final file = File(
    '${dir.path}${Platform.pathSeparator}tnt-${_stamp(now ?? DateTime.now())}.json',
  );
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  return BackupFile(path: file.path, rows: rows);
}

/// 校验并解析备份文件；格式不对就抛 [FormatException]。
(DateTime?, SyncSnapshot) parseBackup(String text) {
  final decoded = jsonDecode(text);
  if (decoded is! Map) {
    throw const FormatException('不是有效的备份文件');
  }
  final map = decoded.cast<String, Object?>();
  if (map['format'] != 'tnt-backup') {
    throw const FormatException('不是 TNT 的备份文件');
  }
  final version = map['version'];
  if (version is! int || version > kBackupVersion) {
    throw FormatException('备份版本过新（$version），先升级 App');
  }
  final exportedAt = DateTime.tryParse('${map['exportedAt'] ?? ''}');
  return (exportedAt, SyncSnapshot.fromJson(map));
}

/// 从备份文件恢复：按 `updated_at` 合并（和局域网同步同一套规则，不会把更新的行改旧）。
Future<SyncMergeStats> restoreBackup(TntDatabase db, String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw const FormatException('备份文件不在了');
  }
  final text = await file.readAsString();
  final (_, snapshot) = parseBackup(text);
  final stats = await applySnapshot(db, snapshot);
  // 自定义泳道：同步快照只认已知表，这里从原始 JSON 里单独取
  final raw = jsonDecode(text);
  final rawTables = raw is Map ? raw['tables'] : null;
  final laneRaw = rawTables is Map ? rawTables['lane_rows'] : null;
  final laneRows = laneRaw is List
      ? [
          for (final row in laneRaw)
            if (row is Map) row.cast<String, Object?>(),
        ]
      : const <Map<String, Object?>>[];
  if (laneRows.isNotEmpty) {
    await db.transaction(() async {
      try {
        await db.customStatement('DELETE FROM lane_rows');
      } catch (_) {
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (final row in laneRows) {
        final id = row['id'];
        final name = row['name'];
        if (id is! String || name is! String) continue;
        final order = row['sort_order'];
        final created = row['created_at'];
        final updated = row['updated_at'];
        await db.customInsert(
          'INSERT INTO lane_rows '
          '(id, name, sort_order, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, NULL)',
          variables: [
            Variable<String>(id),
            Variable<String>(name),
            Variable<int>(order is int ? order : 0),
            Variable<int>(created is int ? created : now),
            Variable<int>(updated is int ? updated : now),
          ],
        );
      }
    });
  }
  return stats;
}

/// 列出备份目录里的文件，新的在前。
Future<List<({String path, String name, int size, DateTime modified})>>
listBackups({Directory? directory}) async {
  final dir = await backupDirectory(directory);
  final files = <({String path, String name, int size, DateTime modified})>[];
  await for (final entity in dir.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final stat = await entity.stat();
    files.add((
      path: entity.path,
      name: entity.path.split(Platform.pathSeparator).last,
      size: stat.size,
      modified: stat.modified,
    ));
  }
  files.sort((a, b) => b.modified.compareTo(a.modified));
  return files;
}
