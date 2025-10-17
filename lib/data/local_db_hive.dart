import 'dart:math';
import 'package:hive/hive.dart';
import '../config/app_config.dart';

class LocalDatabaseHive {
  /// Supprime toutes les sessions de la base Hive
  /// Retourne true si l'opération a réussi, false sinon.
  Future<bool> clearAllSessions() async {
    try {
      await _box.clear();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de toutes les sessions: $e');
      return false;
    }
  }

  /// Génère et insère des sessions de tir aléatoires (test/démo) avec règles:
  /// - Séries: entre 3 et 15
  /// - shot_count: <=5 (rarement 6 ou 7 comme exception ~10%)
  /// - points: borné à shot_count * 10
  Future<void> insertRandomSessions({int count = 5, String status = 'réalisée'}) async {
    final random = Random();
    final now = DateTime.now();
    for (int i = 0; i < count; i++) {
      final date = now.subtract(Duration(days: random.nextInt(60)));
      final weapon = ['GLOCK 17', 'DES', 'S&W Trophy'][random.nextInt(3)];
      final caliber = AppConfig.I.calibers[random.nextInt(AppConfig.I.calibers.length)];
      final session = {
        'date': date.toIso8601String(),
        'weapon': weapon,
        'caliber': caliber,
        'status': status,
      };

      final baseCount = 10;
      // 10% chance d'avoir une variation
      final seriesCount =
          random.nextDouble() < 0.1 ? (random.nextDouble() < 0.5 ? baseCount - random.nextInt(3) : baseCount + random.nextInt(3)) : baseCount;
      final List<Map<String, dynamic>> seriesList = [];
      for (int j = 0; j < seriesCount; j++) {
        // Base shot count 4-5
        int shotCount = 4 + random.nextInt(2); // 4,5
        // 5% chance small exception to 6 or 7
        if (random.nextDouble() < 0.05) {
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
          'group_size': (5 + random.nextInt(21)).toDouble(),
          'comment': random.nextBool() ? 'RAS' : '',
          'hand_method': random.nextDouble() < 0.3 ? 'one' : 'two', // 30% une main, 70% deux mains
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

  /// Insère une nouvelle session dans la base de données.
  /// Retourne la clé générée par Hive après insertion.
  Future<dynamic> insertSession(Map<String, dynamic> session, List<Map<String, dynamic>> seriesList) async {
    try {
      // Clone la session pour éviter de modifier l'original directement
      final sessionWithId = Map<String, dynamic>.from(session);
      
      // Utilise put() avec add() si l'ID n'existe pas déjà
      final key = await _box.add('placeholder');
      
      // Stocke la clé Hive dans la session
      sessionWithId['id'] = key;
      
      // Met à jour avec une seule opération d'écriture
      await _box.put(key, {
        'session': sessionWithId,
        'series': seriesList,
      });
      
      return key;
    } catch (e) {
      print('Erreur lors de l\'insertion d\'une session: $e');
      return null; // Valeur de retour en cas d'erreur
    }
  }

  /// Met à jour une session existante dans la base de données.
  /// Retourne true si la mise à jour a réussi, false sinon.
  Future<bool> updateSession(Map<String, dynamic> session, List<Map<String, dynamic>> seriesList) async {
    try {
      final id = session['id'];
      if (id == null) {
        print('Tentative de mise à jour d\'une session sans ID');
        return false;
      }
      
      await _box.put(id, {
        'session': session,
        'series': seriesList,
      });
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la session: $e');
      return false;
    }
  }

  /// Récupère toutes les sessions avec leurs séries depuis la base de données.
  /// Optimisé pour la performance en faisant une seule lecture de la base.
  Future<List<Map<String, dynamic>>> getSessionsWithSeries() async {
    try {
      if (_box.isEmpty) {
        return [];
      }
      
      final List<Map<String, dynamic>> result = [];
      
      for (final item in _box.values) {
        if (item is Map) {
          // Conversion sûre de Map<dynamic, dynamic> en Map<String, dynamic>
          final Map<String, dynamic> typedMap = {};
          item.forEach((key, value) {
            if (key is String) {
              typedMap[key] = value;
            }
          });
          
          if (typedMap.isNotEmpty) {
            result.add(typedMap);
          }
        }
      }
      
      return result;
    } catch (e) {
      print('Erreur lors de la récupération des sessions: $e');
      return [];
    }
  }

  /// Supprime une session spécifique de la base de données.
  /// Retourne true si la suppression a réussi, false sinon.
  Future<bool> deleteSession(int sessionId) async {
    try {
      await _box.delete(sessionId);
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la session $sessionId: $e');
      return false;
    }
  }
}
