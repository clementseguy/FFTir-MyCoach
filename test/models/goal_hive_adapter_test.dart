import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/goal.dart';

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('nt_goal_hive_');
    Hive.init(dir.path);
    // Register adapters once (ignore if already registered in this isolate)
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());
  });

  tearDown(() async {
    for (final name in [
      'goal_metric_box','goal_comparator_box','goal_status_box','goal_period_box','goals_models_test'
    ]) {
      if (Hive.isBoxOpen(name)) await Hive.box(name).close();
    }
  });

  test('Enum adapters round-trip all values', () async {
    // Use unique box names to avoid clashes with concurrent tests
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final mName = 'goal_metric_box_$suffix';
    final cName = 'goal_comparator_box_$suffix';
    final sName = 'goal_status_box_$suffix';
    final pName = 'goal_period_box_$suffix';
    final mBox = await Hive.openBox<GoalMetric>(mName);
    for (final v in GoalMetric.values) {
      await mBox.put(v.index, v);
      expect(mBox.get(v.index), v);
    }
    // GoalComparator
    final cBox = await Hive.openBox<GoalComparator>(cName);
    for (final v in GoalComparator.values) {
      await cBox.put(v.index, v);
      expect(cBox.get(v.index), v);
    }
    // GoalStatus
    final sBox = await Hive.openBox<GoalStatus>(sName);
    for (final v in GoalStatus.values) {
      await sBox.put(v.index, v);
      expect(sBox.get(v.index), v);
    }
    // GoalPeriod
    final pBox = await Hive.openBox<GoalPeriod>(pName);
    for (final v in GoalPeriod.values) {
      await pBox.put(v.index, v);
      expect(pBox.get(v.index), v);
    }
    await mBox.close();
    await cBox.close();
    await sBox.close();
    await pBox.close();
  });

  test('Goal adapter round-trip with all fields set', () async {
    final gName = 'goals_models_test_${DateTime.now().microsecondsSinceEpoch}';
    final gBox = await Hive.openBox<Goal>(gName);
    final created = DateTime(2025, 1, 2, 3, 4, 5);
    final updated = DateTime(2025, 2, 3, 4, 5, 6);
    final achieved = DateTime(2025, 3, 4, 5, 6, 7);
    final g = Goal(
      id: 'gid-1',
      title: 'Titre',
      description: 'Desc',
      metric: GoalMetric.bestSessionPoints,
      comparator: GoalComparator.greaterOrEqual,
      targetValue: 123.4,
      status: GoalStatus.active,
      period: GoalPeriod.rollingMonth,
      createdAt: created,
      updatedAt: updated,
      lastProgress: 0.75,
      lastMeasuredValue: 111.1,
      priority: 5,
      achievementDate: achieved,
      previousMeasuredValue: 90.0,
      improvementDelta: 21.1,
    );
    await gBox.put('k', g);
    final out = gBox.get('k');
    expect(out, isNotNull);
    final r = out!;
    expect(r.id, 'gid-1');
    expect(r.title, 'Titre');
    expect(r.description, 'Desc');
    expect(r.metric, GoalMetric.bestSessionPoints);
    expect(r.comparator, GoalComparator.greaterOrEqual);
    expect(r.targetValue, 123.4);
    expect(r.status, GoalStatus.active);
    expect(r.period, GoalPeriod.rollingMonth);
    expect(r.createdAt, created);
    // updatedAt is set to now() by copyWith normally; here round-trip preserves field
    expect(r.updatedAt, updated);
    expect(r.lastProgress, 0.75);
    expect(r.lastMeasuredValue, 111.1);
    expect(r.priority, 5);
    expect(r.achievementDate, achieved);
    expect(r.previousMeasuredValue, 90.0);
    expect(r.improvementDelta, 21.1);
    await gBox.close();
  });
}
