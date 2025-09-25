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
