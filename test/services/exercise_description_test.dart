import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/exercise_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise description persistence', () {
    late ExerciseService service;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('nt_test_ex_desc_');
      Hive.init(dir.path);
      await Hive.openBox('exercises');
      service = ExerciseService();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').clear();
    });

    test('store and retrieve multiline description', () async {
      final desc = 'Série 1 : 5 tirs lents en visée fine\nSérie 2 : 5 tirs cadence contrôlée main faible\nSérie 3 : 5 tirs alternance mains';
      await service.addExercise(name: 'Routine mixte', category: 'technique', description: desc);
      final list = await service.listAll();
      expect(list.length, 1);
      final ex = list.first;
      expect(ex.description, equals(desc));
      // Ensure first line extraction logic would work (UI responsibility)
      expect(ex.description!.split('\n').first.trim(), 'Série 1 : 5 tirs lents en visée fine');
    });
  });
}
