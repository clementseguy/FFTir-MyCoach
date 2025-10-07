import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/widgets/series_list.dart';

extension ColorWithValues on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? this.red, 
      green ?? this.green, 
      blue ?? this.blue, 
      alpha ?? this.opacity
    );
  }
}

void main() {
  group('SeriesList', () {
    testWidgets('affiche un message quand aucune série n\'est disponible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeriesList(
              series: [],
            ),
          ),
        ),
      );

      // Vérifier que le message "Aucune série." est affiché
      expect(find.text('Aucune série.'), findsOneWidget);
    });

    testWidgets('affiche correctement une liste de séries', (WidgetTester tester) async {
      final series = [
        Series(
          id: 1,
          shotCount: 10,
          distance: 25,
          points: 95,
          groupSize: 5,
          comment: 'Bonne série',
          handMethod: HandMethod.twoHands,
        ),
        Series(
          id: 2,
          shotCount: 8,
          distance: 30,
          points: 85,
          groupSize: 7,
          comment: '',
          handMethod: HandMethod.oneHand,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeriesList(
              series: series,
            ),
          ),
        ),
      );

      // Vérifier que le nombre de cartes correspond au nombre de séries
      expect(find.byType(Card), findsNWidgets(2));
      
      // Vérifier que le contenu des séries est correctement affiché
      expect(find.text('Série 1'), findsOneWidget);
      expect(find.text('Série 2'), findsOneWidget);
      
      // Vérifier que les valeurs sont bien affichées pour la série 1
      expect(find.text('10'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('5.0 cm'), findsOneWidget);
      expect(find.text('Bonne série'), findsOneWidget);
      expect(find.text('2 mains'), findsOneWidget);
      
      // Vérifier que les valeurs sont bien affichées pour la série 2
      expect(find.text('8'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('7.0 cm'), findsOneWidget);
      expect(find.text('1 main'), findsOneWidget);
      
      // Le commentaire vide ne doit pas être affiché
      expect(find.text(''), findsNothing);
    });

    testWidgets('met en évidence la meilleure série en points et le meilleur groupement', (WidgetTester tester) async {
      final series = [
        Series(
          id: 1,
          shotCount: 10,
          distance: 25,
          points: 80,
          groupSize: 8,
          comment: '',
          handMethod: HandMethod.twoHands,
        ),
        Series(
          id: 2,
          shotCount: 10,
          distance: 25,
          points: 95, // Meilleur score
          groupSize: 6,
          comment: '',
          handMethod: HandMethod.twoHands,
        ),
        Series(
          id: 3,
          shotCount: 10,
          distance: 25,
          points: 70,
          groupSize: 4, // Meilleur groupement
          comment: '',
          handMethod: HandMethod.twoHands,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeriesList(
              series: series,
            ),
          ),
        ),
      );

      // Vérifier que les badges "Meilleurs points" et "Meilleur groupement" sont affichés
      expect(find.text('Meilleurs points'), findsOneWidget);
      expect(find.text('Meilleur groupement'), findsOneWidget);
    });
  });
}