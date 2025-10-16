import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/dashboard_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';

void main() {
  group('DashboardService - Advanced Features', () {
    late List<ShootingSession> testSessions;
    late DashboardService service;
    final now = DateTime(2025, 10, 10, 12, 0, 0);

    setUp(() {
      testSessions = _createTestSessions(now);
      service = DashboardService(testSessions, now: now);
    });

    test('generateAdvancedStats returns proper consistency and progression', () {
      final data = service.generateAdvancedStats();
      
      // Consistency devrait être calculé si ≥3 séries
      expect(data.consistency, greaterThanOrEqualTo(0));
      
      // Progression peut être NaN si pas assez de données dans les 2 fenêtres
      expect(data.progression.isNaN || data.progression.isFinite, isTrue);
      
      // Catégorie dominante devrait être définie avec des sessions test
      expect(data.dominantCategory, isNotNull);
      expect(data.dominantCategoryCount, greaterThan(0));
    });

    test('generateEvolutionComparison calculates 30j vs 90j averages', () {
      final data = service.generateEvolutionComparison();
      
      expect(data.title, 'Évolution 30j vs 90j');
      expect(data.avg30Days, greaterThanOrEqualTo(0));
      expect(data.avg90Days, greaterThanOrEqualTo(0));
      expect(data.delta, equals(data.avg30Days - data.avg90Days));
    });

    test('generateCorrelationData creates points with colors', () {
      final data = service.generateCorrelationData();
      
      expect(data.title, 'Corrélation Points/Groupement');
      expect(data.maxX, greaterThan(0));
      expect(data.maxY, equals(55.0)); // Selon spec
      
      if (data.points.isNotEmpty) {
        for (final point in data.points) {
          expect(point.x, greaterThan(0)); // Groupement valide uniquement
          expect(point.y, greaterThanOrEqualTo(0)); // Score valide
          expect(point.sessionColor, isNotNull);
        }
      }
    });

    test('generateHandSpecificEvolution handles empty data gracefully', () {
      final oneHandPointsData = service.generateHandSpecificPointsEvolution(HandMethod.oneHand);
      final oneHandGroupData = service.generateHandSpecificGroupSizeEvolution(HandMethod.oneHand);
      final twoHandsPointsData = service.generateHandSpecificPointsEvolution(HandMethod.twoHands);
      final twoHandsGroupData = service.generateHandSpecificGroupSizeEvolution(HandMethod.twoHands);
      
      expect(oneHandPointsData.title, contains('1 main'));
      expect(oneHandGroupData.title, contains('1 main'));
      expect(twoHandsPointsData.title, contains('2 mains'));
      expect(twoHandsGroupData.title, contains('2 mains'));
      
      // Vérifie que les données sont cohérentes
      expect(oneHandPointsData.unit, equals('pts'));
      expect(oneHandGroupData.unit, equals('cm'));
      expect(twoHandsPointsData.unit, equals('pts'));
      expect(twoHandsGroupData.unit, equals('cm'));
    });

    test('advanced stats handle empty sessions', () {
      final emptyService = DashboardService([], now: now);
      
      final advancedStats = emptyService.generateAdvancedStats();
      expect(advancedStats.consistency, equals(0.0)); // Pas assez de données (retourne 0 selon StatsService)
      expect(advancedStats.progression.isNaN, isTrue);
      expect(advancedStats.dominantCategory, isNull);
      
      final correlationData = emptyService.generateCorrelationData();
      expect(correlationData.points, isEmpty);
      
      final evolutionComparison = emptyService.generateEvolutionComparison();
      expect(evolutionComparison.avg30Days, equals(0.0));
      expect(evolutionComparison.avg90Days, equals(0.0));
    });

    test('hand specific evolution data respects empty state', () {
      final oneHandPointsData = service.generateHandSpecificPointsEvolution(HandMethod.oneHand);
      final oneHandGroupData = service.generateHandSpecificGroupSizeEvolution(HandMethod.oneHand);
      
      // Vérification de la cohérence des données d'évolution
      expect(oneHandPointsData.minY, lessThanOrEqualTo(oneHandPointsData.maxY));
      expect(oneHandGroupData.minY, lessThanOrEqualTo(oneHandGroupData.maxY));
      
      if (oneHandPointsData.dataPoints.isNotEmpty) {
        expect(oneHandPointsData.seriesDates.length, equals(oneHandPointsData.dataPoints.length));
        expect(oneHandPointsData.seriesIndices.length, equals(oneHandPointsData.dataPoints.length));
      }
      
      if (oneHandGroupData.dataPoints.isNotEmpty) {
        expect(oneHandGroupData.seriesDates.length, equals(oneHandGroupData.dataPoints.length));
        expect(oneHandGroupData.seriesIndices.length, equals(oneHandGroupData.dataPoints.length));
      }
    });
  });
}

/// Crée des sessions de test avec des données variées
List<ShootingSession> _createTestSessions(DateTime now) {
  final sessions = <ShootingSession>[];
  
  // Sessions récentes (30 derniers jours)
  for (int i = 0; i < 15; i++) {
    final date = now.subtract(Duration(days: i + 1));
    final category = i % 3 == 0 ? 'match' : 'entraînement';
    
    final series = <Series>[];
    for (int j = 0; j < 3; j++) {
      series.add(Series(
        distance: [10, 25, 50][j % 3].toDouble(),
        points: 30 + (i * 2) + j + (i % 5), // Variation réaliste
        groupSize: 15.0 + (i * 0.5) + j,
        handMethod: j % 2 == 0 ? HandMethod.twoHands : HandMethod.oneHand,
      ));
    }
    
    sessions.add(ShootingSession(
      id: i,
      date: date,
      weapon: 'Pistolet',
      caliber: '22LR',
      status: SessionConstants.statusRealisee,
      category: category,
      series: series,
    ));
  }
  
  // Sessions plus anciennes (60-90 jours) pour tester la progression
  for (int i = 0; i < 8; i++) {
    final date = now.subtract(Duration(days: 45 + i));
    final series = <Series>[
      Series(
        distance: 25,
        points: 25 + i, // Scores légèrement plus bas pour tester progression
        groupSize: 20.0 + i,
        handMethod: HandMethod.twoHands,
      ),
    ];
    
    sessions.add(ShootingSession(
      id: 100 + i,
      date: date,
      weapon: 'Pistolet',
      caliber: '22LR',
      status: SessionConstants.statusRealisee,
      category: 'entraînement',
      series: series,
    ));
  }
  
  return sessions;
}