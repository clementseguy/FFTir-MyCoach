import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import 'create_session_screen.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import '../widgets/series_list.dart';
import 'package:flutter/services.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import 'wizard/planned_session_wizard.dart';
import 'session_detail/session_detail_components.dart';


class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final SessionService _sessionService = SessionService();
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
          SessionHeaderCard(session: session, series: series, planned: isPlanned),
          if (session.exercises.isNotEmpty) ...[
            SizedBox(height: 16),
            SessionExercisesSection(
              exerciseIds: session.exercises,
              allExercises: _allExercises,
            ),
          ],
          if (isRealisee) ...[
            SizedBox(height: 16),
            SessionCoachAnalysisSection(
              session: session,
              analyse: analyse,
              parentContext: context,
              onAnalyseUpdated: () async {
                final all = await _sessionService.getAllSessions();
                final updated = all.firstWhere((s)=> s.id == session.id, orElse: ()=> session);
                setState(() {
                  _currentSessionData!['session'] = updated.toMap();
                  _currentSessionData!['series'] = updated.series.map((s)=> s.toMap()).toList();
                });
              },
            ),
          ],
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
              child: SessionSyntheseSection(synthese: session.synthese!),
            ),
        ],
      ),
    );
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
