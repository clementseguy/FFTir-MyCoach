import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/widgets/dashboard/flat_distribution_bar.dart';
import 'package:tir_sportif/models/dashboard_data.dart';

void main() {
  group('FlatDistributionBar', () {
    testWidgets('displays loading state', (WidgetTester tester) async {
      const emptyData = DistributionData.empty('Test Distribution');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatDistributionBar(
              data: emptyData,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Calcul des répartitions...'), findsOneWidget);
    });

    testWidgets('displays empty state when no data', (WidgetTester tester) async {
      const emptyData = DistributionData.empty('Test Distribution');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatDistributionBar(
              data: emptyData,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Test Distribution'), findsOneWidget);
      expect(find.text('Aucune donnée disponible'), findsOneWidget);
    });

    testWidgets('displays segmented bar with data', (WidgetTester tester) async {
      const data = DistributionData(
        data: {
          'entraînement': 60.0,
          'match': 30.0,
          'test matériel': 10.0,
        },
        title: 'Répartition Catégories',
        isPercentage: false,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatDistributionBar(
              data: data,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Répartition Catégories'), findsOneWidget);
      expect(find.text('entraînement'), findsOneWidget);
      expect(find.text('match'), findsOneWidget);
      expect(find.text('test matériel'), findsOneWidget);
      
      // Vérifier la présence des pourcentages calculés
      expect(find.textContaining('60 (60%)'), findsOneWidget);
      expect(find.textContaining('30 (30%)'), findsOneWidget);
      expect(find.textContaining('10 (10%)'), findsOneWidget);
    });

    testWidgets('handles percentage data correctly', (WidgetTester tester) async {
      const data = DistributionData(
        data: {
          '10m': 50.0,
          '25m': 30.0,
          '50m': 20.0,
        },
        title: 'Répartition Distances',
        isPercentage: true,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatDistributionBar(
              data: data,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Répartition Distances'), findsOneWidget);
      
      // Avec isPercentage = true, devrait afficher les pourcentages directement
      expect(find.textContaining('50.0%'), findsOneWidget);
      expect(find.textContaining('30.0%'), findsOneWidget);
      expect(find.textContaining('20.0%'), findsOneWidget);
    });

    testWidgets('responsive design on mobile', (WidgetTester tester) async {
      const data = DistributionData(
        data: {'test': 100.0},
        title: 'Test',
        isPercentage: false,
      );
      
      // Test avec largeur mobile
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Mobile width
              child: FlatDistributionBar(
                data: data,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      // Vérifier que le widget s'affiche sans erreur
      expect(find.text('Test'), findsOneWidget);
      
      // Test avec largeur desktop
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200, // Desktop width
              child: FlatDistributionBar(
                data: data,
                isLoading: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('filters out zero values', (WidgetTester tester) async {
      const data = DistributionData(
        data: {
          'visible': 100.0,
          'zero': 0.0,
          'also_visible': 50.0,
        },
        title: 'Filtered Test',
        isPercentage: false,
      );
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatDistributionBar(
              data: data,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('visible'), findsOneWidget);
      expect(find.text('also_visible'), findsOneWidget);
      expect(find.text('zero'), findsNothing); // Filtré car valeur 0
    });
  });
}