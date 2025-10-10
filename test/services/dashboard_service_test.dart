import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/dashboard_data.dart';
import 'package:tir_sportif/services/dashboard_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';

void main() {
  group('DashboardService', () {
    late DateTime now;
    late List<ShootingSession> sessions;
    
    setUp(() {
      now = DateTime(2025, 10, 10, 12, 0, 0);
      sessions = [
        // Session récente avec bonnes séries (5 oct)
        ShootingSession(
          id: 1,
          date: DateTime(2025, 10, 5), // Ce mois (octobre)
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusRealisee,
          category: SessionConstants.categoryEntrainement,
          series: [
            Series(distance: 10, points: 45, groupSize: 8.5),
            Series(distance: 10, points: 42, groupSize: 9.2),
            Series(distance: 25, points: 38, groupSize: 12.1),
          ],
        ),
        // Session mois précédent (25 sept)
        ShootingSession(
          id: 2,
          date: DateTime(2025, 9, 25), // Mois précédent, mais dans les 30j
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusRealisee,
          category: SessionConstants.categoryMatch,
          series: [
            Series(distance: 25, points: 48, groupSize: 7.8),
            Series(distance: 25, points: 44, groupSize: 8.9),
          ],
        ),
        // Session récente ce mois (8 oct)
        ShootingSession(
          id: 3,
          date: DateTime(2025, 10, 8), // Ce mois (octobre)
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusRealisee,
          category: SessionConstants.categoryTest,
          series: [
            Series(distance: 50, points: 35, groupSize: 15.2),
          ],
        ),
        // Session prévue (doit être exclue)
        ShootingSession(
          id: 4,
          date: now.add(const Duration(days: 1)),
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusPrevue,
          category: SessionConstants.categoryEntrainement,
          series: [
            Series(distance: 10, points: 50, groupSize: 5.0),
          ],
        ),
      ];
    });

    group('generateSummary', () {
      test('calcule correctement les moyennes 30j', () {
        final service = DashboardService(sessions, now: now);
        final summary = service.generateSummary();
        
        // Moyenne points: (45+42+38+48+44+35) / 6 = 42.0
        expect(summary.avgPoints30Days, closeTo(42.0, 0.1));
        
        // Moyenne groupement: (8.5+9.2+12.1+7.8+8.9+15.2) / 6 = 10.28
        expect(summary.avgGroupSize30Days, closeTo(10.28, 0.1));
        
        // Sessions ce mois: 2 sessions (id 1, 3) - id 2 est en septembre  
        expect(summary.sessionsThisMonth, equals(2));
        
        // Meilleur score: 48 points
        expect(summary.bestScore, equals(48));
        expect(summary.hasBestScore, isTrue);
        
        // Meilleur groupement: 7.8 cm (plus petit > 0)
        expect(summary.bestGroupSize, closeTo(7.8, 0.1));
        expect(summary.hasBestGroupSize, isTrue);
      });
      
      test('gère les sessions vides', () {
        final service = DashboardService([], now: now);
        final summary = service.generateSummary();
        
        expect(summary.avgPoints30Days, equals(0.0));
        expect(summary.avgGroupSize30Days, equals(0.0));
        expect(summary.sessionsThisMonth, equals(0));
        expect(summary.bestScore, equals(0));
        expect(summary.hasBestScore, isFalse);
        expect(summary.bestGroupSize, equals(0.0));
        expect(summary.hasBestGroupSize, isFalse);
      });
    });

    group('generateScoreEvolution', () {
      test('génère les données d\'évolution score', () {
        final service = DashboardService(sessions, now: now);
        final evolution = service.generateScoreEvolution();
        
        expect(evolution.title, equals('Évolution Score'));
        expect(evolution.unit, equals('pts'));
        expect(evolution.dataPoints.length, equals(6)); // 6 séries réalisées
        expect(evolution.sma3Points.length, equals(6)); // SMA3 calculé
        
        // Vérifier l'ordre chronologique (plus ancien au plus récent)
        expect(evolution.dataPoints.first.y, equals(48)); // Plus ancienne série
        expect(evolution.dataPoints.last.y, equals(35)); // Plus récente série
      });
      
      test('gère les sessions vides', () {
        final service = DashboardService([], now: now);
        final evolution = service.generateScoreEvolution();
        
        expect(evolution.dataPoints, isEmpty);
        expect(evolution.sma3Points, isEmpty);
      });
    });

    group('generateCategoryDistribution', () {
      test('calcule les pourcentages de catégories', () {
        final service = DashboardService(sessions, now: now);
        final distribution = service.generateCategoryDistribution();
        
        expect(distribution.title, equals('Répartition Catégories'));
        expect(distribution.isPercentage, isTrue);
        
        // 3 sessions: 1 entraînement, 1 match, 1 test -> 33.33% chacun
        expect(distribution.data['Entraînement'], closeTo(33.33, 0.1));
        expect(distribution.data['Match'], closeTo(33.33, 0.1));
        expect(distribution.data['Test Matériel'], closeTo(33.33, 0.1));
      });
    });

    group('generatePointsDistribution', () {
      test('génère les buckets de points', () {
        final service = DashboardService(sessions, now: now);
        final histogram = service.generatePointsDistribution();
        
        expect(histogram.title, equals('Distribution Points'));
        expect(histogram.buckets, isNotEmpty);
        
        // Vérifier qu'il y a des buckets pour les scores présents
        final labels = histogram.buckets.map((b) => b.label).toList();
        expect(labels.any((l) => l.contains('30-39')), isTrue); // Score 35, 38
        expect(labels.any((l) => l.contains('40-49')), isTrue); // Scores 42, 44, 45, 48
      });
    });

    group('generateDistanceDistribution', () {
      test('calcule les pourcentages de distances', () {
        final service = DashboardService(sessions, now: now);
        final distribution = service.generateDistanceDistribution();
        
        expect(distribution.title, equals('Répartition Distances'));
        expect(distribution.isPercentage, isTrue);
        
        // 6 séries: 2x10m (session 1), 2x25m (session 2), 1x25m (session 1), 1x50m (session 3)
        // Total: 2x10m, 3x25m, 1x50m = 6 séries
        expect(distribution.data['10m'], closeTo(33.33, 0.1)); // 2/6 = 33.33%
        expect(distribution.data['25m'], closeTo(50.0, 0.1)); // 3/6 = 50%
        expect(distribution.data['50m'], closeTo(16.67, 0.1)); // 1/6 = 16.67%
      });
    });
  });

  group('DashboardSummary', () {
    test('constructeur par défaut', () {
      const summary = DashboardSummary(
        avgPoints30Days: 42.5,
        avgGroupSize30Days: 8.9,
        bestScore: 48,
        bestGroupSize: 7.8,
        sessionsThisMonth: 3,
        hasBestScore: true,
        hasBestGroupSize: true,
      );
      
      expect(summary.avgPoints30Days, equals(42.5));
      expect(summary.avgGroupSize30Days, equals(8.9));
      expect(summary.bestScore, equals(48));
    });
    
    test('constructeur empty', () {
      const summary = DashboardSummary.empty();
      
      expect(summary.avgPoints30Days, equals(0.0));
      expect(summary.avgGroupSize30Days, equals(0.0));
      expect(summary.bestScore, equals(0));
      expect(summary.bestGroupSize, equals(0.0));
      expect(summary.sessionsThisMonth, equals(0));
      expect(summary.hasBestScore, isFalse);
      expect(summary.hasBestGroupSize, isFalse);
    });
  });
}