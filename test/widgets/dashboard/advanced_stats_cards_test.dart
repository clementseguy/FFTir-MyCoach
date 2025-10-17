import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/widgets/dashboard/advanced_stats_cards.dart';
import 'package:tir_sportif/widgets/dashboard/stat_card.dart';
import 'package:tir_sportif/models/dashboard_data.dart';

void main() {
  group('AdvancedStatsCards', () {
    testWidgets('displays loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              summary: DashboardSummary.empty(),
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(StatCardLoading), findsNWidgets(4));
    });

    testWidgets('displays empty state with proper fallbacks', (WidgetTester tester) async {
      const emptyData = AdvancedStatsData.empty();
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: emptyData,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('Régularité'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Prise dominante'), findsOneWidget);
      
      // Vérifier les valeurs par défaut
      expect(find.text('-'), findsAtLeastNWidgets(3)); // consistency, progression, prise
    });

    testWidgets('displays valid data correctly', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 85.5,
        progression: 12.3,
        dominantHandMethod: 'two',
        dominantHandMethodPercentage: 75.5,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('85.5%'), findsOneWidget);
      expect(find.text('+12.3%'), findsOneWidget);
      expect(find.text('2 mains (75.5%)'), findsOneWidget);
    });

    testWidgets('handles negative progression', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 65.0,
        progression: -8.2,
        dominantHandMethod: 'one',
        dominantHandMethodPercentage: 40.2,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('65.0%'), findsOneWidget);
      expect(find.text('-8.2%'), findsOneWidget);
      expect(find.text('1 main (40.2%)'), findsOneWidget);
    });

    testWidgets('handles NaN progression', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 70.0,
        progression: double.nan,
        dominantHandMethod: 'two',
        dominantHandMethodPercentage: 88.9,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('-'), findsAtLeastNWidgets(1)); // progression NaN -> '-'
      expect(find.text('2 mains (88.9%)'), findsOneWidget);
    });

    testWidgets('displays widgets correctly', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 80.0,
        progression: 5.0,
        dominantHandMethod: 'two',
        dominantHandMethodPercentage: 66.7,
      );
      
      // Test simple sans contraintes spécifiques
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      // Vérifier que les cartes utilisent GridView
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(StatCard), findsNWidgets(4));
      
      // Vérifier le contenu
      expect(find.text('Sessions ce mois'), findsOneWidget);
      expect(find.text('Régularité'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Prise dominante'), findsOneWidget);
    });
  });
}