import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/local_db_hive.dart';
import 'screens/home_screen.dart';
import 'screens/sessions_history_screen.dart';
import 'screens/create_session_screen.dart';

// Pages vides pour Coach, Exercices et Paramètres
class CoachScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Coming soon', style: TextStyle(fontSize: 24))),
    );
  }
}

class ExercicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Coming soon', style: TextStyle(fontSize: 24))),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Coming soon', style: TextStyle(fontSize: 24))),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('sessions');
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tir Sportif',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Color(0xFF16FF8B),
          background: Color(0xFF181A20),
          surface: Color(0xFF23272F),
        ),
        scaffoldBackgroundColor: Color(0xFF181A20),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        cardColor: Color(0xFF23272F),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF16FF8B),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            elevation: 2,
          ),
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF23272F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF16FF8B), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.amber, width: 2),
          ),
          labelStyle: TextStyle(color: Color(0xFF16FF8B)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        iconTheme: IconThemeData(color: Color(0xFF16FF8B), size: 24),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF16FF8B),
          foregroundColor: Colors.black,
        ),
        dividerColor: Colors.grey[800],
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // 0: Coach, 1: Exercices, 2: Accueil, 3: Historique, 4: Paramètres

  final List<Widget> _pages = [
    CoachScreen(),
    ExercicesScreen(),
    HomeScreen(),
    const SessionsHistoryScreen(),
    SettingsScreen(),
  ];

  // Pour rafraîchir SessionsHistoryScreen
  final GlobalKey<SessionsHistoryScreenState> _historyKey = GlobalKey<SessionsHistoryScreenState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int safeIndex = (_selectedIndex >= 0 && _selectedIndex < _pages.length) ? _selectedIndex : 0;

    // Historique : AppBar + actions + contenu
    if (safeIndex == 3) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.track_changes, color: Colors.amber),
              SizedBox(width: 10),
              Text('Mes sessions'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.bolt, color: Colors.amber),
              tooltip: 'Ajouter 3 sessions aléatoires',
              onPressed: () async {
                await LocalDatabaseHive().insertRandomSessions(count: 3, status: 'réalisée');
                _historyKey.currentState?.refreshSessions();
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Recharger',
              onPressed: () {
                _historyKey.currentState?.refreshSessions();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SessionsHistoryScreen(key: _historyKey),
            // FloatingActionButton positionné en bas à droite
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'fab_create_session',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => CreateSessionScreen()),
                  ).then((_) => _historyKey.currentState?.refreshSessions());
                },
                child: Icon(Icons.add),
                tooltip: 'Créer une session',
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(safeIndex),
      );
    }

    // Autres pages : Scaffold simple
    return Scaffold(
      body: _pages[safeIndex],
      bottomNavigationBar: _buildBottomNavBar(safeIndex),
    );
  }

  Widget _buildBottomNavBar(int safeIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.white70,
      currentIndex: safeIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Coach',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Exercices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.track_changes),
          label: 'Sessions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Paramètres',
        ),
      ],
    );
  }
}

// Accueil/statistiques




// (getAllSessionsWithSeries est maintenant géré par LocalDatabaseHive)

class SeriesFormData {
  int shotCount;
  double distance;
  int points;
  double groupSize;
  String comment;
  SeriesFormData({
    this.shotCount = 5,
    this.distance = 0,
    this.points = 0,
    this.groupSize = 0,
    this.comment = '',
  });
}

class SessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final session = sessionData['session'];
    final series = sessionData['series'] as List<dynamic>;
    final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text('Détail de la session'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSessionScreen(initialSessionData: sessionData),
                ),
              );
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Supprimer',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Supprimer la session ?'),
                  content: Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await LocalDatabaseHive().deleteSession(session['id']);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Date : ${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 16)),
          Text('Arme : ${session['weapon']}'),
          Text('Calibre : ${session['caliber']}'),
          SizedBox(height: 16),
          Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
          ...series.asMap().entries.map((entry) {
            int i = entry.key;
            final s = entry.value;
            return Card(
              color: Colors.blueGrey[900],
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Série ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Nombre de coups : ${s['shot_count']}'),
                    Text('Distance : ${s['distance']} m'),
                    Text('Points : ${s['points']}'),
                    Text('Groupement : ${s['group_size']} cm'),
                    if ((s['comment'] ?? '').toString().isNotEmpty)
                      Text('Commentaire : ${s['comment']}'),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PointsLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Données simulées : évolution des points sur 6 sessions
    final spots = [
      FlSpot(0, 38),
      FlSpot(1, 42),
      FlSpot(2, 45),
      FlSpot(3, 44),
      FlSpot(4, 47),
      FlSpot(5, 49),
    ];
    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 24),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 35,
        maxY: 50,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
