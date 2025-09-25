import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'local_db_hive.dart';
import 'screens/home_screen.dart';


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
          secondary: Color(0xFF16FF8B), // Sea Foam
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
            backgroundColor: Color(0xFF16FF8B), // Sea Foam
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
      home: HomeScreen(),
    );
  }
}

// Accueil/statistiques


class CreateSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? initialSessionData;
  const CreateSessionScreen({super.key, this.initialSessionData});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date = DateTime.now();
  late TextEditingController _weaponController = TextEditingController();
  late TextEditingController _caliberController = TextEditingController(text: '22LR');
  late List<SeriesFormData> _series = [SeriesFormData(distance: 25)];
  int? _editingSessionId;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _weaponController = TextEditingController();
    _caliberController = TextEditingController();
    if (widget.initialSessionData != null) {
      final session = widget.initialSessionData!['session'];
      final seriesRaw = widget.initialSessionData!['series'];
      final List<dynamic> series = (seriesRaw is List) ? seriesRaw : [];
      // Récupère la clé Hive (id) depuis le parent de sessionData si présente
      _editingSessionId = session['id'] as int?
        ?? widget.initialSessionData!['id'] as int?;
      _date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
      _weaponController.text = session['weapon'] ?? '';
      _caliberController.text = session['caliber'] ?? '22LR';
      _series = series.map((s) => SeriesFormData(
        shotCount: s['shot_count'] ?? 5,
        distance: (s['distance'] as num?)?.toDouble() ?? 25,
        points: s['points'] ?? 0,
        groupSize: (s['group_size'] as num?)?.toDouble() ?? 0,
        comment: s['comment'] ?? '',
      )).toList();
      if (_series.isEmpty) _series = [SeriesFormData(distance: 25)];
    } else {
      _caliberController.text = '22LR';
      _series = [SeriesFormData(distance: 25)];
    }
  }

  @override
  void dispose() {
    _weaponController.dispose();
    _caliberController.dispose();
    super.dispose();
  }

  void _addSeries() {
    setState(() {
      _series.add(SeriesFormData(distance: 25));
    });
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_series.isEmpty || _series.every((s) => s.shotCount == 0 && s.distance == 0 && s.points == 0 && s.groupSize == 0 && s.comment.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez ajouter au moins une série à la session.')),
      );
      return;
    }
    final session = <String, dynamic>{
      'date': _date.toIso8601String(),
      'weapon': _weaponController.text,
      'caliber': _caliberController.text,
    };
    if (_editingSessionId != null) {
      session['id'] = _editingSessionId;
    }
    final seriesList = _series.map((s) => {
      'shot_count': s.shotCount,
      'distance': s.distance,
      'points': s.points,
      'group_size': s.groupSize,
      'comment': s.comment,
    }).toList();
    try {
      if (_editingSessionId != null) {
        await LocalDatabaseHive().updateSession(session, seriesList);
        print('Session mise à jour: id=$_editingSessionId');
      } else {
        await LocalDatabaseHive().insertSession(session, seriesList);
        print('Session insérée: data=$session, séries=$seriesList');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session enregistrée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur à l\'enregistrement')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingSessionId != null ? 'Modifier la session' : 'Nouvelle session'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey[800]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sports, size: 48, color: Colors.amber),
                  SizedBox(height: 8),
                  Text('Tir Sportif', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              selected: ModalRoute.of(context)?.settings.name == '/' || ModalRoute.of(context)?.settings.name == null,
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Nouvelle session'),
              selected: ModalRoute.of(context)?.settings.name == '/create',
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).push(MaterialPageRoute(settings: RouteSettings(name: '/create'), builder: (context) => CreateSessionScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Historique'),
              selected: ModalRoute.of(context)?.settings.name == '/history',
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).push(MaterialPageRoute(settings: RouteSettings(name: '/history'), builder: (context) => SessionsHistoryScreen()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: Text('Date'),
                subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              TextFormField(
                controller: _weaponController,
                decoration: InputDecoration(labelText: 'Arme utilisée'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                onTap: () {
                  if (_weaponController.text.isEmpty) _weaponController.clear();
                },
              ),
              TextFormField(
                controller: _caliberController,
                decoration: InputDecoration(labelText: 'Calibre'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                onTap: () {
                  if (_caliberController.text == '22LR' || _caliberController.text.isEmpty) _caliberController.clear();
                },
              ),
              SizedBox(height: 16),
              Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._series.asMap().entries.map((entry) {
                final i = entry.key;
                final serie = entry.value;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Série ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(
                          initialValue: serie.shotCount.toString(),
                          decoration: InputDecoration(labelText: 'Nombre de coups'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => serie.shotCount = int.tryParse(v) ?? 0,
                          onTap: () {
                            if (serie.shotCount == 5) {
                              // Efface la valeur par défaut si pas modifiée
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final field = FocusScope.of(context).focusedChild;
                                if (field != null) field.unfocus();
                              });
                            }
                          },
                        ),
                        TextFormField(
                          initialValue: serie.distance.toString(),
                          decoration: InputDecoration(labelText: 'Distance tireur/cible (m)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => serie.distance = double.tryParse(v) ?? 0,
                          onTap: () {
                            if (serie.distance == 25) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final field = FocusScope.of(context).focusedChild;
                                if (field != null) field.unfocus();
                              });
                            }
                          },
                        ),
                        TextFormField(
                          initialValue: serie.points.toString(),
                          decoration: InputDecoration(labelText: 'Nombre de points'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => serie.points = int.tryParse(v) ?? 0,
                        ),
                        TextFormField(
                          initialValue: serie.groupSize.toString(),
                          decoration: InputDecoration(labelText: 'Taille du groupement (cm)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => serie.groupSize = double.tryParse(v) ?? 0,
                        ),
                        TextFormField(
                          initialValue: serie.comment,
                          decoration: InputDecoration(labelText: 'Commentaires'),
                          onChanged: (v) => serie.comment = v,
                        ),
                        if (_series.length > 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() => _series.removeAt(i));
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                              label: Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addSeries,
                  icon: Icon(Icons.add),
                  label: Text('Ajouter une série'),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSession,
                child: Text(_editingSessionId != null ? 'Enregistrer les modifications' : 'Enregistrer la session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionsHistoryScreen extends StatefulWidget {
  @override
  _SessionsHistoryScreenState createState() => _SessionsHistoryScreenState();
}

class _SessionsHistoryScreenState extends State<SessionsHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _sessionsFuture = LocalDatabaseHive().getSessionsWithSeries();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when coming back to this screen
    _refreshSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des sessions'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Recharger',
            onPressed: _refreshSessions,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(child: Text('Aucune session enregistrée.'));
          }
          // Trier les sessions par date décroissante
          sessions.sort((a, b) {
            final dateA = DateTime.tryParse(a['session']['date'] ?? '') ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['session']['date'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index]['session'];
              final series = sessions[index]['series'] as List<dynamic>? ?? [];
              final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
              final caliber = session['caliber'] ?? '';
              final weapon = session['weapon'] ?? '';
              final nbSeries = series.length;
              return Card(
                child: ListTile(
                  title: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                  subtitle: Text('Arme : $weapon   |   Calibre : $caliber   |   Séries : $nbSeries'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionDetailScreen(sessionData: sessions[index]),
                      ),
                    );
                    _refreshSessions();
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
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
                        final sessionId = session['id'] as int? ?? sessions[index]['id'] as int?;
                        if (sessionId != null) {
                          await LocalDatabaseHive().deleteSession(sessionId);
                          print('Session supprimée : id=$sessionId');
                          _refreshSessions();
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
