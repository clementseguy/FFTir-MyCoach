import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/constants/session_constants.dart';

/// Mock simple du SessionRepository pour les tests
class MockSessionRepository implements SessionRepository {
  final List<ShootingSession> _sessions = [];
  bool _shouldThrowError = false;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  @override
  Future<List<ShootingSession>> getAll() async {
    if (_shouldThrowError) throw Exception('Database error');
    return List.from(_sessions);
  }

  @override
  Future<int> insert(ShootingSession session) async {
    if (_shouldThrowError) throw Exception('Database error');
    final id = _sessions.length;
    session.id = id;
    _sessions.add(session);
    return id;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    if (_shouldThrowError) throw Exception('Database error');
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
      return false; // Pas de fallback
    }
    return false;
  }

  @override
  Future<void> delete(int id) async {
    if (_shouldThrowError) throw Exception('Database error');
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> clearAll() async {
    if (_shouldThrowError) throw Exception('Database error');
    _sessions.clear();
  }
}

void main() {
  group('SessionService Tests', () {
    late SessionService sessionService;
    late MockSessionRepository mockRepository;

    setUp(() {
      mockRepository = MockSessionRepository();
      sessionService = SessionService(repository: mockRepository);
    });

    test('should get all sessions successfully', () async {
      // Arrange
      final session = ShootingSession(
        weapon: 'Pistolet',
        caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 95, groupSize: 15.5, shotCount: 10),
        ],
      );
      await mockRepository.insert(session);

      // Act
      final sessions = await sessionService.getAllSessions();

      // Assert
      expect(sessions, hasLength(1));
      expect(sessions.first.weapon, equals('Pistolet'));
      expect(sessions.first.caliber, equals('22LR'));
      expect(sessions.first.series, hasLength(1));
    });

    test('should add session successfully', () async {
      // Arrange
      final session = ShootingSession(
        weapon: 'Carabine',
        caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 25, points: 87, groupSize: 12.1, shotCount: 10),
        ],
      );

      // Act
      await sessionService.addSession(session);

      // Assert
      final sessions = await sessionService.getAllSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first.id, isNotNull);
      expect(sessions.first.weapon, equals('Carabine'));
    });

    test('should update session successfully', () async {
      // Arrange
      final session = ShootingSession(
        weapon: 'Pistolet',
        caliber: '22LR',
        status: SessionConstants.statusPrevue,
        series: [],
      );
      await sessionService.addSession(session);

      // Act
      session.status = SessionConstants.statusRealisee;
      session.series.add(Series(distance: 10, points: 95, groupSize: 15.5, shotCount: 10));
      await sessionService.updateSession(session);

      // Assert
      final sessions = await sessionService.getAllSessions();
      expect(sessions.first.status, equals(SessionConstants.statusRealisee));
      expect(sessions.first.series, hasLength(1));
    });

    test('should delete session successfully', () async {
      // Arrange
      final session = ShootingSession(
        weapon: 'Pistolet',
        caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [],
      );
      await sessionService.addSession(session);

      // Act
      await sessionService.deleteSession(session.id!);

      // Assert
      final sessions = await sessionService.getAllSessions();
      expect(sessions, isEmpty);
    });

    test('should clear all sessions successfully', () async {
      // Arrange
      final session1 = ShootingSession(weapon: 'Pistolet', caliber: '22LR', status: SessionConstants.statusRealisee, series: []);
      final session2 = ShootingSession(weapon: 'Carabine', caliber: '22LR', status: SessionConstants.statusRealisee, series: []);
      await sessionService.addSession(session1);
      await sessionService.addSession(session2);

      // Act
      await sessionService.clearAllSessions();

      // Assert
      final sessions = await sessionService.getAllSessions();
      expect(sessions, isEmpty);
    });

    test('should handle repository errors gracefully', () async {
      // Arrange
      mockRepository.setShouldThrowError(true);

      // Act & Assert
      expect(() => sessionService.getAllSessions(), throwsException);
    });

    test('should convert planned session to realized', () async {
      // Arrange
      final plannedSession = ShootingSession(
        weapon: 'Pistolet',
        caliber: '22LR',
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 0, groupSize: 0, shotCount: 10)],
      );
      await sessionService.addSession(plannedSession);

      // Act
      final realizedSession = await sessionService.convertPlannedToRealized(
        session: plannedSession,
        weapon: 'Carabine',
        caliber: '9mm',
        forcedDate: DateTime(2025, 10, 8),
      );

      // Assert
      expect(realizedSession.status, equals(SessionConstants.statusRealisee));
      expect(realizedSession.weapon, equals('Carabine'));
      expect(realizedSession.caliber, equals('9mm'));
      expect(realizedSession.date, equals(DateTime(2025, 10, 8)));
    });

    test('should throw error when converting non-planned session', () async {
      // Arrange
      final realizedSession = ShootingSession(
        weapon: 'Pistolet',
        caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [],
      );

      // Act & Assert
      expect(
        () => sessionService.convertPlannedToRealized(session: realizedSession),
        throwsStateError,
      );
    });
  });
}