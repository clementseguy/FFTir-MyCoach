import 'dart:math';
import 'package:hive/hive.dart';

class LocalDatabaseHive {
  /// Supprime toutes les sessions de la base Hive
  Future<void> clearAllSessions() async {
    await _box.clear();
  }

  /// Génère et insère 25 sessions de tir aléatoires en base (pour démo/tests)
  Future<void> insertRandomSessions({int count = 25, String status = 'réalisée'}) async {
    final random = Random();
    final now = DateTime.now();
    for (int i = 0; i < count; i++) {
      final date = now.subtract(Duration(days: random.nextInt(180)));
      final weapon = ['Pistolet', 'Carabine', 'Revolver'][random.nextInt(3)];
      final caliber = ['22LR', '9mm', '4.5mm'][random.nextInt(3)];
      final session = {
        'date': date.toIso8601String(),
        'weapon': weapon,
        'caliber': caliber,
        'status': status,
      };
      // 1 à 4 séries par session
      final seriesCount = 1 + random.nextInt(4);
      final List<Map<String, dynamic>> seriesList = List.generate(seriesCount, (j) {
        return {
          'shot_count': 5 + random.nextInt(6),
          'distance': [10, 25, 50][random.nextInt(3)],
          'points': 40 + random.nextInt(61),
          'group_size': (5 + random.nextInt(26)).toDouble(),
          'comment': random.nextBool() ? 'RAS' : '',
        };
      });
      await insertSession(session, seriesList);
    }
  }
  static final LocalDatabaseHive _instance = LocalDatabaseHive._internal();
  factory LocalDatabaseHive() => _instance;
  LocalDatabaseHive._internal();

  final String _boxName = 'sessions';

  Box<dynamic> get _box => Hive.box(_boxName);

  Future<void> insertSession(Map<String, dynamic> session, List<Map<String, dynamic>> seriesList) async {
  // (sessions inutilisé)
    // Utilise add() pour une clé auto-incrémentée compatible web
    final key = await _box.add({
      'session': session,
      'series': seriesList,
    });
    // Stocke la clé Hive dans la session pour update/delete
    final sessionWithId = Map<String, dynamic>.from(session);
    sessionWithId['id'] = key;
    await _box.put(key, {
      'session': sessionWithId,
      'series': seriesList,
    });
  }

  Future<void> updateSession(Map<String, dynamic> session, List<Map<String, dynamic>> seriesList) async {
    final id = session['id'];
    if (id == null) return;
    _box.put(id, {
      'session': session,
      'series': seriesList,
    });
  }

  Future<List<Map<String, dynamic>>> getSessionsWithSeries() async {
    return _box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> deleteSession(int sessionId) async {
    await _box.delete(sessionId);
  }
}
