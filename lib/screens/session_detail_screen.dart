import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import '../services/coach_analysis_service.dart';
import 'create_session_screen.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import '../widgets/coach_analysis_card.dart';
import '../widgets/series_list.dart';


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
  final isRealisee = session.status == SessionConstants.statusRealisee;
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
                            // Charger service et construire prompt
                            final analysisService = await CoachAnalysisService.fromAssets(
                              loadAsset: (path) => DefaultAssetBundle.of(context).loadString(path),
                            );
                            final session = ShootingSession.fromMap(_currentSessionData!['session']);
                            final fullPrompt = analysisService.buildPrompt(session);
                            // Appel API
                            final coachReply = await analysisService.fetchAnalysis(fullPrompt);
                            if (coachReply.trim().isNotEmpty) {
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
                            final msg = (e is CoachAnalysisException)
                                ? e.message
                                : 'Une erreur est survenue lors de l\'analyse, veuillez réessayer ultérieurement.';
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Erreur'),
                                  content: Text(msg),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } finally {
                            setState(() => _isAnalysing = false);
                          }
                        }
                      : null,
                ),
                if (analyse != null && analyse.trim().isNotEmpty)
                  const SizedBox(height: 24),
                if (analyse != null && analyse.trim().isNotEmpty)
                  CoachAnalysisCard(analyse: analyse),
              ],
            ),
          Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
          SeriesList(series: series),
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
