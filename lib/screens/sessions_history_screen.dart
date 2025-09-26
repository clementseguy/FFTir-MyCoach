import '../widgets/session_card.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'session_detail_screen.dart';
import '../models/shooting_session.dart';


class SessionsHistoryScreen extends StatefulWidget {
  const SessionsHistoryScreen({Key? key}) : super(key: key);

  @override
  SessionsHistoryScreenState createState() => SessionsHistoryScreenState();
}

class SessionsHistoryScreenState extends State<SessionsHistoryScreen> {
  final SessionService _sessionService = SessionService();
  late Future<List<ShootingSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    refreshSessions();
  }

  void refreshSessions() {
    setState(() {
      _sessionsFuture = _sessionService.getAllSessions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshSessions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ShootingSession>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final sessions = (snapshot.data ?? [])
            .where((s) => (s.status == 'réalisée') && (s.date != null))
            .toList();
        if (sessions.isEmpty) {
          return Center(child: Text('Aucune session enregistrée.'));
        }
        // Calculs statistiques
        final int nbSessions = sessions.length;
        final int totalSeries = sessions.fold(0, (sum, s) => sum + (s.series.length));
        final double avgSeries = nbSessions > 0 ? totalSeries / nbSessions : 0;
        // Trier les sessions par date décroissante
        sessions.sort((a, b) {
          final dateA = a.date ?? DateTime(1970);
          final dateB = b.date ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Nombre de sessions : $nbSessions',
                    child: Row(
                      children: [
                        Icon(Icons.track_changes, color: Colors.amber),
                        SizedBox(width: 4),
                        Text('$nbSessions', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  Tooltip(
                    message: 'Nombre moyen de séries par session : ${avgSeries.toStringAsFixed(2)}',
                    child: Row(
                      children: [
                        Icon(Icons.stacked_line_chart, color: Colors.cyanAccent),
                        SizedBox(width: 4),
                        Text('${avgSeries.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return SessionCard(
                    session: session.toMap(),
                    series: session.series.map((s) => s.toMap()).toList(),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SessionDetailScreen(sessionData: {
                            'session': session.toMap(),
                            'series': session.series.map((s) => s.toMap()).toList(),
                          }),
                        ),
                      );
                      refreshSessions();
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
                      if (confirm == true && session.id != null) {
                        await _sessionService.deleteSession(session.id!);
                        refreshSessions();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
