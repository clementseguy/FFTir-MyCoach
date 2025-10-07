import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/utils/session_filters.dart';

void main() {
  group('SessionFilters.realizedWithDate', () {
    test('garde uniquement les sessions réalisées avec date non nulle', () {
      final s1 = ShootingSession(
        id: 1,
        date: DateTime(2025, 10, 1),
        weapon: 'P', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
      );
      final s2 = ShootingSession(
        id: 2,
        date: null,
        weapon: 'P', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 80, groupSize: 25)],
      );
      final s3 = ShootingSession(
        id: 3,
        date: DateTime(2025, 10, 2),
        weapon: 'P', caliber: '22LR',
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 100, groupSize: 10)],
      );

      final filtered = SessionFilters.realizedWithDate([s1, s2, s3]);
      expect(filtered.length, 1);
      expect(filtered.first.id, 1);
    });
  });
}
