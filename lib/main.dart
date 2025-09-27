import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants/session_constants.dart';
import 'data/local_db_hive.dart';
import 'screens/home_screen.dart';
import 'screens/sessions_history_screen.dart';
import 'screens/create_session_screen.dart';
import 'services/backup_service.dart';
import 'services/session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'config/app_config.dart';

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
    final backup = BackupService();
    final sessionService = SessionService();
    return Scaffold(
      appBar: AppBar(title: Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Sauvegarde & Portabilité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exporter toutes les sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Génère un fichier JSON contenant toutes les sessions (séries, synthèse, analyse).'),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.file_download),
                    label: Text('Exporter (.json)'),
                    onPressed: () async {
                      try {
                        final file = await backup.exportAllSessionsToJsonFile();
                        await Share.shareXFiles([XFile(file.path)], text: 'Export sessions MyCoach');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e')));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importer des sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Sélectionne un fichier JSON exporté précédemment pour réintégrer les sessions.'),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.file_upload),
                    label: Text('Importer (.json)'),
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                        if (result == null || result.files.isEmpty) return;
                        final path = result.files.single.path;
                        if (path == null) return;
                        final content = await File(path).readAsString();
                        final imported = await backup.importSessionsFromJson(content);
                        final total = (await sessionService.getAllSessions()).length;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$imported sessions importées. Total: $total')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur import: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 28),
          Text('Avertissement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Les exports ne chiffrent pas les données. Ne partage pas le fichier si tu ne fais pas confiance au destinataire.' , style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final start = DateTime.now();
  await AppConfig.load();
  await Hive.initFlutter();
  await Hive.openBox(SessionConstants.hiveBoxSessions);

  final minSplash = Duration(milliseconds: AppConfig.I.splashMinDisplayMs);
  final elapsed = DateTime.now().difference(start);
  if (elapsed < minSplash) {
    await Future.delayed(minSplash - elapsed);
  }

  FlutterNativeSplash.remove();
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
      home: FadeInWrapper(
        duration: Duration(milliseconds: AppConfig.I.splashFadeDurationMs),
        child: MainNavigation(),
      ),
    );
  }
}

class FadeInWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  const FadeInWrapper({super.key, required this.child, this.duration = const Duration(milliseconds: 450), this.curve = Curves.easeOut});

  @override
  State<FadeInWrapper> createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<FadeInWrapper> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Démarre le fade sur la prochaine frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // 0: Coach, 1: Exercices, 2: Accueil, 3: Historique, 4: Paramètres

  final GlobalKey<SessionsHistoryScreenState> _historyKey = GlobalKey<SessionsHistoryScreenState>();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CoachScreen(),
      ExercicesScreen(),
      HomeScreen(),
      SessionsHistoryScreen(key: _historyKey),
      SettingsScreen(),
    ];
    final safeIndex = (_selectedIndex >= 0 && _selectedIndex < pages.length) ? _selectedIndex : 0;

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
              onPressed: () => _historyKey.currentState?.refreshSessions(),
            ),
          ],
        ),
        body: Stack(
          children: [
            SessionsHistoryScreen(key: _historyKey),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'fab_create_session',
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (ctx) => CreateSessionScreen()))
                      .then((_) => _historyKey.currentState?.refreshSessions());
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

    return Scaffold(
      body: pages[safeIndex],
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
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Coach'),
        BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercices'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Sessions'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
      ],
    );
  }
}

// Accueil/statistiques




// (getAllSessionsWithSeries est maintenant géré par LocalDatabaseHive)


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
