import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/providers/home_screen_provider.dart';
import 'package:tir_sportif/interfaces/session_service_interface.dart';
import 'package:tir_sportif/interfaces/rolling_stats_service_interface.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/services/stats_contract.dart';
import 'package:tir_sportif/constants/session_constants.dart';

/// Mock simple du SessionService pour les tests
class MockSessionService implements ISessionService {
  final List<ShootingSession> _sessions;
  final bool _shouldThrowError;

  MockSessionService(this._sessions, {bool shouldThrowError = false}) : _shouldThrowError = shouldThrowError;

  @override
  Future<List<ShootingSession>> getAllSessions() async {
    if (_shouldThrowError) throw Exception('Database error');
    return _sessions;
  }

  @override
  Future<void> addSession(ShootingSession session) async {}

  @override
  Future<void> updateSession(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true, bool warnOnFallback = true}) async {}

  @override
  Future<void> deleteSession(int id) async {}

  @override
  Future<void> clearAllSessions() async {}

  @override
  Future<ShootingSession> convertPlannedToRealized({required ShootingSession session, String? weapon, String? caliber, String? category, String? synthese, DateTime? forcedDate, List<Series>? updatedSeries}) async {
    return session;
  }

  @override
  Future<void> updateSingleSeries(ShootingSession session, int seriesIndex, Series newSeries) async {}

  @override
  Future<ShootingSession> planFromExercise(exercise) async {
    throw UnimplementedError();
  }
}

/// Mock simple du RollingStatsService pour les tests
class MockRollingStatsService implements IRollingStatsService {
  final RollingStatsSnapshot _snapshot;

  MockRollingStatsService(this._snapshot);

  @override
  Future<RollingStatsSnapshot> compute() async => _snapshot;
}
void main() {
  group('HomeScreenProvider Enhanced Tests', () {
    late MockSessionService mockSessionService;
    late MockRollingStatsService mockRollingService;
    late HomeScreenProvider provider;

    const mockSnapshot = RollingStatsSnapshot(
      avg30: 85.0,
      avg60: 80.0,
      delta: 5.0,
      sessions30: 5,
      sessions60: 10,
    );

    setUp(() {
      mockRollingService = MockRollingStatsService(mockSnapshot);
    });

    test('should handle empty sessions gracefully', () async {
      // Arrange
      mockSessionService = MockSessionService([]);

      // Act
      provider = HomeScreenProvider(
        sessionService: mockSessionService,
        rollingService: mockRollingService,
      );

      // Wait for fetchSessions to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.filteredSessions, isEmpty);
      expect(provider.error, equals('Aucune donnée pour les graphes.'));
    });

    test('should load and process sessions successfully', () async {
      // Arrange
      final testSessions = [
        ShootingSession(
          id: 1,
          date: DateTime.now().subtract(const Duration(days: 1)),
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusRealisee,
          series: [
            Series(distance: 10, points: 95, groupSize: 15.5, shotCount: 10),
            Series(distance: 10, points: 87, groupSize: 18.2, shotCount: 10),
          ],
        ),
        ShootingSession(
          id: 2,
          date: DateTime.now().subtract(const Duration(days: 2)),
          weapon: 'Carabine',
          caliber: '22LR',
          status: SessionConstants.statusRealisee,
          series: [
            Series(distance: 25, points: 92, groupSize: 12.1, shotCount: 10),
          ],
        ),
      ];

      mockSessionService = MockSessionService(testSessions);

      // Act
      provider = HomeScreenProvider(
        sessionService: mockSessionService,
        rollingService: mockRollingService,
      );

      // Wait for fetchSessions to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.filteredSessions, hasLength(2));
      expect(provider.avgPoints30, greaterThan(0));
      expect(provider.avgGroup30, greaterThan(0));
    });

    test('should handle service errors gracefully', () async {
      // Arrange
      mockSessionService = MockSessionService([], shouldThrowError: true);

      // Act
      provider = HomeScreenProvider(
        sessionService: mockSessionService,
        rollingService: mockRollingService,
      );

      // Wait for fetchSessions to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Erreur lors du chargement des sessions'));
      expect(provider.filteredSessions, isEmpty);
    });

    test('should filter out planned sessions', () async {
      // Arrange
      final testSessions = [
        ShootingSession(
          id: 1,
          date: DateTime.now(),
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusRealisee,
          series: [Series(distance: 10, points: 95, groupSize: 15.5, shotCount: 10)],
        ),
        ShootingSession(
          id: 2,
          date: DateTime.now(),
          weapon: 'Pistolet',
          caliber: '22LR',
          status: SessionConstants.statusPrevue, // Planned session should be filtered out
          series: [Series(distance: 10, points: 100, groupSize: 10.0, shotCount: 10)],
        ),
      ];

      mockSessionService = MockSessionService(testSessions);

      // Act
      provider = HomeScreenProvider(
        sessionService: mockSessionService,
        rollingService: mockRollingService,
      );

      // Wait for fetchSessions to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(provider.filteredSessions, hasLength(1));
      expect(provider.filteredSessions.first.status, equals(SessionConstants.statusRealisee));
    });

    test('should calculate rolling stats correctly', () async {
      // Arrange
      mockSessionService = MockSessionService([]);

      // Act
      provider = HomeScreenProvider(
        sessionService: mockSessionService,
        rollingService: mockRollingService,
      );

      final snapshot = await provider.getRollingStats();

      // Assert
      expect(snapshot.avg30, equals(85.0));
      expect(snapshot.avg60, equals(80.0));
      expect(snapshot.delta, equals(5.0));
      expect(snapshot.sessions30, equals(5));
      expect(snapshot.sessions60, equals(10));
    });

    tearDown(() {
      provider.dispose();
    });
  });
}