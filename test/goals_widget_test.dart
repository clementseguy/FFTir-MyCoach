import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:tir_sportif/widgets/goals_at_glance_card.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/models/shooting_session.dart';

class _StubGoalRepo implements GoalRepository {
  final List<Goal> _store;
  _StubGoalRepo(this._store);
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<Goal>> getAll() async => _store;
  @override
  Future<void> put(Goal goal) async {}
}

class _StubSessionRepo implements SessionRepository {
  final List<ShootingSession> _sessions;
  _StubSessionRepo([List<ShootingSession>? sessions]) : _sessions = sessions ?? const [];
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<ShootingSession>> getAll() async => _sessions;
  @override
  Future<int> insert(ShootingSession session) async => 1;
  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Minimal Hive setup for Goal adapters used by GoalService (copyWith etc.).
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());
  });

  testWidgets('GoalsAtGlanceCard renders Objectifs and counters with stub service', (tester) async {
    final goals = <Goal>[
      Goal(title: 'Paliers', metric: GoalMetric.sessionCount, comparator: GoalComparator.greaterOrEqual, targetValue: 10, status: GoalStatus.active),
      Goal(title: '100 points', metric: GoalMetric.totalPoints, comparator: GoalComparator.greaterOrEqual, targetValue: 100, status: GoalStatus.achieved),
    ];
  final service = GoalService(goalRepository: _StubGoalRepo(goals), sessionRepository: _StubSessionRepo());

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GoalsAtGlanceCard(service: service),
      ),
    ));

    // Laisse le microtask run (init + load)
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));

    // Vérifie en-tête et libellés
    expect(find.text('Objectifs'), findsWidgets);
    // Compteurs présents (même si valeurs exactes dépendent de compute)
    expect(find.textContaining('En cours'), findsWidgets);
    expect(find.textContaining('Réalisés'), findsWidgets);
  });
}
