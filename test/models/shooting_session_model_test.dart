import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';

void main() {
  group('ShootingSession model mapping & flags', () {
    test('toMap/fromMap roundtrip with series and fields', () {
      final ss = ShootingSession(
        id: 12,
        date: DateTime(2025, 10, 7, 12, 0, 0),
        weapon: 'P',
        caliber: '22LR',
        status: 'réalisée',
        analyse: 'A',
        synthese: 'S',
        category: 'match',
        series: [Series(distance: 10, points: 50, groupSize: 20)],
        exercises: ['ex1'],
      );
      final map = ss.toMap();
      final ss2 = ShootingSession.fromMap(Map<String, dynamic>.from(map));
      expect(ss2.id, 12);
      expect(ss2.weapon, 'P');
      expect(ss2.caliber, '22LR');
      expect(ss2.status, 'réalisée');
      expect(ss2.category, 'match');
      expect(ss2.series.length, 1);
      expect(ss2.series.first.points, 50);
      expect(ss2.exercises, ['ex1']);
      expect(ss2.hasAnalysis, isTrue);
      expect(ss2.hasSynthese, isTrue);
    });

    test('fromMap tolerates missing/empty series and exercises', () {
      final ss = ShootingSession.fromMap({
        'weapon': 'C', 'caliber': '9mm',
      });
      expect(ss.series, isEmpty);
      expect(ss.exercises, isEmpty);
      expect(ss.status, 'réalisée');
      expect(ss.category, 'entraînement');
      expect(ss.hasAnalysis, isFalse);
      expect(ss.hasSynthese, isFalse);
    });
  });
}
