import '../widgets/session_card.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import '../models/shooting_session.dart';
import '../services/stats_service.dart';
// import '../models/series.dart';
import 'package:fl_chart/fl_chart.dart';
import 'session_detail_screen.dart';
// import 'create_session_screen.dart';
// import 'sessions_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService();
  late Future<List<ShootingSession>> _sessionsFuture;

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              height: 36,
            ),
            const SizedBox(width: 12),
            const Text('Accueil'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _refreshSessions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mes Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              FutureBuilder<List<ShootingSession>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final allSessions = (snapshot.data ?? [])
                      .where((s) => s.status == SessionConstants.statusRealisee && s.date != null)
                      .toList();
                  if (allSessions.isEmpty) {
                    return Center(child: Text('Aucune donnée pour les graphes.'));
                  }
                  // Stats service
                  final stats = StatsService(allSessions);
                  final avgPoints30 = stats.averagePointsLast30Days();
                  final avgGroup30 = stats.averageGroupSizeLast30Days();
                  final best = stats.bestSeriesByPoints();
                  final sessionsMonth = stats.sessionsCountCurrentMonth();
                  final consistency = stats.consistencyIndexLast30Days();
                  final progression = stats.progressionPercent30Days();
                  final distDistrib = stats.distanceDistribution();
                  final mostPlayedDistance = distDistrib.isEmpty ? null : distDistrib.entries.reduce((a,b)=> a.value>=b.value? a : b);
                  final catDistrib = stats.categoryDistribution();
                  final pointBuckets = stats.pointBuckets();

                  // Bandeau KPI (Grid 2x2)
                  Widget kpiCard(String title, String value, {IconData icon = Icons.insights}) => _KpiCard(title: title, value: value, icon: icon);

                  final kpiGrid = GridView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.9,
                    ),
                    children: [
                      kpiCard('Moy. points 30j', avgPoints30.toStringAsFixed(1), icon: Icons.star_rate),
                      kpiCard('Groupement moy 30j', avgGroup30.toStringAsFixed(1) + ' cm', icon: Icons.blur_circular),
                      kpiCard('Best série', best != null ? '${best.points} pts' : '-', icon: Icons.emoji_events),
                      kpiCard('Sessions ce mois', sessionsMonth.toString(), icon: Icons.calendar_month),
                    ],
                  );
                  final List<DateTime> dates = [];
                  final List<FlSpot> pointsSpots = [];
                  final List<FlSpot> groupSizeSpots = [];
                  final List<ShootingSession> sortedSessions = List<ShootingSession>.from(allSessions);
                  sortedSessions.sort((a, b) {
                    final dateA = a.date ?? DateTime.now();
                    final dateB = b.date ?? DateTime.now();
                    return dateB.compareTo(dateA);
                  });
                  final List<ShootingSession> lastSessions = sortedSessions.take(10).toList();
                  final List<Map<String, dynamic>> allSeries = [];
                  for (final session in lastSessions) {
                    final sessionDate = session.date ?? DateTime.now();
                    for (final serie in session.series) {
                      allSeries.add({
                        'date': sessionDate,
                        'points': (serie.points).toDouble(),
                        'group_size': (serie.groupSize).toDouble(),
                      });
                    }
                  }
                  allSeries.sort((a, b) => a['date'].compareTo(b['date']));
                  final List<Map<String, dynamic>> lastSeries = allSeries.length > 10
                      ? allSeries.sublist(allSeries.length - 10)
                      : allSeries;
                  for (int i = 0; i < lastSeries.length; i++) {
                    final serie = lastSeries[i];
                    dates.add(serie['date']);
                    pointsSpots.add(FlSpot(i.toDouble(), serie['points']));
                    groupSizeSpots.add(FlSpot(i.toDouble(), serie['group_size']));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI banner
                      kpiGrid,
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Évolution points par série', textAlign: TextAlign.center),
                          SizedBox(width: 8),
                          Icon(Icons.trending_up, size: 16, color: Colors.amberAccent),
                        ],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: Builder(builder: (context) {
                          // Trend line (SMA 3)
                          final statsAll = StatsService(allSessions);
                          final moving = statsAll.movingAveragePoints(window: 3);
                          final List<FlSpot> trendSpots = [];
                          for (int i = 0; i < moving.length && i < pointsSpots.length; i++) {
                            trendSpots.add(FlSpot(pointsSpots[i].x, moving[i]));
                          }
                          final maxPoints = pointsSpots.isNotEmpty
                              ? pointsSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
                              : 10;
                          final minPoints = pointsSpots.isNotEmpty
                              ? pointsSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b)
                              : 0;
                          double niceCeil(double v) {
                            return (v / 5.0).ceil() * 5.0;
                          }
                          double niceFloor(double v) {
                            return (v / 5.0).floor() * 5.0;
                          }
                          // Ancien maxY remplacé par adjustedMaxY (voir plus bas)
                          final minY = niceFloor(minPoints - 1 < 0 ? 0 : minPoints - 1);
                          // Inclure valeurs trend dans maxY éventuel
                          final combinedMax = [
                            maxPoints,
                            if (trendSpots.isNotEmpty) trendSpots.map((e)=> e.y).reduce((a,b)=> a>b?a:b)
                          ].reduce((a,b)=> a>b?a:b);
                          final adjustedMaxY = niceCeil(combinedMax + 1);
                          return LineChart(
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
                                      if (value % 5 != 0) return SizedBox.shrink();
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(fontSize: 11, color: Colors.white70),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final i = value.toInt();
                                      if (value % 1 != 0 || i < 0 || i >= dates.length) return SizedBox.shrink();
                                      final d = dates[i];
                                      return Text(
                                        '${d.day}/${d.month}',
                                        style: TextStyle(fontSize: 11, color: Colors.white70),
                                      );
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
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((barSpot) {
                                      final i = barSpot.x.toInt();
                                      final d = (i >= 0 && i < dates.length) ? dates[i] : DateTime.now();
                                      return LineTooltipItem(
                                        '${d.day}/${d.month}\n${barSpot.barIndex == 0 ? 'Points' : 'Tendance'}: ${barSpot.y.toStringAsFixed(1)}',
                                        const TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: pointsSpots,
                                  isCurved: true,
                                  color: Colors.amberAccent,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
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
                          );
                        }),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: Colors.amberAccent, label: 'Points'),
                          SizedBox(width: 16),
                          _LegendDot(color: Colors.lightBlueAccent, label: 'Tendance (SMA3)'),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Analyse avancée (KPIs supplémentaires)
                      Text('Analyse avancée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
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
                      SizedBox(height: 32),
                      // Graphiques complémentaires
                      if (distDistrib.isNotEmpty) ...[
                        Text('Répartition distances (30j)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        SizedBox(
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
                                      if (idx < 0 || idx >= keys.length) return SizedBox.shrink();
                                      return Text('${keys[idx].toStringAsFixed(0)}m', style: TextStyle(fontSize: 11));
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
                        ),
                        SizedBox(height: 28),
                      ],
                      if (catDistrib.isNotEmpty) ...[
                        Text('Répartition catégories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                              sections: () {
                                final total = catDistrib.values.fold<int>(0, (a,b)=> a+b).toDouble();
                                final colors = [
                                  Colors.amberAccent,
                                  Colors.lightBlueAccent,
                                  Colors.lightGreenAccent,
                                  Colors.pinkAccent,
                                  Colors.tealAccent,
                                ];
                                int ci = 0;
                                return catDistrib.entries.map((e) {
                                  final pct = total == 0 ? 0 : (e.value / total) * 100;
                                  final section = PieChartSectionData(
                                    value: e.value.toDouble(),
                                    color: colors[ci % colors.length],
                                    title: pct < 8 ? '' : '${pct.toStringAsFixed(0)}%',
                                    radius: 60,
                                    titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                  );
                                  ci++;
                                  return section;
                                }).toList();
                              }(),
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: () {
                            final colors = [
                              Colors.amberAccent,
                              Colors.lightBlueAccent,
                              Colors.lightGreenAccent,
                              Colors.pinkAccent,
                              Colors.tealAccent,
                            ];
                            int ci = 0;
                            return catDistrib.entries.map((e){
                              final color = colors[ci++ % colors.length];
                              return _LegendDot(color: color, label: '${e.key} (${e.value})');
                            }).toList();
                          }(),
                        ),
                        SizedBox(height: 28),
                      ],
                      if (pointBuckets.isNotEmpty) ...[
                        Text('Distribution points (30j)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        SizedBox(
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
                                      if (idx < 0 || idx >= pointBuckets.length) return SizedBox.shrink();
                                      final b = pointBuckets[idx];
                                      return Text('${b.start}-${b.end}', style: TextStyle(fontSize: 10));
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
                        ),
                        SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Évolution groupement (cm)', textAlign: TextAlign.center),
                          SizedBox(width: 8),
                          Icon(Icons.center_focus_strong, size: 16, color: Colors.lightGreenAccent),
                        ],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: Builder(builder: (context) {
                          if (groupSizeSpots.isEmpty) return SizedBox.shrink();
                          final maxGroup = groupSizeSpots.map((e) => e.y).reduce((a,b)=> a>b?a:b);
                          final minGroup = groupSizeSpots.map((e) => e.y).reduce((a,b)=> a<b?a:b);
                          double niceCeil(double v) => (v/5).ceil()*5.0;
                          final maxY = niceCeil(maxGroup + 1);
                          final minIndex = groupSizeSpots.indexWhere((e)=> e.y == minGroup);
                          return LineChart(
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
                                      if (value % 5 != 0) return SizedBox.shrink();
                                      return Text(value.toInt().toString(), style: TextStyle(fontSize: 11, color: Colors.white70));
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) {
                                      final i = value.toInt();
                                      if (value % 1 != 0 || i < 0 || i >= dates.length) return SizedBox.shrink();
                                      final d = dates[i];
                                      return Text('${d.day}/${d.month}', style: TextStyle(fontSize: 11, color: Colors.white70));
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
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((barSpot) {
                                      final i = barSpot.x.toInt();
                                      final d = (i >= 0 && i < dates.length) ? dates[i] : DateTime.now();
                                      return LineTooltipItem(
                                        '${d.day}/${d.month}\nGroupement: ${barSpot.y.toStringAsFixed(1)} cm',
                                        const TextStyle(color: Colors.white, fontSize: 12),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              clipData: FlClipData.all(),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: groupSizeSpots,
                                  isCurved: true,
                                  color: Colors.lightGreenAccent,
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar, index) {
                                      final isRecord = index == minIndex;
                                      return FlDotCirclePainter(
                                        radius: isRecord ? 5 : 3.5,
                                        color: isRecord ? Colors.deepOrangeAccent : Colors.lightGreenAccent,
                                        strokeColor: Colors.black,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
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
                          );
                        }),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(color: Colors.lightGreenAccent, label: 'Groupement'),
                          SizedBox(width: 16),
                          _LegendDot(color: Colors.deepOrangeAccent, label: 'Record (min)'),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 24),
              Text('Mes dernières sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FutureBuilder<List<ShootingSession>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final sessions = (snapshot.data ?? [])
                      .where((s) => s.status == 'réalisée' && s.date != null)
                      .toList();
                  if (sessions.isEmpty) {
                    return Center(child: Text('Aucune session enregistrée.'));
                  }
                  final List<ShootingSession> sortedSessions = List<ShootingSession>.from(sessions);
                  sortedSessions.sort((a, b) {
                    final dateA = a.date ?? DateTime.now();
                    final dateB = b.date ?? DateTime.now();
                    return dateB.compareTo(dateA);
                  });
                  final List<ShootingSession> last3 = sortedSessions.take(3).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: last3.length,
                    itemBuilder: (context, index) {
                      final session = last3[index];
                      return SessionCard(
                        session: session.toMap(),
                        series: session.series.map((s) => s.toMap()).toList(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(sessionData: {
                                'session': session.toMap(),
                                'series': session.series.map((s) => s.toMap()).toList(),
                              }),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        color: Colors.white.withOpacity(0.05),
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
