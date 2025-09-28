import '../widgets/session_card.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import 'session_detail_screen.dart';
import '../models/shooting_session.dart';
import 'create_session_screen.dart';


class SessionsHistoryScreen extends StatefulWidget {
  const SessionsHistoryScreen({Key? key}) : super(key: key);

  @override
  SessionsHistoryScreenState createState() => SessionsHistoryScreenState();
}

class SessionsHistoryScreenState extends State<SessionsHistoryScreen> {
  final SessionService _sessionService = SessionService();
  late Future<List<ShootingSession>> _sessionsFuture;
  String _filter = 'realized'; // realized | planned | all

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
      final all = (snapshot.data ?? []);
      final realizedAll = all.where((s) => (s.status == SessionConstants.statusRealisee) && (s.date != null)).toList();
      final plannedAll = all.where((s) => s.status == SessionConstants.statusPrevue).toList();

      List<ShootingSession> sessions = realizedAll;
      List<ShootingSession> planned = plannedAll;
      if (_filter == 'planned') {
        sessions = const [];
      } else if (_filter == 'realized') {
        // planned remains for optional section only when 'all'
        planned = const [];
      } else if (_filter == 'all') {
        // keep both
      }
            if (sessions.isEmpty) {
              return _EmptyState(onCreate: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const CreateSessionScreen(),
                  ),
                );
                refreshSessions();
              });
            }
            // Tri et regroupement par jour
            sessions.sort((a,b)=> b.date!.compareTo(a.date!));
            final Map<DateTime,List<ShootingSession>> grouped = {};
            for (final s in sessions) {
              final d = s.date!;
              final key = DateTime(d.year, d.month, d.day);
              grouped.putIfAbsent(key, ()=> []); grouped[key]!.add(s);
            }
            final orderedKeys = grouped.keys.toList()..sort((a,b)=> b.compareTo(a));
            // Stats header
            final int nbSessions = sessions.length;
            final int totalSeries = sessions.fold(0, (sum, s) => sum + (s.series.length));
            final double avgSeries = nbSessions > 0 ? totalSeries / nbSessions : 0;
            final int daysActive = grouped.length;
            return RefreshIndicator(
              onRefresh: () async { refreshSessions(); await Future.delayed(Duration(milliseconds:300)); },
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 24, top: 8),
                itemCount: 1 + orderedKeys.length + (planned.isNotEmpty ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(value: 'realized', label: Text('Réalisées')), 
                                    ButtonSegment(value: 'planned', label: Text('Prévues')), 
                                    ButtonSegment(value: 'all', label: Text('Toutes')),
                                  ],
                                  selected: {_filter},
                                  onSelectionChanged: (s)=> setState(()=> _filter = s.first),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _SummaryHeader(nbSessions: nbSessions, totalSeries: totalSeries, avgSeries: avgSeries, daysActive: daysActive),
                      ],
                    );
                  }
                  int cursor = 1;
                  if (planned.isNotEmpty) {
                    if (index == cursor) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16,8,16,4),
                        child: Text('Sessions prévues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amberAccent)),
                      );
                    }
                    cursor++;
                    if (index == cursor) {
                      return Column(
                        children: planned.map((p)=> Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                          child: SessionCard(
                            session: p.toMap(),
                            series: const [],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SessionDetailScreen(sessionData: {
                                    'session': p.toMap(),
                                    'series': [],
                                  }),
                                ),
                              );
                              refreshSessions();
                            },
                          ),
                        )).toList(),
                      );
                    }
                    cursor++;
                  }
                  final dayIndex = index - cursor;
                  final day = orderedKeys[dayIndex];
                  final list = grouped[day]!;
                  return _DaySection(day: day, sessions: list, onChanged: refreshSessions, sessionService: _sessionService);
                },
              ),
            );
        },
      );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int nbSessions;
  final int totalSeries;
  final double avgSeries;
  final int daysActive;
  const _SummaryHeader({required this.nbSessions, required this.totalSeries, required this.avgSeries, required this.daysActive});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16,16,16,12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text('Résumé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _Stat(label: 'Sessions', value: nbSessions.toString(), icon: Icons.track_changes, color: Colors.amberAccent),
                  _VerticalDivider(),
                  _Stat(label: 'Séries', value: totalSeries.toString(), icon: Icons.list_alt, color: Colors.lightBlueAccent),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  _Stat(label: 'Moy./session', value: avgSeries.toStringAsFixed(1), icon: Icons.stacked_line_chart, color: Colors.pinkAccent),
                  _VerticalDivider(),
                  _Stat(label: 'Jours actifs', value: daysActive.toString(), icon: Icons.event_available, color: Colors.tealAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 42, color: Colors.white12, margin: EdgeInsets.symmetric(horizontal: 8));
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<ShootingSession> sessions;
  final VoidCallback onChanged;
  final SessionService sessionService;
  const _DaySection({required this.day, required this.sessions, required this.onChanged, required this.sessionService});
  @override
  Widget build(BuildContext context) {
    final title = '${day.day}/${day.month}/${day.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.amberAccent),
                SizedBox(width: 6),
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${sessions.length} session${sessions.length>1? 's':''}', style: TextStyle(fontSize: 11, color: Colors.white70)),
                )
              ],
            ),
          ),
          ...sessions.map((session) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: GestureDetector(
              onLongPress: () async {
                final action = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Wrap(children: [
                      ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Supprimer'), onTap: ()=> Navigator.pop(ctx, 'delete')),
                      ListTile(leading: Icon(Icons.close), title: Text('Annuler'), onTap: ()=> Navigator.pop(ctx, null)),
                    ]),
                  ),
                );
                if (action == 'delete' && session.id != null) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Supprimer la session ?'),
                      content: Text('Cette action est irréversible.'),
                      actions: [
                        TextButton(onPressed: ()=> Navigator.pop(ctx, false), child: Text('Annuler')),
                        TextButton(onPressed: ()=> Navigator.pop(ctx, true), child: Text('Supprimer', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await sessionService.deleteSession(session.id!);
                    onChanged();
                  }
                }
              },
              child: SessionCard(
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
                  onChanged();
                },
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 56, color: Colors.white24),
            SizedBox(height: 16),
            Text('Aucune session pour le moment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Crée ta première session pour commencer à analyser ta progression.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white70)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Nouvelle session'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
