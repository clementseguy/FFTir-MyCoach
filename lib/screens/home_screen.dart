import '../widgets/rules_bottom_sheet.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import '../models/shooting_session.dart';
import '../services/stats_service.dart';
import '../services/rolling_stats_service.dart';
import '../services/stats_contract.dart';
import '../repositories/hive_session_repository.dart';
import 'package:fl_chart/fl_chart.dart';
// Scatter mode utils kept for potential future use; charts use last 30 series by requirement
// import '../models/series.dart'; // plus besoin du filtrage par prise

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService();
  late Future<List<ShootingSession>> _sessionsFuture;
  // Filtrage par prise retiré

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshSessions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSessions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _sessionsFuture = _sessionService.getAllSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // F01 Onglets Synthèse / Avancé
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/app_logo.png', height: 36),
              const SizedBox(width: 12),
              const Text('Tableau de bord'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Règles & fondamentaux',
              onPressed: () => RulesBottomSheet.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: _refreshSessions,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Synthèse'), // F01
              Tab(text: 'Avancé'),   // F01
            ],
          ),
        ),
        body: FutureBuilder<List<ShootingSession>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allSessions = (snapshot.data ?? [])
                .where((s) => s.status == SessionConstants.statusRealisee && s.date != null)
                .toList();
            if (allSessions.isEmpty) {
              return const Center(child: Text('Aucune donnée pour les graphes.'));
            }

            // Services & calculs communs (mutualisé pour les deux onglets)
            final stats = StatsService(allSessions); // F02/F03/F04
            final rollingService = RollingStatsService(HiveSessionRepository()); // F08 (affiché avancé)

            // KPI & metrics de base (Synthèse)
            final avgPoints30 = stats.averagePointsLast30Days(); // F02
            final avgGroup30 = stats.averageGroupSizeLast30Days(); // F02
            final best = stats.bestSeriesByPoints(); // F02
            final sessionsMonth = stats.sessionsCountCurrentMonth(); // F02

            // Avancé metrics
            final consistency = stats.consistencyIndexLast30Days(); // F07
            final progression = stats.progressionPercent30Days(); // F07
            final distDistrib = stats.distanceDistribution(); // F11 (30j)
            final mostPlayedDistance = distDistrib.isEmpty ? null : distDistrib.entries.reduce((a,b)=> a.value>=b.value? a : b); // F07
            final catDistrib = stats.categoryDistribution(); // F05 (Synthèse)
            final pointBuckets = stats.pointBuckets(); // F06
            final streak = stats.currentDayStreak(); // F09
            final recordPoints = stats.lastSeriesIsRecordPoints(); // F25
            final recordGroup = stats.lastSeriesIsRecordGroup(); // F25
            final loadDelta = stats.weeklyLoadDelta(); // F09
            final currentWeek = stats.sessionsThisWeek(); // F09
            final bestGroup = stats.bestGroupSize(); // F26

            // Séries: afficher les 30 dernières séries en ordre chrono ASC (ancien -> récent)
            final last30 = stats.lastNSortedSeriesAsc(30);
            final List<DateTime> dates = [];
            final List<FlSpot> pointsSpots = [];
            final List<FlSpot> groupSizeSpots = [];
            for (int i = 0; i < last30.length; i++) {
              final s = last30[i];
              dates.add(s.date);
              pointsSpots.add(FlSpot(i.toDouble(), s.points.toDouble()));
              groupSizeSpots.add(FlSpot(i.toDouble(), s.groupSize.toDouble()));
            }

            // Préparation 1 main / 2 mains: reconstruire un flatten avec handMethod, prendre dernières 30 séries, puis filtrer
            final List<Map<String, dynamic>> allSeriesFlatHand = [];
            final sessionsAsc = List<ShootingSession>.from(allSessions)
              ..sort((a, b) => (a.date ?? DateTime(1970)).compareTo(b.date ?? DateTime(1970)));
            for (final session in sessionsAsc) {
              final d = session.date ?? DateTime(1970);
              for (final serie in session.series) {
                allSeriesFlatHand.add({
                  'date': d,
                  'points': serie.points.toDouble(),
                  'group': serie.groupSize.toDouble(),
                  'hand': serie.handMethod.name, // 'oneHand' | 'twoHands'
                });
              }
            }
            allSeriesFlatHand.sort((a,b)=> (a['date'] as DateTime).compareTo(b['date'] as DateTime));
            final int nH = allSeriesFlatHand.length;
            final int startH = nH > 30 ? nH - 30 : 0;
            final last30Flat = allSeriesFlatHand.sublist(startH, nH);
            final oneHand = last30Flat.where((e)=> e['hand'] == 'oneHand').toList();
            final twoHands = last30Flat.where((e)=> e['hand'] == 'twoHands').toList();

            List<DateTime> _datesFrom(List<Map<String,dynamic>> list) => List.generate(list.length, (i)=> list[i]['date'] as DateTime);
            List<FlSpot> _pointsFrom(List<Map<String,dynamic>> list) => List.generate(list.length, (i)=> FlSpot(i.toDouble(), (list[i]['points'] as double)));
            List<FlSpot> _groupsFrom(List<Map<String,dynamic>> list) => List.generate(list.length, (i)=> FlSpot(i.toDouble(), (list[i]['group'] as double)));

            final dates1 = _datesFrom(oneHand);
            final pts1 = _pointsFrom(oneHand);
            final grp1 = _groupsFrom(oneHand);
            final dates2 = _datesFrom(twoHands);
            final pts2 = _pointsFrom(twoHands);
            final grp2 = _groupsFrom(twoHands);
            final moving = stats.movingAveragePoints(window: 3); // F03 tendance
            final List<FlSpot> trendSpots = [];
            if (pointsSpots.isNotEmpty && moving.isNotEmpty) {
              final take = pointsSpots.length;
              final start = (moving.length - take) < 0 ? 0 : (moving.length - take);
              for (int i = 0; i < take && (start + i) < moving.length; i++) {
                trendSpots.add(FlSpot(pointsSpots[i].x, moving[start + i]));
              }
            }

            final rollingFuture = rollingService.compute(); // F08 async

            // BUILDERS ========================================================
            Widget kpiGrid() {
              Widget kpiCard(String title, String value, {IconData icon = Icons.insights}) => _KpiCard(title: title, value: value, icon: icon);
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.9,
                ),
                children: [
                  kpiCard('Moy. points 30j', avgPoints30.toStringAsFixed(1), icon: Icons.star_rate),
                  kpiCard('Groupement moy 30j', '${avgGroup30.toStringAsFixed(1)} cm', icon: Icons.blur_circular),
                  kpiCard('Best série', best != null ? '${best.points} pts' : '-', icon: Icons.emoji_events),
                  kpiCard('Sessions ce mois', sessionsMonth.toString(), icon: Icons.calendar_month),
                ],
              );
            }

            Widget syntheseTab() {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    kpiGrid(), // F02
                    const SizedBox(height: 20),
                    // F03 Évolution points + SMA3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Évolution points par série'),
                        SizedBox(width: 8),
                        Icon(Icons.trending_up, size: 16, color: Colors.amberAccent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PointsLineChart(dates: dates, pointsSpots: pointsSpots, trendSpots: trendSpots),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendDot(color: Colors.amberAccent, label: 'Points'),
                        SizedBox(width: 16),
                        _LegendDot(color: Colors.lightBlueAccent, label: 'Tendance (SMA3)'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // F04 Évolution groupement
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Évolution groupement (cm)'),
                        SizedBox(width: 8),
                        Icon(Icons.center_focus_strong, size: 16, color: Colors.lightGreenAccent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GroupementLineChart(dates: dates, groupSizeSpots: groupSizeSpots),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _LegendDot(color: Colors.lightGreenAccent, label: 'Groupement'),
                        SizedBox(width: 16),
                        _LegendDot(color: Colors.deepOrangeAccent, label: 'Record (min)'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // F05 Répartition catégories (sessions)
                    if (catDistrib.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Répartition catégories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _CategoryStackedBar(distribution: catDistrib),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: _CategoryStackedBar.legend(catDistrib),
                      ),
                      const SizedBox(height: 32),
                    ],
                    // F06 Distribution points 30j
                    if (pointBuckets.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Distribution points (30j)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _BucketsChart(pointBuckets: pointBuckets),
                      const SizedBox(height: 24),
                    ],
                    
                    // Répartition distances 30j
                    if (distDistrib.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Répartition distances (30j)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _DistanceChart(distDistrib: distDistrib),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              );
            }

            Widget avanceTab() {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // F07 Analyse avancée
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Analyse avancée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MiniStatChip(
                          label: 'Consistency',
                          value: (consistency == 0) ? '-' : '${consistency.toStringAsFixed(0)}%',
                          color: consistency == 0 ? Colors.grey : (consistency >= 70 ? Colors.greenAccent : (consistency >= 40 ? Colors.orangeAccent : Colors.redAccent)),
                        ),
                        _MiniStatChip(
                          label: 'Progression',
                          value: progression.isNaN ? '-' : '${progression >= 0 ? '+' : ''}${progression.toStringAsFixed(1)}%',
                          color: progression.isNaN ? Colors.grey : (progression >= 0 ? Colors.lightBlueAccent : Colors.deepOrangeAccent),
                        ),
                        _MiniStatChip(
                          label: 'Distance fréquente',
                          value: mostPlayedDistance == null ? '-' : '${mostPlayedDistance.key.toStringAsFixed(0)}m (${mostPlayedDistance.value})',
                          color: Colors.purpleAccent,
                        ),
                        _MiniStatChip(
                          label: 'Catégorie dominante',
                          value: catDistrib.isEmpty ? '-' : catDistrib.entries.reduce((a,b)=> a.value>=b.value? a:b).key,
                          color: Colors.tealAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // F08 Rolling card (déplacé ici)
                    FutureBuilder<RollingStatsSnapshot>(
                      future: rollingFuture,
                      builder: (context, snap) {
                        final r = snap.data;
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (r == null) return const SizedBox.shrink();
                        Color deltaColor;
                        if (r.delta > 1) {
                          deltaColor = Colors.greenAccent;
                        } else if (r.delta < -1) {
                          deltaColor = Colors.redAccent;
                        } else {
                          deltaColor = Colors.white70;
                        }
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timeline, color: Colors.amberAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Rolling (30j vs 60j)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 18,
                                      runSpacing: 8,
                                      children: [
                                        _MiniStatChip(label: 'Avg30', value: r.avg30.toStringAsFixed(1), color: Colors.amberAccent),
                                        _MiniStatChip(label: 'Avg60', value: r.avg60.toStringAsFixed(1), color: Colors.lightBlueAccent),
                                        _MiniStatChip(label: 'Δ', value: (r.delta >= 0 ? '+' : '') + r.delta.toStringAsFixed(1), color: deltaColor),
                                        _MiniStatChip(label: 'Sessions30', value: r.sessions30.toString(), color: Colors.tealAccent),
                                        _MiniStatChip(label: 'Sessions60', value: r.sessions60.toString(), color: Colors.pinkAccent),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // F09 / F25 / F26 Badges performance
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _PerfBadge(icon: Icons.local_fire_department, color: Colors.indigoAccent, label: 'Streak', value: streak <=1 ? '1 jour' : '${streak}j'),
                        _PerfBadge(icon: Icons.fitness_center, color: loadDelta >=0 ? Colors.cyanAccent : Colors.deepOrangeAccent, label: 'Charge', value: '${currentWeek} (${loadDelta>=0?'+':''}${loadDelta})'),
                        if (recordPoints) _PerfBadge(icon: Icons.star, color: Colors.amber, label: 'Record', value: 'Points'),
                        if (recordGroup) _PerfBadge(icon: Icons.adjust, color: Colors.greenAccent, label: 'Record', value: 'Groupement'),
                        if (bestGroup > 0) _PerfBadge(icon: Icons.center_focus_strong, color: Colors.lightGreenAccent, label: 'Best grp', value: '${bestGroup.toStringAsFixed(1)}cm'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // (1M/2M charts moved to bottom as requested)
                    // F10 Scatter (corrélation) - dernières 30 séries
                    if (last30.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Corrélation Points / Groupement'),
                          SizedBox(width: 8),
                          Icon(Icons.scatter_plot, size: 16, color: Colors.orangeAccent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: ScatterChart(
                          ScatterChartData(
                            gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: true, horizontalInterval: 5, verticalInterval: 5),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: () {
                              final maxG = last30.isEmpty ? 0.0 : last30.map((e)=> e.groupSize.toDouble()).reduce((a,b)=> b>a? b:a);
                              final v = maxG + 5.0;
                              return (v > 10.0 ? v : 10.0).toDouble();
                            }(),
                            minY: 0,
                            maxY: 55,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            scatterSpots: List.generate(last30.length, (i) => ScatterSpot(
                              last30[i].groupSize.toDouble(),
                              last30[i].points.toDouble(),
                            )),
                            scatterTouchData: ScatterTouchData(enabled: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    // F11 (Répartition distances déplacé vers l'onglet Synthèse)
                    const SizedBox(height: 8),
                    // 1M / 2M Combined charts at the bottom (30 dernières séries)
                    if (oneHand.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('1 main - Points et Groupement'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _PointsAndGroupCombinedChart(dates: dates1, points: pts1, groups: grp1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _LegendDot(color: Colors.amberAccent, label: 'Points'),
                          SizedBox(width: 16),
                          _LegendDot(color: Colors.lightGreenAccent, label: 'Groupement'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (twoHands.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('2 mains - Points et Groupement'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _PointsAndGroupCombinedChart(dates: dates2, points: pts2, groups: grp2),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _LegendDot(color: Colors.amberAccent, label: 'Points'),
                          SizedBox(width: 16),
                          _LegendDot(color: Colors.lightGreenAccent, label: 'Groupement'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                syntheseTab(),
                avanceTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// (helpers moved to utils/scatter_utils.dart)

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _KpiCard({required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
  color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ===== Helper widgets ajoutés Lot A (extraction logique existante) =====

class _PointsLineChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<FlSpot> pointsSpots;
  final List<FlSpot> trendSpots;
  const _PointsLineChart({required this.dates, required this.pointsSpots, required this.trendSpots});
  @override
  Widget build(BuildContext context) {
    final maxPoints = pointsSpots.isNotEmpty
        ? pointsSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 10;
    final minPoints = pointsSpots.isNotEmpty
        ? pointsSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b)
        : 0;
    double niceCeil(double v) => (v / 5.0).ceil() * 5.0;
    double niceFloor(double v) => (v / 5.0).floor() * 5.0;
    final minY = niceFloor(minPoints - 1 < 0 ? 0 : minPoints - 1);
    final combinedMax = [
      maxPoints,
      if (trendSpots.isNotEmpty) trendSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
    ].reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = niceCeil(combinedMax + 1);
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value % 5 != 0) return const SizedBox.shrink();
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 11, color: Colors.white70));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (value % 1 != 0 || i < 0 || i >= dates.length) return const SizedBox.shrink();
                  final d = dates[i];
                  return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 11, color: Colors.white70));
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: pointsSpots.isNotEmpty ? pointsSpots.length - 1.0 : 1.0,
          minY: minY,
          maxY: adjustedMaxY,
          clipData: FlClipData.all(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((barSpot) {
                final i = barSpot.x.toInt();
                final d = (i >= 0 && i < dates.length) ? dates[i] : DateTime.now();
                return LineTooltipItem(
                  '${d.day}/${d.month}\n${barSpot.barIndex == 0 ? 'Points' : 'Tendance'}: ${barSpot.y.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
          extraLinesData: const ExtraLinesData(horizontalLines: []),
          lineBarsData: [
            LineChartBarData(
              spots: pointsSpots,
              isCurved: true,
              color: Colors.amberAccent,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.amberAccent.withOpacity(0.35),
                    Colors.amberAccent.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (trendSpots.length >= 3)
              LineChartBarData(
                spots: trendSpots,
                isCurved: true,
                color: Colors.lightBlueAccent,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupementLineChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<FlSpot> groupSizeSpots;
  const _GroupementLineChart({required this.dates, required this.groupSizeSpots});
  @override
  Widget build(BuildContext context) {
    if (groupSizeSpots.isEmpty) return const SizedBox.shrink();
    final maxGroup = groupSizeSpots.map((e) => e.y).reduce((a,b)=> a>b?a:b);
    double niceCeil(double v) => (v/5).ceil()*5.0;
    final maxY = niceCeil(maxGroup + 1);
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    if (value % 5 != 0) return const SizedBox.shrink();
                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 11, color: Colors.white70));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (value % 1 != 0 || i < 0 || i >= dates.length) return const SizedBox.shrink();
                    final d = dates[i];
                    return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 11, color: Colors.white70));
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: groupSizeSpots.length - 1.0,
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) => touchedSpots.map((barSpot) {
                  final i = barSpot.x.toInt();
                  final d = (i >= 0 && i < dates.length) ? dates[i] : DateTime.now();
                  return LineTooltipItem('${d.day}/${d.month}\nGroupement: ${barSpot.y.toStringAsFixed(1)} cm', const TextStyle(color: Colors.white, fontSize: 12));
                }).toList(),
              ),
            ),
            clipData: FlClipData.all(),
            lineBarsData: [
              LineChartBarData(
                spots: groupSizeSpots,
                isCurved: true,
                color: Colors.lightGreenAccent,
                barWidth: 3,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.lightGreenAccent.withOpacity(0.30),
                      Colors.lightGreenAccent.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }
}

class _BucketsChart extends StatelessWidget {
  final List<dynamic> pointBuckets; // list of _PointBucket (private type) so keep dynamic
  const _BucketsChart({required this.pointBuckets});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= pointBuckets.length) return const SizedBox.shrink();
                  final b = pointBuckets[idx];
                  return Text('${b.start}-${b.end}', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          barGroups: List.generate(pointBuckets.length, (i) {
            final b = pointBuckets[i];
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: b.count.toDouble(),
                color: Colors.orangeAccent,
                width: 14,
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent,
                    Colors.orangeAccent.withOpacity(0.15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            ]);
          }),
        ),
      ),
    );
  }
}

class _DistanceChart extends StatelessWidget {
  final Map<double,int> distDistrib;
  const _DistanceChart({required this.distDistrib});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final keys = distDistrib.keys.toList()..sort();
                  final idx = value.toInt();
                  if (idx < 0 || idx >= keys.length) return const SizedBox.shrink();
                  return Text('${keys[idx].toStringAsFixed(0)}m', style: const TextStyle(fontSize: 11));
                },
              ),
            ),
          ),
          barGroups: () {
            final keys = distDistrib.keys.toList()..sort();
            return List.generate(keys.length, (i) {
              final k = keys[i];
              final v = distDistrib[k]!.toDouble();
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: v,
                    color: Colors.purpleAccent,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.purpleAccent,
                        Colors.purpleAccent.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
              );
            });
          }(),
        ),
      ),
    );
  }
}

class _PerfBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _PerfBadge({required this.icon, required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
  color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
          SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
            SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryStackedBar extends StatelessWidget {
  final Map<String,int> distribution;
  const _CategoryStackedBar({required this.distribution});

  static const List<Color> _palette = [
    Colors.amberAccent,
    Colors.lightBlueAccent,
    Colors.lightGreenAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
  ];

  static List<Widget> legend(Map<String,int> distribution) {
    int ci = 0;
    final total = distribution.values.fold<int>(0,(a,b)=> a+b).toDouble();
    return distribution.entries.map((e){
      final color = _palette[ci++ % _palette.length];
      final pct = total==0?0:(e.value/total*100);
      return _LegendDot(color: color, label: '${e.key} (${pct.toStringAsFixed(0)}%)');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold<int>(0,(a,b)=> a+b).toDouble();
    if (total == 0) {
      return Container(
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('-', style: TextStyle(color: Colors.white54)),
      );
    }
    int ci = 0;
    final segments = distribution.entries.map((e){
      final color = _palette[ci++ % _palette.length];
      final pct = e.value / total;
      return _CategorySegment(
        flex: (pct * 1000).round().clamp(1, 1000),
        color: color,
        label: pct>=0.12 ? '${(pct*100).toStringAsFixed(0)}%' : null,
      );
    }).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(children: segments),
        );
      },
    );
  }
}

class _CategorySegment extends StatelessWidget {
  final int flex;
  final Color color;
  final String? label;
  const _CategorySegment({required this.flex, required this.color, this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
  color: color.withOpacity(0.85),
        child: label == null ? null : Center(
          child: Text(
            label!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              shadows: [Shadow(color: Colors.white54, blurRadius: 2)],
            ),
          ),
        ),
      ),
    );
  }
}

// Bucket temporaire pour affichage filtré (évite d'exposer la classe privée de StatsService)

class _PointsAndGroupCombinedChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<FlSpot> points;
  final List<FlSpot> groups;
  const _PointsAndGroupCombinedChart({required this.dates, required this.points, required this.groups});
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty && groups.isEmpty) return const SizedBox.shrink();
    final maxPoints = points.isNotEmpty ? points.map((e)=> e.y).reduce((a,b)=> a>b?a:b) : 10;
    final maxGroup = groups.isNotEmpty ? groups.map((e)=> e.y).reduce((a,b)=> a>b?a:b) : 10;
    // Scale group to roughly overlap points range for a simple combined view
    final scale = (maxGroup <= 0) ? 1.0 : (maxPoints / maxGroup);
    final scaledGroups = groups.map((e)=> FlSpot(e.x, e.y * scale)).toList();
    final maxY = [
      if (points.isNotEmpty) maxPoints.toDouble(),
      if (scaledGroups.isNotEmpty) scaledGroups.map((e)=> e.y).reduce((a,b)=> a>b?a:b),
    ].fold<double>(10.0, (a,b)=> a>b?a:b);
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5, getDrawingHorizontalLine: (v)=> FlLine(color: Colors.white10, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (value % 1 != 0 || i < 0 || i >= dates.length) return const SizedBox.shrink();
                  final d = dates[i];
                  return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 11, color: Colors.white70));
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.isNotEmpty ? points.length - 1.0 : (groups.isNotEmpty ? groups.length - 1.0 : 1.0)),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              color: Colors.amberAccent,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: scaledGroups,
              isCurved: true,
              color: Colors.lightGreenAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
