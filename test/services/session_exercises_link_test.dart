import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/exercise_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session <-> Exercises linking', () {
    late SessionService sessionService;
    late ExerciseService exerciseService;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('nt_test_sessions_');
      Hive.init(dir.path);
      // Open needed boxes manually: sessions + exercises
      await Hive.openBox('sessions');
      await Hive.openBox('exercises');
      sessionService = SessionService();
      exerciseService = ExerciseService();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').clear();
      if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').clear();
    });

    test('create session with exercises and retrieve', () async {
      // Create a couple of exercises
      await exerciseService.addExercise(name: 'Drill précision', category: 'précision');
      await exerciseService.addExercise(name: 'Vitesse contrôlée', category: 'vitesse');
      final exList = await exerciseService.listAll();
      expect(exList.length, 2);

      final ids = exList.map((e) => e.id).toList();

      final session = ShootingSession(
        weapon: 'Pistolet',
        caliber: '22LR',
        date: DateTime(2024, 1, 10),
        series: [Series(shotCount: 5, distance: 25, points: 40, groupSize: 20, comment: '', handMethod: HandMethod.twoHands)],
        exercises: ids,
      );

      await sessionService.addSession(session);
      final all = await sessionService.getAllSessions();
      expect(all.length, 1);
      final stored = all.first;
      expect(stored.exercises.toSet(), ids.toSet());
    });
  });
}
