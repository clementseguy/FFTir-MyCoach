import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/widgets/dashboard/advanced_stats_cards.dart';
import 'package:tir_sportif/models/dashboard_data.dart';

void main() {
  group('AdvancedStatsCards', () {
    testWidgets('displays loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des statistiques...'), findsOneWidget);
    });

    testWidgets('displays empty state with proper fallbacks', (WidgetTester tester) async {
      const emptyData = AdvancedStatsData.empty();
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: emptyData,
            ),
          ),
        ),
      );

      expect(find.text('Consistency'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Catégorie dominante'), findsOneWidget);
      
      // Vérifier les valeurs par défaut
      expect(find.text('-'), findsAtLeastNWidgets(3)); // consistency, progression, catégorie
    });

    testWidgets('displays valid data correctly', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 85.5,
        progression: 12.3,
        dominantCategory: 'match',
        dominantCategoryCount: 5,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
            ),
          ),
        ),
      );

      expect(find.text('85.5%'), findsOneWidget);
      expect(find.text('+12.3%'), findsOneWidget);
      expect(find.text('match (5)'), findsOneWidget);
    });

    testWidgets('handles negative progression', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 65.0,
        progression: -8.2,
        dominantCategory: 'entraînement',
        dominantCategoryCount: 3,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
            ),
          ),
        ),
      );

      expect(find.text('65.0%'), findsOneWidget);
      expect(find.text('-8.2%'), findsOneWidget);
      expect(find.text('entraînement (3)'), findsOneWidget);
    });

    testWidgets('handles NaN progression', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 70.0,
        progression: double.nan,
        dominantCategory: 'test matériel',
        dominantCategoryCount: 1,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
            ),
          ),
        ),
      );

      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('-'), findsAtLeastNWidgets(1)); // progression NaN -> '-'
      expect(find.text('test matériel (1)'), findsOneWidget);
    });

    testWidgets('adapts layout for mobile', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 80.0,
        progression: 5.0,
        dominantCategory: 'match',
        dominantCategoryCount: 2,
      );
      
      // Test avec contrainte mobile (width < 600)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Mobile width
              child: AdvancedStatsCards(
                data: data,
              ),
            ),
          ),
        ),
      );

      // Vérifier que les cartes sont en colonne (mobile)
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      
      // Maintenant test avec contrainte desktop (width >= 600)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800, // Desktop width
              child: AdvancedStatsCards(
                data: data,
              ),
            ),
          ),
        ),
      );

      // Vérifier que les cartes sont en ligne (desktop)
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });
}