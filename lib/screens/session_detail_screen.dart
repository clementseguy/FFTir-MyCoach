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
  final ScrollController _analyseScrollController = ScrollController();
  final SessionService _sessionService = SessionService();
  bool _isAnalysing = false;

  Map<String, dynamic>? _currentSessionData;

  @override
  void initState() {
    super.initState();
    _currentSessionData = widget.sessionData;
  }

  Future<void> _reloadSessionFromDb() async {
    if (_currentSessionData?['session']?['id'] != null) {
      final allSessions = await _sessionService.getAllSessions();
      final sessionId = _currentSessionData!['session']['id'];
      ShootingSession? found;
      for (final s in allSessions) {
        if (s.id == sessionId) {
          found = s;
          break;
        }
      }
      if (found != null) {
        final sessionMap = found.toMap();
        final seriesList = found.series.map((s) => s.toMap()).toList();
        setState(() {
          _currentSessionData = {
            'session': sessionMap,
            'series': seriesList,
          };
        });
      }
    }
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
                  builder: (context) => CreateSessionScreen(initialSessionData: widget.sessionData),
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
            ElevatedButton.icon(
              icon: Icon(Icons.analytics),
              label: Text((analyse != null && analyse.trim().isNotEmpty)
                  ? 'La session a été analysée'
                  : 'Analyser la session'),
              onPressed: (analyse != null && analyse.trim().isNotEmpty) || _isAnalysing
                  ? null
                  : () async {
                      setState(() => _isAnalysing = true);
                      final prompt = await DefaultAssetBundle.of(context).loadString('assets/coach_prompt.yaml');
                      final configStr = await DefaultAssetBundle.of(context).loadString('assets/config.yaml');
                      final config = loadYaml(configStr);
                      final mistralApiKey = config['api']['mistral_key']?.toString() ?? '';
                      final mistralUrl = config['api']['mistral_url']?.toString() ?? 'https://api.mistral.ai/v1/chat/completions';
                      final mistralModel = config['api']['mistral_model']?.toString() ?? 'mistral-medium';
                      final message = _buildAnalysePrompt(prompt, session, series);
                      print('[Mistral] Clé API utilisée : $mistralApiKey');
                      String analyseResult = '';
                      bool apiSuccess = false;
                      try {
                        print('[Mistral] Appel API avec prompt :\n$message');
                        final response = await http.post(
                          Uri.parse(mistralUrl),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $mistralApiKey',
                          },
                          body: jsonEncode({
                            'model': mistralModel,
                            'messages': [
                              {'role': 'user', 'content': message},
                            ],
                            'temperature': 0.7,
                          }),
                        );
                        print('[Mistral] Status: \\${response.statusCode}');
                        print('[Mistral] Réponse brute: \\${response.body}');
                        if (response.statusCode >= 200 && response.statusCode < 300) {
                          final data = jsonDecode(response.body);
                          analyseResult = data['choices'][0]['message']['content']?.toString() ?? 'Réponse vide.';
                          print('[Mistral] Analyse extraite: $analyseResult');
                          apiSuccess = true;
                        } else {
                          analyseResult = 'Erreur API Mistral : \\${response.statusCode}\n\\${response.body}';
                          print('[Mistral] Erreur API : $analyseResult');
                        }
                      } catch (e) {
                        analyseResult = 'Erreur lors de l\'appel à l\'API Mistral : $e';
                        print('[Mistral] Exception : $e');
                      }
                      setState(() => _isAnalysing = false);
                      if (apiSuccess) {
                        // Enregistrer l'analyse en base
                        final updatedSession = ShootingSession.fromMap(session.toMap());
                        updatedSession.toMap()['analyse'] = analyseResult;
                        await _sessionService.updateSession(
                          ShootingSession.fromMap({...updatedSession.toMap(), 'analyse': analyseResult})
                            ..series = series
                        );
                        await _reloadSessionFromDb();
                        // Afficher le retour
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            final theme = Theme.of(context);
                            final isDark = theme.brightness == Brightness.dark;
                            final bgColor = theme.dialogBackgroundColor;
                            final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
                            final titleColor = theme.textTheme.titleLarge?.color ?? (isDark ? Colors.white : Colors.black87);
                            return Dialog(
                              backgroundColor: bgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                                    minWidth: 300,
                                    maxWidth: 600,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Analyse de la session',
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: titleColor,
                                        ) ?? TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: titleColor),
                                      ),
                                      SizedBox(height: 16),
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _analyseScrollController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: _analyseScrollController,
                                            child: MarkdownBody(
                                              data: analyseResult,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(color: textColor, fontSize: 16),
                                                strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                                h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor),
                                                h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor.withOpacity(0.9)),
                                                h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor.withOpacity(0.8)),
                                                code: TextStyle(color: Colors.deepOrange),
                                                blockquote: TextStyle(color: textColor.withOpacity(0.7), fontStyle: FontStyle.italic),
                                                listBullet: TextStyle(color: textColor),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text('Fermer', style: TextStyle(color: theme.colorScheme.primary)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        // Afficher une popup d'erreur sans enregistrer l'analyse
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Erreur'),
                            content: Text('Désolé, le coach n\'est pas disponible. Réessayez ultérieurement ou contactez le support.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Fermer'))],
                          ),
                        );
                      }
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
  String _buildAnalysePrompt(String prompt, ShootingSession session, List<Series> series) {
    final buffer = StringBuffer();
    buffer.writeln(prompt);
    buffer.writeln('Session :');
    buffer.writeln('Arme : ${session.weapon}');
    buffer.writeln('Calibre : ${session.caliber}');
    if (session.date != null) buffer.writeln('Date : ${session.date!.toIso8601String()}');
    buffer.writeln('Séries :');
    for (int i = 0; i < series.length; i++) {
      final s = series[i];
      buffer.writeln('- Série ${i + 1} : Coups=${s.shotCount}, Distance=${s.distance}m, Points=${s.points}, Groupement=${s.groupSize}cm, Commentaire=${s.comment}');
    }
    return buffer.toString();
  }
}
