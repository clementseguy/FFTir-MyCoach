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
  String _filter = 'realized'; // realized | planned
  String get currentFilter => _filter;

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
        sessions = <ShootingSession>[];
      } else { // realized
        planned = <ShootingSession>[];
      }
            final bool noDataRealized = sessions.isEmpty && _filter == 'realized';
            final bool noDataPlannedOnly = _filter == 'planned' && planned.isEmpty;
            List<DateTime> orderedKeys = [];
            final Map<DateTime,List<ShootingSession>> grouped = {};
            if (_filter == 'realized') {
              sessions.sort((a,b)=> b.date!.compareTo(a.date!));
              for (final s in sessions) {
                final d = s.date!;
                final key = DateTime(d.year, d.month, d.day);
                grouped.putIfAbsent(key, ()=> []); grouped[key]!.add(s);
              }
              orderedKeys = grouped.keys.toList()..sort((a,b)=> b.compareTo(a));
            } else {
              // planned view: we won't group by day; treat each planned session as a flat list
              orderedKeys = [];
            }
            // Stats header (different for planned vs realized)
            final int nbSessions = sessions.length;
            final int totalSeries = sessions.fold(0, (sum, s) => sum + (s.series.length));
            final double avgSeries = nbSessions > 0 ? totalSeries / nbSessions : 0;
            final int daysActive = grouped.length;
            // Planned metrics
            int plannedCount = planned.length;
            int plannedWithDate = planned.where((p)=> p.date!=null).length;
            int plannedWithoutDate = plannedCount - plannedWithDate;
            DateTime? nextPlannedDate;
            final datedPlanned = planned.where((p)=> p.date!=null).toList();
            if (datedPlanned.isNotEmpty) {
              datedPlanned.sort((a,b)=> a.date!.compareTo(b.date!));
              nextPlannedDate = datedPlanned.first.date;
            }
            return RefreshIndicator(
              onRefresh: () async { refreshSessions(); await Future.delayed(Duration(milliseconds:300)); },
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 24, top: 8),
                itemCount: 1 + (noDataRealized ? 1 : 0) + (noDataPlannedOnly ? 1 : 0) + (_filter=='realized' ? orderedKeys.length : planned.length) + (planned.isNotEmpty && _filter=='realized' ? 2 : 0),
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
                                  ],
                                  selected: {_filter},
                                  onSelectionChanged: (s)=> setState(()=> _filter = s.first),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_filter == 'realized')
                          _SummaryHeader(nbSessions: nbSessions, totalSeries: totalSeries, avgSeries: avgSeries, daysActive: daysActive)
                        else
                          _PlannedHeader(
                            totalPlanned: plannedCount,
                            withDate: plannedWithDate,
                            withoutDate: plannedWithoutDate,
                            nextDate: nextPlannedDate,
                          ),
                      ],
                    );
                  }
                  int cursor = 1;
                  if (noDataPlannedOnly) {
                    if (index == cursor) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.pending_actions, size: 48, color: Colors.white24),
                            SizedBox(height: 12),
                            Text('Aucune session prévue', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Text('Crée une session prévue depuis le +', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60)),
                          ],
                        ),
                      );
                    }
                    cursor++;
                  }
                  if (noDataRealized) {
                    if (index == cursor) {
                      return _EmptyMini(onCreate: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => CreateSessionScreen(
                              initialSessionData: _filter == 'planned' ? {
                                'session': {
                                  'weapon': '',
                                  'caliber': '22LR',
                                  'status': SessionConstants.statusPrevue,
                                  'category': SessionConstants.categoryEntrainement,
                                  'series': [],
                                  'exercises': [],
                                },
                                'series': [],
                              } : null,
                            ),
                          ),
                        );
                        refreshSessions();
                      });
                    }
                    cursor++;
                  }
                  if (planned.isNotEmpty && _filter == 'realized') {
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
                            series: p.series.map((s)=> s.toMap()).toList(),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SessionDetailScreen(sessionData: {
                                    'session': p.toMap(),
                                    'series': p.series.map((s)=> s.toMap()).toList(),
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
                  if (_filter == 'planned') {
                    final plannedIndex = index - cursor;
                    if (plannedIndex < 0 || plannedIndex >= planned.length) return SizedBox.shrink();
                    final p = planned[plannedIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                      child: SessionCard(
                        session: p.toMap(),
                        series: p.series.map((s)=> s.toMap()).toList(),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(sessionData: {
                                'session': p.toMap(),
                                'series': p.series.map((s)=> s.toMap()).toList(),
                              }),
                            ),
                          );
                          refreshSessions();
                        },
                      ),
                    );
                  } else {
                    final dayIndex = index - cursor;
                    final day = orderedKeys[dayIndex];
                    final list = grouped[day]!;
                    return _DaySection(day: day, sessions: list, onChanged: refreshSessions, sessionService: _sessionService);
                  }
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

class _PlannedHeader extends StatelessWidget {
  final int totalPlanned;
  final int withDate;
  final int withoutDate;
  final DateTime? nextDate;
  const _PlannedHeader({required this.totalPlanned, required this.withDate, required this.withoutDate, required this.nextDate});
  @override
  Widget build(BuildContext context) {
    String nextLabel = nextDate != null ? '${nextDate!.day}/${nextDate!.month}' : '-';
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
                  Icon(Icons.pending_actions, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Résumé des prévues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.lightBlue[100])),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _Stat(label: 'Total', value: totalPlanned.toString(), icon: Icons.list_alt, color: Colors.blueAccent),
                  _VerticalDivider(),
                  _Stat(label: 'Datées', value: withDate.toString(), icon: Icons.event, color: Colors.indigoAccent),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  _Stat(label: 'Sans date', value: withoutDate.toString(), icon: Icons.help_outline, color: Colors.deepPurpleAccent),
                  _VerticalDivider(),
                  _Stat(label: 'Prochaine', value: nextLabel, icon: Icons.schedule, color: Colors.cyanAccent),
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

class _EmptyMini extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyMini({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, size: 48, color: Colors.white24),
          SizedBox(height: 12),
          Text('Aucune session réalisée', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Ajoute une session pour voir l\'historique.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60)),
          SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onCreate, icon: Icon(Icons.add), label: Text('Créer')),        
        ],
      ),
    );
  }
}
