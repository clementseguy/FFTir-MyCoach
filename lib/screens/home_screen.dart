import '../widgets/session_card.dart';
import 'package:flutter/material.dart';
import '../local_db_hive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'session_detail_screen.dart';
import 'create_session_screen.dart';
import 'sessions_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rafraîchit la liste à chaque retour sur l'accueil
    _sessionsFuture = LocalDatabaseHive().getSessionsWithSeries();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionsFuture = LocalDatabaseHive().getSessionsWithSeries();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionsFuture = LocalDatabaseHive().getSessionsWithSeries();
  }

  Future<void> _addRandomSessions() async {
    await LocalDatabaseHive().insertRandomSessions(count: 3);
    setState(() {
      _sessionsFuture = LocalDatabaseHive().getSessionsWithSeries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/app_logo.png',
              height: 36,
            ),
            const SizedBox(width: 12),
            const Text('Accueil'),
          ],
        ),
        actions: [],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/app_logo.png',
                    height: 56,
                  ),
                  SizedBox(height: 8),
                  Text('Tir Sportif', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Nouvelle session'),
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateSessionScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Historique'),
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SessionsHistoryScreen()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statistiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final allSessions = (snapshot.data ?? [])
                    .where((s) {
                      final session = s['session'];
                      return session != null && (session['status'] ?? 'réalisée') == 'réalisée' && session['date'] != null;
                    })
                    .toList();
                  if (allSessions.isEmpty) {
                    return Center(child: Text('Aucune donnée pour les graphes.'));
                  }
                  final List<DateTime> dates = [];
                  final List<FlSpot> pointsSpots = [];
                  final List<FlSpot> groupSizeSpots = [];
                  final List<Map<String, dynamic>> sortedSessions = List<Map<String, dynamic>>.from(allSessions);
                  sortedSessions.sort((a, b) {
                    final dateA = DateTime.tryParse(a['session']['date'] ?? '') ?? DateTime.now();
                    final dateB = DateTime.tryParse(b['session']['date'] ?? '') ?? DateTime.now();
                    return dateB.compareTo(dateA);
                  });
                  final List<Map<String, dynamic>> lastSessions = sortedSessions.take(10).toList();
                  final List<Map<String, dynamic>> allSeries = [];
                  for (final session in lastSessions) {
                    final sessionDate = DateTime.tryParse(session['session']['date'] ?? '') ?? DateTime.now();
                    final List<dynamic> series = session['series'] ?? [];
                    for (final serie in series) {
                      allSeries.add({
                        'date': sessionDate,
                        'points': (serie['points'] ?? 0).toDouble(),
                        'group_size': (serie['group_size'] ?? 0).toDouble(),
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
                                    // Affiche les scores (axe Y)
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
                                    // Affiche la date de la série (axe X)
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
                                    return Text('${d.day}/${d.month}');
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
              Text('Dernières sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final sessions = (snapshot.data ?? [])
                    .where((s) {
                      final session = s['session'];
                      return session != null && (session['status'] ?? 'réalisée') == 'réalisée' && session['date'] != null;
                    })
                    .toList();
                  if (sessions.isEmpty) {
                    return Center(child: Text('Aucune session enregistrée.'));
                  }
                  final List<Map<String, dynamic>> sortedSessions = List<Map<String, dynamic>>.from(sessions);
                  sortedSessions.sort((a, b) {
                    final dateA = DateTime.tryParse(a['session']['date'] ?? '') ?? DateTime.now();
                    final dateB = DateTime.tryParse(b['session']['date'] ?? '') ?? DateTime.now();
                    return dateB.compareTo(dateA);
                  });
                  final List<Map<String, dynamic>> last3 = sortedSessions.take(3).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: last3.length,
                    itemBuilder: (context, index) {
                      final session = last3[index]['session'];
                      final series = last3[index]['series'] as List<dynamic>? ?? [];
                      return SessionCard(
                        session: session,
                        series: series,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(sessionData: last3[index]),
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
