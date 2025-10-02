import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise consignes & planning', () {
    late ExerciseService exerciseService;
    late SessionService sessionService;

    setUp(() async {
      final dir = Directory('./build/test_ex');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      Hive.init(dir.path);
      exerciseService = ExerciseService();
      sessionService = SessionService();
      // Clear boxes
      try {
        final repoBox = await Hive.openBox('exercises');
        await repoBox.clear();
      } catch (_) {}
      try {
        final sessBox = await Hive.openBox('sessions');
        await sessBox.clear();
      } catch (_) {}
    });

    test('Persist consignes and recreate from map', () async {
      await exerciseService.addExercise(
        name: 'Drill précision',
        category: 'technique',
        consignes: ['Série 1 : tir lent', 'Série 2 : cadence moyenne', 'Série 3 : cadence rapide'],
      );
      final all = await exerciseService.listAll();
      expect(all.length, 1);
      final ex = all.first;
      expect(ex.consignes.length, 3);
      expect(ex.consignes[0], contains('tir lent'));
    });

    test('Planning creates one series per consigne (comment filled)', () async {
      await exerciseService.addExercise(
        name: 'Drill vitesse',
        category: 'vitesse',
        consignes: ['Phase 1', 'Phase 2', 'Phase 3'],
      );
      final exercise = (await exerciseService.listAll()).first;
      final session = await sessionService.planFromExercise(exercise);
      expect(session.status, 'prévue');
      expect(session.id, isNotNull);
      expect(session.exercises, contains(exercise.id));
      expect(session.series.length, 3);
      expect(session.series.map((s)=>s.comment).toList(), equals(['Phase 1','Phase 2','Phase 3']));
  expect(session.synthese, isNotNull);
  expect(session.synthese, contains('Drill vitesse'));
      // Reload sessions from repository to ensure series persisted
      final allSessions = await sessionService.getAllSessions();
      final planned = allSessions.firstWhere((s)=> s.exercises.contains(exercise.id));
      expect(planned.id, isNotNull);
      expect(planned.series.length, 3);
    });

    test('Planning exercise with no consigne -> single empty series', () async {
      await exerciseService.addExercise(
        name: 'Sans étapes',
        category: 'technique',
      );
      final exercise = (await exerciseService.listAll()).first;
      final session = await sessionService.planFromExercise(exercise);
      expect(session.series.length, 1);
      expect(session.series.first.comment, '');
      final allSessions = await sessionService.getAllSessions();
      final created = allSessions.firstWhere((s)=> s.exercises.contains(exercise.id));
      expect(created.id, isNotNull);
      expect(created.series.length, 1);
  expect(created.synthese, isNotNull);
  expect(created.synthese, contains('Sans étapes'));
    });
    
    test('Placeholder series has minimal non-empty metrics', () async {
  await exerciseService.addExerciseLegacy(name: 'Mini', category: 'technique');
      final ex = (await exerciseService.listAll()).first;
      final sess = await sessionService.planFromExercise(ex);
      expect(sess.series.first.shotCount, 1);
      expect(sess.series.first.distance, 1);
    });
  });
}
