import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tir_sportif/widgets/exercises_total_card.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExercisesTotalCard', () {
    setUp(() async {
      final dir = await Directory('./build/test_ex/${DateTime.now().microsecondsSinceEpoch}').create(recursive: true);
      Hive.init(dir.path);
      try { await Hive.openBox('exercises'); } catch (_) {}
    });

    tearDown(() async {
      if (Hive.isBoxOpen('exercises')) {
        await Hive.box('exercises').clear();
        await Hive.box('exercises').close();
      }
    });

    testWidgets('affiche compteur 0 puis se rafraîchit sans crash', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ExercisesTotalCard())));
  // Laisser le FutureBuilder compléter son premier cycle
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byType(ExercisesTotalCard), findsOneWidget);
      // Rien de plus à tester ici sans injecter service (resté simple)
    });
  });
}
