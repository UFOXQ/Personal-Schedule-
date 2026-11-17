import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/backup.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock _block(
  String id, {
  String title = '测试方块',
  Lane lane = Lane.daily,
  int startMin = 600,
  int durationMin = 30,
}) {
  return TBlock(
    id: id,
    title: title,
    lane: lane,
    startMin: startMin,
    durationMin: durationMin,
    priority: Priority.c,
  );
}

void main() {
  late TntDatabase db;
  late DayBlockRepository dayRepo;
  late Directory tempDir;

  setUp(() async {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    dayRepo = DayBlockRepository(db);
    tempDir = await Directory.systemTemp.createTemp('tnt-backup-test');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('导出后能解析回来，表与行数都在', () async {
    await dayRepo.upsertAll([
      _block('b1', title: '早饭', startMin: 460),
      _block('b2', title: '午饭', startMin: 765, durationMin: 45),
    ], '2026-11-17');

    final file = await exportBackup(
      db,
      now: DateTime(2026, 11, 17, 9, 30),
      directory: tempDir,
    );

    expect(file.rows, greaterThanOrEqualTo(2));
    expect(await File(file.path).exists(), isTrue);
    expect(file.name, startsWith('tnt-20261117-093000'));

    final text = await File(file.path).readAsString();
    final raw = jsonDecode(text) as Map<String, Object?>;
    expect(raw['format'], 'tnt-backup');
    expect(raw['version'], kBackupVersion);

    final (exportedAt, snapshot) = parseBackup(text);
    expect(exportedAt, DateTime(2026, 11, 17, 9, 30));
    final rows = snapshot.tables['day_blocks']!;
    expect(rows, hasLength(2));
    expect(rows.map((r) => r['title']), containsAll(['早饭', '午饭']));
  });

  test('坏格式与过新版本都会被拒绝', () async {
    expect(() => parseBackup('not json'), throwsFormatException);
    expect(
      () => parseBackup(jsonEncode({'format': 'other', 'version': 1})),
      throwsFormatException,
    );
    expect(
      () => parseBackup(jsonEncode({
        'format': 'tnt-backup',
        'version': kBackupVersion + 1,
        'tables': <String, Object?>{},
      })),
      throwsFormatException,
    );
  });

  test('恢复到另一个库，行数与内容一致', () async {
    await dayRepo.upsertAll([
      _block('b1', title: '早饭', startMin: 460),
      _block('b2', title: '午饭', startMin: 765, durationMin: 45),
    ], '2026-11-17');
    final file = await exportBackup(db, directory: tempDir);

    final target = TntDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    final stats = await restoreBackup(target, file.path);
    expect(stats.applied + stats.skipped, greaterThanOrEqualTo(2));

    final restored = await DayBlockRepository(target).loadDay('2026-11-17');
    expect(restored, hasLength(2));
    expect(restored.map((b) => b.title), containsAll(['早饭', '午饭']));
  });

  test('自定义泳道也会跟着备份恢复', () async {
    await db.customInsert(
      'INSERT INTO lane_rows '
      '(id, name, sort_order, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable<String>('lane-work'),
        Variable<String>('工作'),
        Variable<int>(3),
        Variable<int>(0),
        Variable<int>(0),
      ],
    );
    await dayRepo.upsert(_block('b1', title: '写周报', lane: Lane.daily), '2026-11-17');
    final file = await exportBackup(db, directory: tempDir);

    final target = TntDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    await restoreBackup(target, file.path);

    final lanes = await target.customSelect('SELECT name FROM lane_rows').get();
    expect(lanes.map((r) => r.data['name']), contains('工作'));
  });
}
