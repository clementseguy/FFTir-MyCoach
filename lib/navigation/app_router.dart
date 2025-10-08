import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../screens/coach_screen.dart';
import '../screens/exercices_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sessions_history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_session_screen.dart';
import '../screens/goal_edit_screen.dart';
import '../screens/exercises_list_screen.dart';
import '../providers/navigation_provider.dart';
import '../constants/session_constants.dart';
import '../data/local_db_hive.dart';
import '../models/goal.dart';

/// Classe responsable de la gestion des routes nommées de l'application
class AppRouter {
  static const String home = '/';
  static const String coach = '/coach';
  static const String exercises = '/exercises';
  static const String sessions = '/sessions';
  static const String settings = '/settings';
  static const String createSession = '/sessions/create';
  static const String editGoal = '/goals/edit';
  static const String exercisesList = '/exercises/list';
  
  /// Retourne la route correspondant au nom spécifié
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == home) {
      return MaterialPageRoute(builder: (_) => HomeScreen());
    } else if (name == coach) {
      return MaterialPageRoute(builder: (_) => CoachScreen());
    } else if (name == exercises) {
      return MaterialPageRoute(builder: (_) => ExercicesScreen());
    } else if (name == sessions) {
      return MaterialPageRoute(builder: (_) => SessionsHistoryScreen());
    } else if (name == settings) {
      return MaterialPageRoute(builder: (_) => SettingsScreen());
    } else if (name == createSession) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CreateSessionScreen(
          initialSessionData: args,
        ),
      );
    } else if (name == editGoal) {
      final args = settings.arguments as Map<String, dynamic>?;
      Goal? goalToEdit;
      if (args != null && args.containsKey('goal')) {
        goalToEdit = args['goal'] as Goal?;
      }
      return MaterialPageRoute(
        builder: (_) => GoalEditScreen(
          existing: goalToEdit,
        ),
      );
    } else if (name == exercisesList) {
      return MaterialPageRoute(builder: (_) => ExercisesListScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route inconnue: ${name ?? "non définie"}'),
          ),
        ),
      );
    }
  }
}

/// Widget principal de navigation qui utilise un BottomNavigationBar
/// et un NavigationProvider pour gérer l'état de navigation
class AppNavigator extends StatelessWidget {
  AppNavigator({Key? key}) : super(key: key);
  
  final GlobalKey<SessionsHistoryScreenState> _historyKey = GlobalKey<SessionsHistoryScreenState>();
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, _) {
        final currentIndex = navigationProvider.currentIndex;
        final Widget body;
        
        // Page spéciale pour les sessions avec FAB
        if (currentIndex == 3) {
          body = _buildSessionsPage(context);
        } else {
          body = _getPageForIndex(currentIndex);
        }
        
        return Scaffold(
          appBar: currentIndex == 3 ? _buildSessionsAppBar(context) : null,
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.amber,
            unselectedItemColor: Colors.white70,
            currentIndex: currentIndex,
            onTap: (index) => navigationProvider.changeIndex(index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Coach'),
              BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercices'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tableau de bord'),
              BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Sessions'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
            ],
          ),
        );
      }
    );
  }
  
  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return CoachScreen();
      case 1:
        return ExercicesScreen();
      case 2:
        return HomeScreen();
      case 4:
        return SettingsScreen();
      default:
        return HomeScreen();
    }
  }
  
  AppBar _buildSessionsAppBar(BuildContext context) {
    return AppBar(
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
    );
  }

  Widget _buildSessionsPage(BuildContext context) {
    return Stack(
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
    );
  }
}