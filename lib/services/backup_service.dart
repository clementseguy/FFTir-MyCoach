import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/shooting_session.dart';
import '../services/session_service.dart';

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

  Future<File> exportAllSessionsToJsonFile() async {
    final sessions = await _sessionService.getAllSessions();
    final data = {
      'format': 'mycoach-sessions',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'count': sessions.length,
      'sessions': sessions.map((s) => s.toMap()).toList(),
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
    if (decoded['format'] != 'mycoach-sessions') {
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
    return imported;
  }
}
