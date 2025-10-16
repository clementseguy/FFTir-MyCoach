import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/dashboard_data.dart';
import 'package:tir_sportif/widgets/dashboard/stats_summary_cards.dart';

void main() {
  group('StatsSummaryCards', () {
    testWidgets('affiche les cartes avec les bonnes valeurs', (WidgetTester tester) async {
      const summary = DashboardSummary(
        avgPoints30Days: 42.5,
        avgGroupSize30Days: 8.9,
        bestScore: 48,
        bestGroupSize: 7.8,
        sessionsThisMonth: 3,
        hasBestScore: true,
        hasBestGroupSize: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsSummaryCards(summary: summary),
          ),
        ),
      );

      // Vérifier que les valeurs sont affichées
      expect(find.text('42.5'), findsOneWidget);
      expect(find.text('8.9'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('7.8'), findsOneWidget);

      // Vérifier les unités
      expect(find.text('pts'), findsNWidgets(2)); // Points + Meilleur Score
      expect(find.text('cm'), findsNWidgets(2)); // Groupement + Meilleur Groupement

      // Vérifier les titres
      expect(find.text('Moyenne Points 30j'), findsOneWidget);
      expect(find.text('Groupement Moy. 30j'), findsOneWidget);
      expect(find.text('Meilleur Score'), findsOneWidget);
      expect(find.text('Meilleur Groupement'), findsOneWidget);
    });

    testWidgets('affiche "-" pour les valeurs vides', (WidgetTester tester) async {
      const summary = DashboardSummary.empty();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsSummaryCards(summary: summary),
          ),
        ),
      );

      // Vérifier que "-" est affiché pour les valeurs vides
      expect(find.text('-'), findsNWidgets(2)); // Meilleur Score + Meilleur Groupement
      
      // Vérifier que les valeurs zéro sont affichées normalement
      expect(find.text('0.0'), findsNWidgets(2)); // Moyennes
    });

    testWidgets('affiche l\'état de chargement', (WidgetTester tester) async {
      const summary = DashboardSummary.empty();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsSummaryCards(summary: summary, isLoading: true),
          ),
        ),
      );

      // Vérifier que l'état de chargement est affiché (placeholders gris)
      expect(find.byType(Container), findsWidgets);
      
      // Ne devrait pas afficher les vraies valeurs
      expect(find.text('0.0'), findsNothing);
      expect(find.text('-'), findsNothing);
    });

    testWidgets('les cartes sont cliquables et bien organisées', (WidgetTester tester) async {
      const summary = DashboardSummary(
        avgPoints30Days: 42.5,
        avgGroupSize30Days: 8.9,
        bestScore: 48,
        bestGroupSize: 7.8,
        sessionsThisMonth: 3,
        hasBestScore: true,
        hasBestGroupSize: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsSummaryCards(summary: summary),
          ),
        ),
      );

      // Vérifier que les cartes sont dans un GridView
      expect(find.byType(GridView), findsOneWidget);
      
      // Vérifier qu'il y a 4 cartes
      expect(find.byType(Card), findsNWidgets(4));

      // Vérifier que les icônes sont présentes
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
    });
  });
}