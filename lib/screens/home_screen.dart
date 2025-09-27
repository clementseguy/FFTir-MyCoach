import '../widgets/session_card.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import '../models/shooting_session.dart';
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
                      Center(
                        child: Text(
                          'Évolution du nombre de points par série',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.transparent,
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) return SizedBox.shrink();
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(fontSize: 11, color: Colors.white),
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
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
                                      style: TextStyle(fontSize: 11, color: Colors.white),
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
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
                            minY: 0,
                            maxY: pointsSpots.map((e) => e.y).fold<double>(0, (prev, y) => y > prev ? y : prev) + 5,
                            lineBarsData: [
                              LineChartBarData(
                                spots: pointsSpots,
                                isCurved: true,
                                color: Colors.amber,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Évolution de la taille du groupement par série',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.transparent,
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= dates.length) return SizedBox.shrink();
                                    if (value != i.toDouble()) return SizedBox.shrink();
                                    final d = dates[i];
                                    return Text(
                                      '${d.day}/${d.month}',
                                      style: TextStyle(fontSize: 11, color: Colors.white),
                                      overflow: TextOverflow.visible,
                                      maxLines: 1,
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: groupSizeSpots.isNotEmpty ? groupSizeSpots.length - 1.0 : 1.0,
                            minY: 0,
                            maxY: groupSizeSpots.map((e) => e.y).fold<double>(0, (prev, y) => y > prev ? y : prev) + 2,
                            lineBarsData: [
                              LineChartBarData(
                                spots: groupSizeSpots,
                                isCurved: true,
                                color: Colors.cyanAccent,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
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
