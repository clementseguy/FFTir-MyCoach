import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/session_constants.dart';
import '../data/local_db_hive.dart';
import '../screens/coach_screen.dart';
import '../screens/exercices_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sessions_history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_session_screen.dart';

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
              child: GestureDetector(
                onLongPress: () {
                  // Ouvre un menu contextuel pour créer une session prévue
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.schedule, color: Colors.blueAccent),
                              title: const Text('Créer une session prévue'),
                              subtitle: const Text('Statut prérempli: prévue'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                final initial = {
                                  'session': {
                                    'weapon': '',
                                    'caliber': '22LR',
                                    'status': SessionConstants.statusPrevue,
                                    'category': SessionConstants.categoryEntrainement,
                                    'series': [],
                                    'exercises': [],
                                  },
                                  'series': [],
                                };
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (c) => CreateSessionScreen(initialSessionData: initial)))
                                    .then((_) => _historyKey.currentState?.refreshSessions());
                              },
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text('Astuce: simple pression = réalisée', style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                onSecondaryTap: () { // Fallback Web: clic droit
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.schedule, color: Colors.blueAccent),
                              title: const Text('Créer une session prévue'),
                              subtitle: const Text('Statut prérempli: prévue'),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                final initial = {
                                  'session': {
                                    'weapon': '',
                                    'caliber': '22LR',
                                    'status': SessionConstants.statusPrevue,
                                    'category': SessionConstants.categoryEntrainement,
                                    'series': [],
                                    'exercises': [],
                                  },
                                  'series': [],
                                };
                                Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (c) => CreateSessionScreen(initialSessionData: initial)))
                                    .then((_) => _historyKey.currentState?.refreshSessions());
                              },
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text('Astuce: appui long / clic droit', style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: FloatingActionButton(
                  heroTag: 'fab_create_session',
                  onPressed: () {
                    // Création d'une session réalisée (comportement original)
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (ctx) => CreateSessionScreen()))
                        .then((_) => _historyKey.currentState?.refreshSessions());
                  },
                  child: const Icon(Icons.add),
                  tooltip: kIsWeb ? 'Créer une session (clic droit pour prévue)' : 'Créer une session (appui long pour prévue)',
                ),
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
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tableau de bord'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Sessions'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
      ],
    );
  }
}