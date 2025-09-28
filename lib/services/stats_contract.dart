
class RollingStatsSnapshot {
  final double avg30;
  final double avg60;
  final double delta; // avg30 - avg60
  final int sessions30;
  final int sessions60;
  const RollingStatsSnapshot({
    required this.avg30,
    required this.avg60,
    required this.delta,
    required this.sessions30,
    required this.sessions60,
  });
  bool get hasData => sessions30 > 0 || sessions60 > 0;
}

abstract class RollingStatsCalculator {
  Future<RollingStatsSnapshot> compute();
}
