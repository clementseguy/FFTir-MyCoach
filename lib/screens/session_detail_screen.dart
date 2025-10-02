import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import '../services/coach_analysis_service.dart';
import 'create_session_screen.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import '../widgets/coach_analysis_card.dart';
import '../utils/markdown_sanitizer.dart';
import '../widgets/series_list.dart';
import 'package:flutter/services.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import 'wizard/planned_session_wizard.dart';


class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final SessionService _sessionService = SessionService();
  bool _isAnalysing = false;
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _allExercises = [];

  Map<String, dynamic>? _currentSessionData;

  @override
  void initState() {
    super.initState();
    _currentSessionData = widget.sessionData;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await _exerciseService.listAll();
      if (mounted) setState(()=> _allExercises = list);
    } catch (_) {}
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
  final isRealisee = session.status == SessionConstants.statusRealisee;
  final bool isPlanned = !isRealisee;
    String? analyse = _currentSessionData!['session']['analyse'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Session'),
        actions: [
          if (isPlanned) 
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Démarrer',
              onPressed: () async {
                final bool? converted = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlannedSessionWizard(session: session),
                  ),
                );
                if (converted == true) {
                  // Recharger session depuis service
                  final all = await _sessionService.getAllSessions();
                  final updated = all.firstWhere((s)=> s.id == session.id, orElse: ()=> session);
                  setState(() {
                    _currentSessionData!['session'] = updated.toMap();
                    _currentSessionData!['series'] = updated.series.map((s)=> s.toMap()).toList();
                  });
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.copy_all_outlined),
            tooltip: 'Copier résumé',
            onPressed: () async {
              final resume = _buildClipboardSummary(session, series);
              await Clipboard.setData(ClipboardData(text: resume));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Résumé copié')),);
              }
            },
          ),
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
            icon: Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Supprimer la session ?'),
                  content: Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Supprimer', style: TextStyle(color: Colors.red))),
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
          _SessionHeaderCard(session: session, series: series, planned: isPlanned),
          if (session.exercises.isNotEmpty) ...[
            SizedBox(height: 16),
            _ExercisesChips(exerciseIds: session.exercises, all: _allExercises),
          ],
          if (_isAnalysing) ...[
            SizedBox(height: 16),
            LinearProgressIndicator(),
            SizedBox(height: 12),
            Text('Le coach analyse votre session, merci de patienter...', style: TextStyle(fontStyle: FontStyle.italic)),
            SizedBox(height: 16),
          ],
          if (isRealisee)
            Card(
              color: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                initiallyExpanded: analyse != null && analyse.trim().isNotEmpty,
                leading: Icon(Icons.analytics, color: Colors.amberAccent),
                title: Text('Analyse Coach', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  (analyse != null && analyse.trim().isNotEmpty)
                      ? 'Analyse disponible'
                      : 'Aucune analyse générée',
                  style: TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.play_arrow),
                        label: Text(
                          (analyse != null && analyse.trim().isNotEmpty)
                              ? 'Re-générer'
                              : 'Lancer analyse',
                        ),
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
                            final rawReply = await analysisService.fetchAnalysis(fullPrompt);
                            final coachReply = sanitizeCoachMarkdown(rawReply);
                            if (coachReply.trim().isNotEmpty) {
                              // Log affichage immédiat (popup)
                              try {
                                final preview = coachReply.length > 180 ? coachReply.substring(0,180) : coachReply;
                                // ignore: avoid_print
                                print('[DEBUG] CoachAnalysis display (popup) len=${coachReply.length} preview="'+preview.replaceAll('\n',' ')+'"');
                              } catch(_) {}
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
                    ),
                  ),
                  if (analyse != null && analyse.trim().isNotEmpty) ...[
                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: _LoggedCoachAnalysis(analyse: sanitizeCoachMarkdown(analyse)),
                    ),
                    SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          SizedBox(height: 28),
          Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Séries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Spacer(),
              Text('${series.length} au total', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          SizedBox(height: 8),
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

/// Wrapper pour logger l'analyse coach lors du premier build d'affichage persistant.
class _LoggedCoachAnalysis extends StatefulWidget {
  final String analyse;
  const _LoggedCoachAnalysis({required this.analyse});
  @override
  State<_LoggedCoachAnalysis> createState() => _LoggedCoachAnalysisState();
}

class _LoggedCoachAnalysisState extends State<_LoggedCoachAnalysis> {
  bool _logged = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logged) {
      try {
        final preview = widget.analyse.length > 180 ? widget.analyse.substring(0,180) : widget.analyse;
        // ignore: avoid_print
        print('[DEBUG] CoachAnalysis display (persisted) len=${widget.analyse.length} preview="'+preview.replaceAll('\n',' ')+'"');
      } catch(_) {}
      _logged = true;
    }
  }
  @override
  Widget build(BuildContext context) {
    return CoachAnalysisCard(analyse: widget.analyse);
  }
}

