import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final List<dynamic> series;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const SessionCard({required this.session, required this.series, this.onTap, this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
    final bool isPlanned = (session['status'] == 'prévue');
    int totalPoints = 0;
    double avgScore = 0;
    double avgGroup = 0;
    final List<dynamic> exerciseIds = (session['exercises'] is List) ? (session['exercises'] as List) : const [];
    if (series.isNotEmpty) {
      totalPoints = series.fold(0, (sum, s) => sum + ((s['points'] ?? 0) as int));
      avgScore = totalPoints / series.length;
      avgGroup = series.map((s) => (s['group_size'] ?? 0.0) as num).fold(0.0, (a, b) => a + b) / series.length;
    }
    final Color accent = isPlanned ? Colors.blueAccent : Colors.amber;
    final Color badgeColor = isPlanned ? Colors.blueAccent : Colors.green;
    final Color titleColor = isPlanned ? Colors.lightBlue[100]! : Theme.of(context).textTheme.titleMedium?.color ?? Colors.white;
    final Color bgOverlay = isPlanned ? Colors.blueGrey.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06);
    return Card(
      color: bgOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isPlanned ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.white24, width: 0.8),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: accent),
            Text('${date.day}/${date.month}', style: TextStyle(fontSize: 12)),
          ],
        ),
        title: Text(
          '${session['weapon']} [${session['caliber']}] - ${session['category'] ?? ''} - # Séries : ${series.length}' + (isPlanned ? ' (prévue)' : ''),
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score moyen : ${avgScore.toStringAsFixed(1)}', style: TextStyle(color: isPlanned ? Colors.lightBlue[200] : null)),
            Text('Groupement moyen : ${avgGroup.toStringAsFixed(1)} cm', style: TextStyle(color: isPlanned ? Colors.lightBlue[200] : null)),
            if (exerciseIds.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 14, color: badgeColor),
                  SizedBox(width: 4),
                  Text('${exerciseIds.length} exercice(s)', style: TextStyle(fontSize: 12, color: isPlanned ? Colors.lightBlue[200] : null)),
                ],
              ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
