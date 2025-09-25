import '../widgets/session_card.dart';
import 'package:flutter/material.dart';
import '../local_db_hive.dart';
import 'session_detail_screen.dart';

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
    _refreshSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des sessions'),
        actions: [
          IconButton(
            icon: Icon(Icons.bolt, color: Colors.amber),
            tooltip: 'Ajouter 3 sessions aléatoires',
            onPressed: () async {
              await LocalDatabaseHive().insertRandomSessions(count: 3, status: 'réalisée');
              _refreshSessions();
            },
          ),
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
          final sessions = (snapshot.data ?? [])
            .where((s) {
              final session = s['session'];
              return session != null && (session['status'] ?? 'réalisée') == 'réalisée' && session['date'] != null;
            })
            .toList();
          if (sessions.isEmpty) {
            return Center(child: Text('Aucune session enregistrée.'));
          }
          // Calculs statistiques
          final int nbSessions = sessions.length;
          final int totalSeries = sessions.fold(0, (sum, s) => sum + ((s['series'] as List?)?.length ?? 0));
          final double avgSeries = nbSessions > 0 ? totalSeries / nbSessions : 0;
          // Trier les sessions par date décroissante
          sessions.sort((a, b) {
            final dateA = DateTime.tryParse(a['session']['date'] ?? '') ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['session']['date'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre de sessions : $nbSessions', style: Theme.of(context).textTheme.bodyLarge),
                    SizedBox(height: 4),
                    Text('Nombre moyen de séries par session : ${avgSeries.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index]['session'];
                    final series = sessions[index]['series'] as List<dynamic>? ?? [];
                    return SessionCard(
                      session: session,
                      series: series,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionDetailScreen(sessionData: sessions[index]),
                          ),
                        );
                        _refreshSessions();
                      },
                      onDelete: () async {
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
                            _refreshSessions();
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
