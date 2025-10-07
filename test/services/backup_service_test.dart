import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/backup_service.dart';
import 'package:tir_sportif/services/session_service.dart';

void main() {
  group('BackupService import/export (logic-only)', () {
    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('nt_backup_test_');
      Hive.init(dir.path);
      await Hive.openBox('sessions');
      await Hive.openBox('exercises');
      // Ne pas ouvrir 'goals' ici pour éviter conflit avec Box<Goal> typé
    });

    tearDown(() async {
      for (final name in ['sessions','exercises']) {
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      }
    });

  test('importSessionsFromJson happy path and invalids', () async {
      final svc = BackupService();
      // Build a minimal valid payload
      final payload = {
        'format': 'mycoach-data',
        'version': 2,
        'sessions': [
          {
            'id': 999,
            'date': DateTime(2025,10,1).toIso8601String(),
            'weapon': 'P', 'caliber': '22LR', 'status': 'réalisée', 'category': 'entraînement',
            'series': [ {'id':1,'shot_count':5,'distance':10,'points':50,'group_size':20,'comment':'','hand_method':'two'} ],
            'exercises': []
          }
        ]
      };
      final jsonStr = const JsonEncoder().convert(payload);
      final imported = await svc.importSessionsFromJson(jsonStr);
      expect(imported, 1);
      // ID should be reset to null on import (DB assigns new id)
      final all = await SessionService().getAllSessions();
      expect(all.length, 1);
      expect(all.first.id, isNotNull);

      // Invalid structures
      expect(() => svc.importSessionsFromJson('[]'), throwsFormatException);
      expect(() => svc.importSessionsFromJson('{"format":"wrong"}'), throwsFormatException);
      expect(() => svc.importSessionsFromJson('{"format":"mycoach-data"}'), throwsFormatException);
    });

    test('importSessionsFromJson accepts goals section (no crash)', () async {
      final svc = BackupService();
      final nowIso = DateTime(2025,10,1).toIso8601String();
      final payload = {
        'format': 'mycoach-data',
        'version': 2,
        'sessions': [],
        'goals': [
          {
            'id': 'g1',
            'title': 'Titre',
            'description': 'Desc',
            'metric': 1, // sessionCount
            'comparator': 0, // >=
            'targetValue': 5,
            'status': 0, // active
            'period': 1, // rollingWeek
            'createdAt': nowIso,
            'updatedAt': nowIso,
            'lastProgress': 0.4,
            'lastMeasuredValue': 2.0,
            'priority': 3,
          }
        ],
      };
      final jsonStr = const JsonEncoder().convert(payload);
      // L'import ne doit pas lever d'exception même si les adapters Hive ne sont pas enregistrés.
      final imported = await svc.importSessionsFromJson(jsonStr);
      expect(imported, 0);
    });

    // Note: exportAllSessionsToJsonFile test skipped due to platform channel dependency (path_provider) in unit tests
  });
}
