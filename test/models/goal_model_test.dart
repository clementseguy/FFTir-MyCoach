import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/goal.dart';

void main() {
  group('Goal model defaults and copyWith', () {
    test('defaults: id generated, dates set, priority defaulted', () {
      final g = Goal(
        title: 'T',
        metric: GoalMetric.totalPoints,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 100,
      );
      expect(g.id, isNotEmpty);
      expect(g.createdAt, isNotNull);
      expect(g.updatedAt, isNotNull);
      expect(g.priority, 9999);
      expect(g.status, GoalStatus.active);
      expect(g.period, GoalPeriod.none);
    });

    test('copyWith updates fields and preserves others', () {
      final g = Goal(
        title: 'Initial',
        metric: GoalMetric.averagePoints,
        comparator: GoalComparator.lessOrEqual,
        targetValue: 20,
        lastProgress: 0.5,
        lastMeasuredValue: 10,
        priority: 3,
      );
      final g2 = g.copyWith(
        title: 'New',
        targetValue: 30,
        lastProgress: 0.8,
        previousMeasuredValue: 12,
      );
      expect(g2.title, 'New');
      expect(g2.targetValue, 30);
      expect(g2.lastProgress, 0.8);
      expect(g2.previousMeasuredValue, 12);
      expect(g2.metric, GoalMetric.averagePoints);
      expect(g2.comparator, GoalComparator.lessOrEqual);
      expect(g2.priority, 3);
      expect(g2.id, g.id);
    });
  });
}
