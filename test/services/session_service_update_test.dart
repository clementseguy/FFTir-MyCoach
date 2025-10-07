import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/exercise.dart';

void main() {
  group('SessionService update and planning methods', () {
    late Directory tempDir;
    
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('session_test_');
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
    
    test('updateSingleSeries modifies specific series in a session', () async {
      final service = SessionService();
      
      // Create session with multiple series
      final session = ShootingSession(
        weapon: 'Pistol',
        caliber: '22LR',
        date: DateTime(2024, 5, 1),
        status: 'prévue',
        category: 'entraînement',
        series: [
          Series(
            id: 1,
            distance: 10,
            points: 80,
            shotCount: 10,
            groupSize: 10.0,
            comment: 'Original Series 1',
          ),
          Series(
            id: 2,
            distance: 25,
            points: 90,
            shotCount: 5,
            groupSize: 5.0,
            comment: 'Original Series 2',
          ),
        ],
      );
      
      await service.addSession(session);
      
      // Create updated series
      final updatedSeries = Series(
        id: 2, // Same ID as the second series
        distance: 25,
        points: 95, // Modified points
        shotCount: 10, // Modified shot count
        groupSize: 3.0, // Modified group size
        comment: 'Updated Series 2', // Modified comment
      );
      
      // Update just the second series
      await service.updateSingleSeries(session, 1, updatedSeries);
      
      // Verify the update
      final allSessions = await service.getAllSessions();
      expect(allSessions.length, 1);
      
      final updatedSession = allSessions[0];
      expect(updatedSession.series.length, 2);
      
      // First series should be unchanged
      expect(updatedSession.series[0].id, 1);
      expect(updatedSession.series[0].points, 80);
      expect(updatedSession.series[0].comment, 'Original Series 1');
      
      // Second series should be updated
      expect(updatedSession.series[1].id, 2);
      expect(updatedSession.series[1].points, 95);
      expect(updatedSession.series[1].shotCount, 10);
      expect(updatedSession.series[1].groupSize, 3.0);
      expect(updatedSession.series[1].comment, 'Updated Series 2');
      
      // Status should still be 'prévue'
      expect(updatedSession.status, 'prévue');
    });
    
    test('updateSingleSeries handles invalid index safely', () async {
      final service = SessionService();
      
      // Create session with a single series
      final session = ShootingSession(
        weapon: 'Pistol',
        caliber: '22LR',
        series: [
          Series(
            distance: 10,
            points: 80,
            shotCount: 10,
            groupSize: 10.0,
            comment: 'Original Series',
          ),
        ],
        status: 'prévue',
        category: 'entraînement',
      );
      
      await service.addSession(session);
      
      // Try to update with negative index
      final newSeries = Series(
        distance: 25,
        points: 95,
        shotCount: 5,
        groupSize: 5.0,
        comment: 'New Series',
      );
      
      // This should not throw or modify the session
      await service.updateSingleSeries(session, -1, newSeries);
      await service.updateSingleSeries(session, 99, newSeries);
      
      // Verify no changes
      final allSessions = await service.getAllSessions();
      expect(allSessions.length, 1);
      
      final unchangedSession = allSessions[0];
      expect(unchangedSession.series.length, 1);
      expect(unchangedSession.series[0].distance, 10);
      expect(unchangedSession.series[0].points, 80);
      expect(unchangedSession.series[0].comment, 'Original Series');
    });
    
    test('planFromExercise creates planned session with series from exercise consignes', () async {
      final service = SessionService();
      
      // Create a test exercise with consignes
      final exercise = Exercise(
        id: 'test-exercise',
        name: 'Test Exercise',
        description: 'Test Description',
        type: ExerciseType.stand, // Important: must be stand type
        categoryEnum: ExerciseCategory.precision,
        createdAt: DateTime.now(),
        consignes: [
          'First step: do this',
          'Second step: do that',
          'Final step: finish',
        ],
      );
      
      // Create planned session from exercise
      final plannedSession = await service.planFromExercise(exercise);
      
      // Verify session properties
      expect(plannedSession.id, isNotNull);
      expect(plannedSession.status, 'prévue');
      expect(plannedSession.exercises, contains('test-exercise'));
      expect(plannedSession.category, 'entraînement');
      expect(plannedSession.synthese, contains('Test Exercise'));
      
      // Verify series were created from consignes
      expect(plannedSession.series.length, 3); // One per consigne
      
      // Check that series comments match consignes
      expect(plannedSession.series[0].comment, 'First step: do this');
      expect(plannedSession.series[1].comment, 'Second step: do that');
      expect(plannedSession.series[2].comment, 'Final step: finish');
    });
    
    test('planFromExercise creates a default series for exercise without consignes', () async {
      final service = SessionService();
      
      // Create exercise without consignes
      final exercise = Exercise(
        id: 'empty-exercise',
        name: 'Empty Exercise',
        description: 'No consignes',
        type: ExerciseType.stand,
        categoryEnum: ExerciseCategory.precision,
        createdAt: DateTime.now(),
        consignes: [], // No consignes
      );
      
      // Create planned session
      final plannedSession = await service.planFromExercise(exercise);
      
      // Verify session properties
      expect(plannedSession.id, isNotNull);
      expect(plannedSession.status, 'prévue');
      expect(plannedSession.exercises, contains('empty-exercise'));
      
      // Should have one default series
      expect(plannedSession.series.length, 1);
      expect(plannedSession.series[0].distance, 1);
      expect(plannedSession.series[0].points, 0);
      expect(plannedSession.series[0].shotCount, 1);
      expect(plannedSession.series[0].comment, '');
    });
    
    test('planFromExercise throws error for non-stand exercise type', () async {
      final service = SessionService();
      
      // Create exercise with wrong type
      final exercise = Exercise(
        id: 'wrong-type',
        name: 'Wrong Type Exercise',
        description: 'This should fail',
        type: ExerciseType.home, // Not a stand exercise
        categoryEnum: ExerciseCategory.mental,
        createdAt: DateTime.now(),
        consignes: ['This should not be planned'],
      );
      
      // Should throw StateError
      expect(() => service.planFromExercise(exercise), throwsStateError);
    });
  });
}