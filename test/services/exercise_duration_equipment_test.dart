import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/exercise_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise duration & equipment persistence', () {
    late ExerciseService service;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('nt_test_ex_dur_');
      Hive.init(dir.path);
      await Hive.openBox('exercises');
      service = ExerciseService();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').clear();
    });

    test('store and retrieve duration & equipment', () async {
      await service.addExercise(
        name: 'Enchaînement vitesse',
        category: 'vitesse',
        durationMinutes: 18,
        equipment: 'Timer, 3 cibles métal',
      );
      final list = await service.listAll();
      expect(list.length, 1);
      final ex = list.first;
      expect(ex.durationMinutes, 18);
      expect(ex.equipment, 'Timer, 3 cibles métal');
    });
  });
}
