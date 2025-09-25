import 'package:flutter/material.dart';
import '../local_db_hive.dart';
import 'create_session_screen.dart';

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
