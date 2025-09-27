import 'dart:math';
import 'package:hive/hive.dart';

class LocalDatabaseHive {
  /// Supprime toutes les sessions de la base Hive
  Future<void> clearAllSessions() async {
    await _box.clear();
  }

  /// Génère et insère des sessions de tir aléatoires (test/démo) avec règles:
  /// - Séries: entre 3 et 15
  /// - shot_count: <=5 (rarement 6 ou 7 comme exception ~10%)
  /// - points: borné à shot_count * 10
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

      final seriesCount = 3 + random.nextInt(13); // 3..15
      final List<Map<String, dynamic>> seriesList = [];
      for (int j = 0; j < seriesCount; j++) {
        // Base shot count 3-5
        int shotCount = 3 + random.nextInt(3); // 3,4,5
        // 10% chance small exception to 6 or 7
        if (random.nextDouble() < 0.10) {
          shotCount = 6 + random.nextInt(2); // 6 ou 7
        }
        final maxPoints = shotCount * 10;
        // Générer une distribution réaliste: points autour de 65-95% du max
        final base = (maxPoints * (0.65 + random.nextDouble() * 0.30)).round();
        final points = base.clamp(0, maxPoints);
        seriesList.add({
          'shot_count': shotCount,
          'distance': [10, 25, 50][random.nextInt(3)],
          'points': points,
          'group_size': (5 + random.nextInt(26)).toDouble(),
          'comment': random.nextBool() ? 'RAS' : '',
        });
      }
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
