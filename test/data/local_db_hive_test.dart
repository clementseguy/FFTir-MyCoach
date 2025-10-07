import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/data/local_db_hive.dart';

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('nt_local_hive_');
    Hive.init(dir.path);
    await Hive.openBox('sessions');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
  });

  test('insertRandomSessions and clearAllSessions', () async {
    final db = LocalDatabaseHive();
    await db.insertRandomSessions(count: 3);
    final all = await db.getSessionsWithSeries();
    expect(all.length, 3);
    await db.clearAllSessions();
    final after = await db.getSessionsWithSeries();
    expect(after, isEmpty);
  });
}
