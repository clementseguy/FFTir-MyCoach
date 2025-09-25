import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        final isRealisee = (session['status'] ?? 'réalisée') == 'réalisée';
        String? analyse = session['analyse'];
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
              if (isRealisee)
                ElevatedButton.icon(
                  icon: Icon(Icons.analytics),
                  label: Text((analyse != null && analyse.trim().isNotEmpty)
                      ? 'La session a été analysée'
                      : 'Analyser la session'),
                  onPressed: (analyse != null && analyse.trim().isNotEmpty)
                      ? null
                      : () async {
                          final prompt = await DefaultAssetBundle.of(context).loadString('assets/coach_prompt.yaml');
                          final message = _buildAnalysePrompt(prompt, session, series);
                          String analyseResult = '';
                          try {
                            // Clé API Mistral fournie par l'utilisateur
                            const mistralApiKey = 'EeVTEcDwYHmXJVM4akVym7VdkOSMp28p';
                            print('[Mistral] Appel API avec prompt :\n$message');
                            final response = await http.post(
                              Uri.parse('https://api.mistral.ai/v1/chat/completions'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $mistralApiKey',
                              },
                              body: jsonEncode({
                                'model': 'mistral-medium',
                                'messages': [
                                  {'role': 'user', 'content': message},
                                ],
                                'temperature': 0.7,
                              }),
                            );
                            print('[Mistral] Status: ${response.statusCode}');
                            print('[Mistral] Réponse brute: ${response.body}');
                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);
                              analyseResult = data['choices'][0]['message']['content']?.toString() ?? 'Réponse vide.';
                              print('[Mistral] Analyse extraite: $analyseResult');
                            } else {
                              analyseResult = 'Erreur API Mistral : ${response.statusCode}\n${response.body}';
                              print('[Mistral] Erreur API : $analyseResult');
                            }
                          } catch (e) {
                            analyseResult = 'Erreur lors de l\'appel à l\'API Mistral : $e';
                            print('[Mistral] Exception : $e');
                          }
                          // Enregistrer l'analyse en base
                          final updatedSession = Map<String, dynamic>.from(session);
                          updatedSession['analyse'] = analyseResult;
                          await LocalDatabaseHive().updateSession(updatedSession, List<Map<String, dynamic>>.from(series));
                          // Afficher le retour
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Analyse de la session'),
                              content: Text(analyseResult),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Fermer'))],
                            ),
                          );
                        },
                ),
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
              if (isRealisee && analyse != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Card(
                    color: Colors.green[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Analyse du coach', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 8),
                          MarkdownBody(
                            data: analyse,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(color: Colors.white),
                              strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              h1: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              h2: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              h3: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              code: TextStyle(color: Colors.yellow[200]),
                              blockquote: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                              listBullet: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
  }

  // Construit le prompt à envoyer au chat Mistral
  String _buildAnalysePrompt(String prompt, Map<String, dynamic> session, List<dynamic> series) {
    final buffer = StringBuffer();
    buffer.writeln(prompt);
    buffer.writeln('Session :');
    buffer.writeln('Arme : ${session['weapon']}');
    buffer.writeln('Calibre : ${session['caliber']}');
    if (session['date'] != null) buffer.writeln('Date : ${session['date']}');
    buffer.writeln('Séries :');
    for (int i = 0; i < series.length; i++) {
      final s = series[i];
      buffer.writeln('- Série ${i + 1} : Coups=${s['shot_count']}, Distance=${s['distance']}m, Points=${s['points']}, Groupement=${s['group_size']}cm, Commentaire=${s['comment'] ?? ''}');
    }
    return buffer.toString();
  }
}
