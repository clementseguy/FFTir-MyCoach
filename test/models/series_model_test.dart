import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/series.dart';

void main() {
  group('Series model mapping & defaults', () {
    test('toMap/fromMap roundtrip preserves fields and hand_method encoding', () {
      final s = Series(id: 7, shotCount: 6, distance: 25, points: 55, groupSize: 18.5, comment: 'ok', handMethod: HandMethod.oneHand);
      final map = s.toMap();
      expect(map['hand_method'], 'one');
      final s2 = Series.fromMap(Map<String, dynamic>.from(map));
      expect(s2.id, 7);
      expect(s2.shotCount, 6);
      expect(s2.distance, 25);
      expect(s2.points, 55);
      expect(s2.groupSize, 18.5);
      expect(s2.comment, 'ok');
      expect(s2.handMethod, HandMethod.oneHand);
    });

    test('fromMap handles unknown hand_method and missing fields with safe defaults', () {
      final s = Series.fromMap({
        'id': 1,
        'distance': 10.0,
        'hand_method': 'unknown',
        // shot_count, points, group_size, comment missing
      });
      expect(s.shotCount, 5);
      expect(s.points, 0);
      expect(s.groupSize, 0);
      expect(s.comment, '');
      expect(s.handMethod, HandMethod.twoHands);
    });
  });
}
