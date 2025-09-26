import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:yaml/yaml.dart';
import '../services/session_service.dart';
import 'create_session_screen.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';


class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final SessionService _sessionService = SessionService();
  bool _isAnalysing = false;

  Map<String, dynamic>? _currentSessionData;

  @override
  void initState() {
    super.initState();
    _currentSessionData = widget.sessionData;
  }


  @override
  Widget build(BuildContext context) {
    if (_currentSessionData == null || _currentSessionData!['session'] == null || _currentSessionData!['series'] == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Détail de la session')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final session = ShootingSession.fromMap(_currentSessionData!['session']);
    final series = (_currentSessionData!['series'] as List<dynamic>).map((s) => Series.fromMap(Map<String, dynamic>.from(s))).toList();
    final date = session.date ?? DateTime.now();
    final isRealisee = session.status == 'réalisée';
    String? analyse = _currentSessionData!['session']['analyse'];
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
                  builder: (context) => CreateSessionScreen(initialSessionData: widget.sessionData, isEdit: true),
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
              if (confirm == true && session.id != null) {
                await _sessionService.deleteSession(session.id!);
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
          Text('Arme : ${session.weapon}'),
          Text('Calibre : ${session.caliber}'),
          SizedBox(height: 16),
          if (_isAnalysing) ...[
            LinearProgressIndicator(),
            SizedBox(height: 12),
            Text('Le coach analyse votre session, merci de patienter...', style: TextStyle(fontStyle: FontStyle.italic)),
            SizedBox(height: 16),
          ],
          if (isRealisee)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.analytics),
                  label: Text((analyse != null && analyse.trim().isNotEmpty)
                      ? 'La session a été analysée'
                      : 'Analyser la session'),
                  onPressed: (!_isAnalysing && (analyse == null || analyse.trim().isEmpty))
                      ? () async {
                          setState(() => _isAnalysing = true);
                          try {
                            // 1. Charger la config API
                            final configStr = await DefaultAssetBundle.of(context).loadString('assets/config.yaml');
                            final config = loadYaml(configStr);
                            final apiConfig = config['api'];
                            final mistralApiKey = apiConfig['mistral_key'].toString();
                            final mistralUrl = apiConfig['mistral_url'].toString();
                            final mistralModel = apiConfig['mistral_model'].toString();

                            // 2. Charger le prompt initial
                            final promptStr = await DefaultAssetBundle.of(context).loadString('assets/coach_prompt.yaml');
                            final promptYaml = loadYaml(promptStr);
                            final promptTemplate = promptYaml['prompt'].toString();

                            // 3. Construire le prompt complet
                            final session = ShootingSession.fromMap(_currentSessionData!['session']);
                            final buffer = StringBuffer();
                            buffer.writeln(promptTemplate.trim());
                            buffer.writeln('\nSession :');
                            buffer.writeln('Arme : ${session.weapon}');
                            buffer.writeln('Calibre : ${session.caliber}');
                            buffer.writeln('Date : ${session.date?.toIso8601String() ?? "Non renseignée"}');
                            buffer.writeln('Séries :');
                            for (var i = 0; i < session.series.length; i++) {
                              final s = session.series[i];
                              buffer.writeln('- Série ${i + 1} : Coups=${s.shotCount}, Distance=${s.distance}m, Points=${s.points}, Groupement=${s.groupSize}cm, Commentaire=${s.comment}');
                            }
                            if (session.synthese != null && session.synthese!.trim().isNotEmpty) {
                              buffer.writeln('\nSynthèse du tireur :');
                              buffer.writeln(session.synthese);
                            }
                            final fullPrompt = buffer.toString();

                            // 4. Appel API Mistral
                            final response = await http.post(
                              Uri.parse(mistralUrl),
                              headers: {
                                'Authorization': 'Bearer $mistralApiKey',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'model': mistralModel,
                                'messages': [
                                  {'role': 'user', 'content': fullPrompt}
                                ]
                              }),
                            );

                            if (response.statusCode >= 200 && response.statusCode < 300) {
                              // Succès : extraire la réponse
                              final data = jsonDecode(response.body);
                              final coachReply = data['choices']?[0]?['message']?['content']?.toString() ?? 'Aucune analyse reçue.';
                              // Afficher la popup markdown
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Analyse du coach'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: SingleChildScrollView(
                                      child: MarkdownBody(data: coachReply),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                ),
                              );
                              // Enregistrer la réponse dans la session (champ analyse) AVEC les séries
                              final sessionMap = _currentSessionData!['session'];
                              final seriesList = (_currentSessionData!['series'] as List<dynamic>)
                                  .map((s) => Series.fromMap(Map<String, dynamic>.from(s)))
                                  .toList();
                              final updatedSession = ShootingSession.fromMap(sessionMap)
                                ..series = seriesList
                                ..analyse = coachReply;
                              await SessionService().updateSession(updatedSession);
                              setState(() {
                                _currentSessionData!['session']['analyse'] = coachReply;
                              });
                            } else {
                              // Erreur API
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Erreur'),
                                  content: const Text('Une erreur est survenue lors de l\'analyse, veuillez réesayer ultérieurement.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Erreur'),
                                content: const Text('Une erreur est survenue lors de l\'analyse, veuillez réesayer ultérieurement.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              ),
                            );
                          } finally {
                            setState(() => _isAnalysing = false);
                          }
                        }
                      : null,
                ),
                if (analyse != null && analyse.trim().isNotEmpty)
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
                    Text('Nombre de coups : ${s.shotCount}'),
                    Text('Distance : ${s.distance} m'),
                    Text('Points : ${s.points}'),
                    Text('Groupement : ${s.groupSize} cm'),
                    if ((s.comment).toString().isNotEmpty)
                      Text('Commentaire : ${s.comment}'),
                  ],
                ),
              ),
            );
          }),
          if (session.synthese != null && session.synthese!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synthèse du tireur',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        session.synthese!,
                        style: Theme.of(context).textTheme.bodyMedium,
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
}
