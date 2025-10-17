import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/shooting_session.dart';
import '../../models/series.dart';
import '../../models/exercise.dart';
import '../../services/coach_analysis_service.dart';
import '../../services/session_service.dart';
import '../../utils/markdown_sanitizer.dart';
import '../../widgets/coach_analysis_card.dart';

/// Carte header récapitulative de la session
class SessionHeaderCard extends StatelessWidget {
  final ShootingSession session;
  final List<Series> series;
  final bool planned;
  
  const SessionHeaderCard({
    super.key,
    required this.session,
    required this.series,
    this.planned = false,
  });

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: planned ? Colors.blueAccent.withValues(alpha:0.4): Colors.white12,
          width: 0.8,
        ),
      ),
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
                Text(
                  date != null ? '${date.day}/${date.month}/${date.year}' : 'Date inconnue',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Spacer(),
                SessionChip(
                  text: session.status,
                  icon: Icons.flag,
                  color: planned ? Colors.blueAccent : Colors.lightBlueAccent,
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                SessionChip(
                  text: session.weapon.isEmpty ? 'Arme ?' : session.weapon,
                  icon: Icons.security,
                  overrideBase: planned,
                ),
                SessionChip(
                  text: session.caliber.isEmpty ? 'Calibre ?' : session.caliber,
                  icon: Icons.bolt,
                  overrideBase: planned,
                ),
                if (session.category.isNotEmpty)
                  SessionChip(
                    text: session.category,
                    icon: Icons.category,
                    color: planned ? Colors.indigoAccent : Colors.purpleAccent,
                  ),
                SessionChip(
                  text: '${series.length} séries',
                  icon: Icons.list_alt,
                  color: chipBase,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                StatBlock(label: 'Total', value: '$totalPoints pts'),
                DividerVert(),
                StatBlock(label: 'Moy. série', value: avgPoints.toStringAsFixed(1)),
                DividerVert(),
                StatBlock(
                  label: 'Group. moy',
                  value: avgGroup>0? '${avgGroup.toStringAsFixed(1)} cm':'-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section analyse coach avec bouton génération
class SessionCoachAnalysisSection extends StatefulWidget {
  final ShootingSession session;
  final String? analyse;
  final BuildContext parentContext;
  final VoidCallback onAnalyseUpdated;

  const SessionCoachAnalysisSection({
    super.key,
    required this.session,
    required this.analyse,
    required this.parentContext,
    required this.onAnalyseUpdated,
  });

  @override
  State<SessionCoachAnalysisSection> createState() => _SessionCoachAnalysisSectionState();
}

class _SessionCoachAnalysisSectionState extends State<SessionCoachAnalysisSection> {
  bool _isAnalysing = false;

  Future<void> _launchAnalysis() async {
    setState(() => _isAnalysing = true);
    try {
      final analysisService = await CoachAnalysisService.fromAssets(
        loadAsset: (path) => DefaultAssetBundle.of(widget.parentContext).loadString(path),
      );
      final fullPrompt = analysisService.buildPrompt(widget.session);
      final rawReply = await analysisService.fetchAnalysis(fullPrompt);
      final coachReply = sanitizeCoachMarkdown(rawReply);
      
      try {
        final prev = coachReply.length > 160 ? coachReply.substring(0,160) : coachReply;
        // ignore: avoid_print
        print('[DEBUG] CoachAnalysis sanitized preview="'+prev.replaceAll('\n',' ')+'"');
      } catch(_) {}
      
      if (coachReply.trim().isNotEmpty) {
        // Afficher la popup markdown
        if (!mounted) return;
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
        
        // Enregistrer la réponse dans la session
        final updatedSession = widget.session..analyse = coachReply;
        await SessionService().updateSession(updatedSession);
        widget.onAnalyseUpdated();
      } else {
        // Erreur API
        if (!mounted) return;
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
      if (mounted) {
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
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        initiallyExpanded: widget.analyse != null && widget.analyse!.trim().isNotEmpty,
        leading: Icon(Icons.analytics, color: Colors.amberAccent),
        title: Text('Analyse Coach', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          (widget.analyse != null && widget.analyse!.trim().isNotEmpty)
              ? 'Analyse disponible'
              : 'Aucune analyse générée',
          style: TextStyle(fontSize: 12),
        ),
        children: [
          if (_isAnalysing) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Le coach analyse votre session, merci de patienter...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text(
                    (widget.analyse != null && widget.analyse!.trim().isNotEmpty)
                        ? 'Re-générer'
                        : 'Lancer analyse',
                  ),
                  onPressed: (widget.analyse == null || widget.analyse!.trim().isEmpty)
                      ? _launchAnalysis
                      : null,
                ),
              ),
            ),
          ],
          if (widget.analyse != null && widget.analyse!.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: LoggedCoachAnalysis(analyse: sanitizeCoachMarkdown(widget.analyse!)),
            ),
            SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Wrapper pour logger l'analyse coach lors du premier build d'affichage persistant
class LoggedCoachAnalysis extends StatefulWidget {
  final String analyse;
  const LoggedCoachAnalysis({super.key, required this.analyse});
  @override
  State<LoggedCoachAnalysis> createState() => _LoggedCoachAnalysisState();
}

class _LoggedCoachAnalysisState extends State<LoggedCoachAnalysis> {
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

/// Section exercices travaillés
class SessionExercisesSection extends StatelessWidget {
  final List<String> exerciseIds;
  final List<Exercise> allExercises;

  const SessionExercisesSection({
    super.key,
    required this.exerciseIds,
    required this.allExercises,
  });

  @override
  Widget build(BuildContext context) {
    final nameMap = {for (final e in allExercises) e.id: e.name};
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

/// Section synthèse du tireur
class SessionSyntheseSection extends StatelessWidget {
  final String synthese;

  const SessionSyntheseSection({super.key, required this.synthese});

  @override
  Widget build(BuildContext context) {
    if (synthese.trim().isEmpty) return SizedBox.shrink();
    
    return Card(
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
              synthese,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip générique pour affichage session
class SessionChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  final bool overrideBase;
  
  const SessionChip({
    super.key,
    required this.text,
    required this.icon,
    this.color,
    this.overrideBase = false,
  });
  
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

/// Bloc statistique générique
class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  
  const StatBlock({super.key, required this.label, required this.value});
  
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

/// Divider vertical
class DividerVert extends StatelessWidget {
  const DividerVert({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white12);
  }
}
