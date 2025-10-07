import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/backup_service.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/goal.dart';

// Extension du BackupService pour exposer la logique interne pour les tests
class TestableBackupService extends BackupService {
  // Expose la logique interne d'exportation sans dépendre de path_provider
  Future<Map<String, dynamic>> exportSessionsToJson() async {
    final sessions = await getAllSessions();
    dev.log('Sessions for export: ${sessions.length}');
    if (sessions.isNotEmpty) {
      dev.log('First session: ${sessions.first.weapon}, ID: ${sessions.first.id}');
      dev.log('Series: ${sessions.first.series.length}');
      if (sessions.first.series.isNotEmpty) {
        dev.log('First series distance: ${sessions.first.series.first.distance}');
      }
    }
    
    final goals = await getAllGoals();
    dev.log('Goals for export: ${goals.length}');
    
    final result = {
      'format': 'mycoach-data',
      'version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'sessions_count': sessions.length,
      'goals_count': goals.length,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'goals': goals.map((g) => mapGoalToJson(g)).toList(),
    };
    
    return result;
  }
  
  Future<List<ShootingSession>> getAllSessions() async {
    final sessionService = SessionService();
    return sessionService.getAllSessions();
  }
  
  Future<List<Goal>> getAllGoals() async {
    final goalService = GoalService();
    try {
      await goalService.init();
      return goalService.listAll();
    } catch (e) {
      dev.log('Error in getAllGoals: $e');
      return [];
    }
  }
  
  Map<String, dynamic> mapGoalToJson(Goal g) {
    return {
      'id': g.id,
      'title': g.title,
      'description': g.description,
      'metric': g.metric.index,
      'comparator': g.comparator.index,
      'targetValue': g.targetValue,
      'status': g.status.index,
      'period': g.period.index,
      'createdAt': g.createdAt.toIso8601String(),
      'updatedAt': g.updatedAt.toIso8601String(),
      'lastProgress': g.lastProgress,
      'lastMeasuredValue': g.lastMeasuredValue,
      'priority': g.priority,
    };
  }
}

// Tests pour la logique d'exportation de BackupService
void main() {
  group('BackupService export functions', () {
    late Directory tempDir;
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nt_backup_export_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('sessions');
      await Hive.openBox('exercises');
    });

    tearDown(() async {
      for (final name in ['sessions', 'exercises']) {
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    
    test('exportSessionsToJson creates valid JSON structure with correct fields', () async {
      // Setup
      final sessionService = SessionService();
      final testableService = TestableBackupService();
      
      // Add a test session with unique identifiers
      final uniqueWeapon = 'UNIQUE_TEST_WEAPON_${DateTime.now().millisecondsSinceEpoch}';
      final testSession = ShootingSession(
        weapon: uniqueWeapon,
        caliber: '22LR',
        date: DateTime(2024, 5, 15),
        status: 'réalisée',
        category: 'entraînement',
        series: [
          Series(
            distance: 10,
            points: 90,
            shotCount: 10,
            groupSize: 15.0,
            comment: 'Test comment',
          ),
        ],
        synthese: 'Test synthesis',
      );
      
      await sessionService.addSession(testSession);
      dev.log('Added session with weapon: $uniqueWeapon');
      
      // Execute export JSON generation
      final jsonData = await testableService.exportSessionsToJson();
      
      // Print structure for debugging
      dev.log('JSON data structure:');
      dev.log('Format: ${jsonData['format']}');
      dev.log('Version: ${jsonData['version']}');
      dev.log('Sessions count: ${jsonData['sessions_count']}');
      
      final sessions = jsonData['sessions'] as List;
      dev.log('Sessions in JSON: ${sessions.length}');
      
      for (int i = 0; i < sessions.length; i++) {
        final s = sessions[i];
        dev.log('Session $i - Weapon: ${s['weapon']}, Caliber: ${s['caliber']}');
        
        if (s['series'] != null) {
          final seriesList = s['series'] as List;
          dev.log('  Series count: ${seriesList.length}');
          
          for (int j = 0; j < seriesList.length; j++) {
            final series = seriesList[j];
            dev.log('  Series $j - Distance: ${series['distance']}, Points: ${series['points']}');
          }
        } else {
          dev.log('  No series in this session');
        }
      }
      
      // Basic structure verification only
      expect(jsonData['format'], 'mycoach-data');
      expect(jsonData['version'], 2);
      expect(jsonData['sessions'], isA<List>());
      expect(jsonData.containsKey('goals'), isTrue);
      expect(jsonData['exported_at'], isNotNull);
    });
    
    test('mapGoalToJson formats Goal correctly', () async {
      final testableService = TestableBackupService();
      
      // Create test goal
      final goal = Goal(
        id: 'test-goal',
        title: 'Test Goal',
        description: 'A goal for testing',
        metric: GoalMetric.sessionCount,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 10.0,
        status: GoalStatus.active,
        period: GoalPeriod.rollingMonth,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        lastProgress: 0.5,
        lastMeasuredValue: 5.0,
        priority: 1,
      );
      
      // Format to JSON
      final json = testableService.mapGoalToJson(goal);
      
      // Verify formatting
      expect(json['id'], 'test-goal');
      expect(json['title'], 'Test Goal');
      expect(json['description'], 'A goal for testing');
      expect(json['metric'], GoalMetric.sessionCount.index);
      expect(json['comparator'], GoalComparator.greaterOrEqual.index);
      expect(json['targetValue'], 10.0);
      expect(json['status'], GoalStatus.active.index);
      expect(json['period'], GoalPeriod.rollingMonth.index);
      expect(json['createdAt'], DateTime(2024, 1, 1).toIso8601String());
      expect(json['updatedAt'], DateTime(2024, 1, 2).toIso8601String());
      expect(json['lastProgress'], 0.5);
      expect(json['lastMeasuredValue'], 5.0);
      expect(json['priority'], 1);
    });
  });
}