import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/shooting_session.dart';
import '../services/session_service.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

/// Service pour exporter / importer toutes les sessions sous forme JSON plat
/// Structure de fichier:
/// {
///   "format": "mycoach-sessions",
///   "version": 1,
///   "exported_at": "2025-09-27T12:00:00Z",
///   "count": N,
///   "sessions": [ { sessionMap... }, ... ]
/// }
class BackupService {
  final SessionService _sessionService = SessionService();
  final GoalService _goalService = GoalService();

  Future<File> exportAllSessionsToJsonFile() async {
    final sessions = await _sessionService.getAllSessions();
    await _goalService.init();
    final goals = await _goalService.listAll();
    final data = {
      'format': 'mycoach-data',
      'version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'sessions_count': sessions.length,
      'goals_count': goals.length,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'goals': goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'metric': g.metric.index,
        'comparator': g.comparator.index,
        'targetValue': g.targetValue,
        'status': g.status.index,
        'period': g.period.index,
        'createdAt': g.createdAt.toIso8601String(),
        'updatedAt': g.updatedAt.toIso8601String(),
        'lastProgress': g.lastProgress,
        'lastMeasuredValue': g.lastMeasuredValue,
        'priority': g.priority,
      }).toList(),
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sessions_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
    return file;
  }

  /// Importe les sessions depuis une chaîne JSON.
  /// - Les IDs existants sont ignorés pour éviter collisions: on remet id=null (laisser DB attribuer / conserver logique actuelle)
  /// - Retourne le nombre de sessions importées.
  Future<int> importSessionsFromJson(String jsonContent) async {
    final decoded = json.decode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Fichier invalide (structure racine).');
    }
    if (decoded['format'] != 'mycoach-data') {
      throw FormatException('Format non reconnu.');
    }
    final sessionsRaw = decoded['sessions'];
    if (sessionsRaw is! List) {
      throw FormatException('Section sessions manquante.');
    }
    int imported = 0;
    for (final item in sessionsRaw) {
      if (item is! Map) continue;
  final map = Map<String, dynamic>.from(item);
      // Forcer id null pour éviter écrasement
      map['id'] = null;
      // Normaliser séries si besoin
      if (map['series'] is List) {
        map['series'] = (map['series'] as List).map((e) => e is Map ? Map<String,dynamic>.from(e) : e).toList();
      }
      try {
        final session = ShootingSession.fromMap(map);
        // (session.series déjà instanciées)
        await _sessionService.addSession(session);
        imported++;
      } catch (_) {
        // ignorer session invalide
      }
    }
    // Import goals (facultatif si absent - compat ascendante)
    try {
      await _goalService.init();
      final goalsRaw = decoded['goals'];
      if (goalsRaw is List) {
        for (final g in goalsRaw) {
          if (g is! Map) continue;
          try {
            final goal = Goal(
              id: g['id']?.toString(),
              title: g['title']?.toString() ?? 'Sans titre',
              description: g['description']?.toString(),
              metric: GoalMetric.values[(g['metric'] as num?)?.toInt() ?? 0],
              comparator: GoalComparator.values[(g['comparator'] as num?)?.toInt() ?? 0],
              targetValue: (g['targetValue'] as num?)?.toDouble() ?? 0,
              status: GoalStatus.values[(g['status'] as num?)?.toInt() ?? 0],
              period: GoalPeriod.values[(g['period'] as num?)?.toInt() ?? 0],
              createdAt: DateTime.tryParse(g['createdAt'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(g['updatedAt'] ?? '') ?? DateTime.now(),
              lastProgress: (g['lastProgress'] as num?)?.toDouble(),
              lastMeasuredValue: (g['lastMeasuredValue'] as num?)?.toDouble(),
              priority: (g['priority'] as num?)?.toInt(),
            );
            await _goalService.addGoal(goal);
          } catch (_) {
            // ignore invalid goal
          }
        }
      }
    } catch (_) {}
    return imported;
  }
}
