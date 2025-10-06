import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/models/shooting_session.dart';
// import removed (not needed): series

// Fake in-memory repositories for isolation
class _MemGoalRepo implements GoalRepository {
  final List<Goal> _list = [];
  @override Future<void> delete(String id) async { _list.removeWhere((g)=> g.id==id); }
  @override Future<void> deleteAll() async { _list.clear(); }
  @override Future<List<Goal>> getAll() async => List.unmodifiable(_list);
  @override Future<void> put(Goal goal) async { _list.removeWhere((g)=> g.id==goal.id); _list.add(goal); }
}
class _MemSessionRepo implements SessionRepository {
  final List<ShootingSession> _sessions = [];
  @override Future<void> clearAll() async { _sessions.clear(); }
  @override Future<void> delete(int id) async { _sessions.removeWhere((s)=> s.id==id); }
  @override Future<List<ShootingSession>> getAll() async => List.unmodifiable(_sessions);
  @override Future<int> insert(ShootingSession session) async { final newId = (_sessions.length+1); session.id=newId; _sessions.add(session); return newId; }
  @override Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async { final idx=_sessions.indexWhere((s)=> s.id==session.id); if(idx!=-1) _sessions[idx]=session; return false; }
}

void main() {
  group('GoalService Lot A', () {
    late GoalService service;
    late _MemGoalRepo goalRepo;
    late _MemSessionRepo sessionRepo;

    setUp(() async {
      goalRepo = _MemGoalRepo();
      sessionRepo = _MemSessionRepo();
      service = GoalService(goalRepository: goalRepo, sessionRepository: sessionRepo);
    });

    Goal _g({required String id, double prog=0.0, int prio=0, GoalStatus status=GoalStatus.active, DateTime? achievedAt}) {
      return Goal(
        id: id,
        title: id,
        metric: GoalMetric.sessionCount,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 10,
        status: status,
        period: GoalPeriod.none,
        lastProgress: prog,
        lastMeasuredValue: prog*10,
        priority: prio,
        achievementDate: achievedAt,
      );
    }

    test('topActiveGoals sorts by progress desc then priority asc', () async {
      await goalRepo.put(_g(id:'g1', prog:0.5, prio:5));
      await goalRepo.put(_g(id:'g2', prog:0.7, prio:9));
      await goalRepo.put(_g(id:'g3', prog:0.7, prio:2)); // same progress lower priority wins
      await goalRepo.put(_g(id:'g4', prog:0.2, prio:1));
      final top = await service.topActiveGoals(3);
      expect(top.map((g)=>g.id).toList(), ['g3','g2','g1']);
    });

    test('topActiveGoals excludes achieved', () async {
      await goalRepo.put(_g(id:'a1', prog:0.9));
      await goalRepo.put(_g(id:'a2', prog:1.0, status: GoalStatus.achieved));
      final top = await service.topActiveGoals(5);
      expect(top.any((g)=> g.id=='a2'), false);
    });

    test('countActiveGoals & countAchievedGoals', () async {
      await goalRepo.put(_g(id:'x1', status: GoalStatus.active));
      await goalRepo.put(_g(id:'x2', status: GoalStatus.achieved));
      await goalRepo.put(_g(id:'x3', status: GoalStatus.active));
      expect(await service.countActiveGoals(), 2);
      expect(await service.countAchievedGoals(), 1);
    });

    test('achievementsWithin counts correct windows', () async {
      final now = DateTime.now();
      await goalRepo.put(_g(id:'w1', status: GoalStatus.achieved, achievedAt: now.subtract(const Duration(days:5))));
      await goalRepo.put(_g(id:'w2', status: GoalStatus.achieved, achievedAt: now.subtract(const Duration(days:20))));
      await goalRepo.put(_g(id:'w3', status: GoalStatus.achieved, achievedAt: now.subtract(const Duration(days:65))));
      expect(await service.achievementsWithin(7), 1); // only w1
      expect(await service.achievementsWithin(30), 2); // w1 + w2
      expect(await service.achievementsWithin(60), 2); // w1 + w2 (w3 outside)
      expect(await service.achievementsWithin(90), 3); // all three
    });
  });
}
