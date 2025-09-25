import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final List<dynamic> series;
  final VoidCallback? onTap;
  const SessionCard({required this.session, required this.series, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
    int totalPoints = 0;
    double avgGroup = 0;
    if (series.isNotEmpty) {
      totalPoints = series.fold(0, (sum, s) => sum + ((s['points'] ?? 0) as int));
      avgGroup = series.map((s) => (s['group_size'] ?? 0.0) as num).fold(0.0, (a, b) => a + b) / series.length;
    }
    return Card(
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: Colors.amber),
            Text('${date.day}/${date.month}', style: TextStyle(fontSize: 12)),
          ],
        ),
        title: Text('Arme: ${session['weapon']} | Calibre: ${session['caliber']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score total : $totalPoints'),
            Text('Groupement moyen : ${avgGroup.toStringAsFixed(1)} cm'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