String _buildClipboardSummary(ShootingSession s, List<Series> series) {
  final buf = StringBuffer();
  buf.writeln('Session ${s.date != null ? '${s.date!.day}/${s.date!.month}/${s.date!.year}' : ''}');
  buf.writeln('Arme: ${s.weapon} | Calibre: ${s.caliber}');
  if (s.category.isNotEmpty) buf.writeln('Catégorie: ${s.category}');
  buf.writeln('Séries (${series.length}):');
  for (int i=0;i<series.length;i++) {
    final se = series[i];
    final prise = se.handMethod == HandMethod.oneHand ? '1M' : '2M';
    buf.writeln('- #${i+1}: ${se.points} pts, group. ${se.groupSize} cm, dist ${se.distance}m, prise $prise');
  }
  if (s.synthese != null && s.synthese!.trim().isNotEmpty) {
    buf.writeln('Synthèse: ${s.synthese}');
  }
  if (s.analyse != null && s.analyse!.trim().isNotEmpty) {
    buf.writeln('Analyse Coach: ${s.analyse}');
  }
  return buf.toString();
}

class _SessionHeaderCard extends StatelessWidget {
  final ShootingSession session;
  final List<Series> series;
  final bool planned;
  const _SessionHeaderCard({required this.session, required this.series, this.planned = false});

  int get totalPoints => series.fold(0, (a,b)=> a + b.points);
  double get avgPoints => series.isEmpty ? 0 : totalPoints / series.length;
  double get avgGroup => () {
    final vals = series.where((s)=> s.groupSize > 0).map((e)=> e.groupSize).toList();
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a,b)=> a+b) / vals.length;
  }();

  @override
  Widget build(BuildContext context) {
    final date = session.date;
    final Color accent = planned ? Colors.blueAccent : Colors.amberAccent;
    final Color chipBase = planned ? Colors.lightBlueAccent : Colors.tealAccent;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: planned ? Colors.blueAccent.withValues(alpha:0.4): Colors.white12, width: 0.8)),
      color: planned ? Colors.blueGrey.withValues(alpha: 0.25) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: accent),
                SizedBox(width: 8),
                Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Date inconnue', style: TextStyle(fontWeight: FontWeight.w600)),
                Spacer(),
                _Chip(text: session.status, icon: Icons.flag, color: planned ? Colors.blueAccent : Colors.lightBlueAccent),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(text: session.weapon.isEmpty ? 'Arme ?' : session.weapon, icon: Icons.security, overrideBase: planned),
                _Chip(text: session.caliber.isEmpty ? 'Calibre ?' : session.caliber, icon: Icons.bolt, overrideBase: planned),
                if (session.category.isNotEmpty) _Chip(text: session.category, icon: Icons.category, color: planned ? Colors.indigoAccent : Colors.purpleAccent),
                _Chip(text: '${series.length} séries', icon: Icons.list_alt, color: chipBase),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _StatBlock(label: 'Total', value: '$totalPoints pts'),
                _DividerVert(),
                _StatBlock(label: 'Moy. série', value: avgPoints.toStringAsFixed(1)),
                _DividerVert(),
                _StatBlock(label: 'Group. moy', value: avgGroup>0? '${avgGroup.toStringAsFixed(1)} cm':'-'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  final bool overrideBase; // when planned, adjust default neutral chips
  const _Chip({required this.text, required this.icon, this.color, this.overrideBase = false});
  @override
  Widget build(BuildContext context) {
    final Color base = color ?? (overrideBase ? Colors.lightBlueAccent : Colors.white70);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base.withValues(alpha: 0.55), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: base),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: base)),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DividerVert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white12);
  }
}

class _ExercisesChips extends StatelessWidget {
  final List<String> exerciseIds;
  final List<Exercise> all;
  const _ExercisesChips({required this.exerciseIds, required this.all});

  @override
  Widget build(BuildContext context) {
    final nameMap = {for (final e in all) e.id: e.name};
    final names = exerciseIds.map((id) => nameMap[id] ?? id).toList();
    if (names.isEmpty) return SizedBox.shrink();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, size: 18, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Exercices travaillés', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final n in names)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text(n, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
