import 'package:hive/hive.dart';
import 'migration.dart';

/// Migration v2: ensure each session map has an 'exercises' key (empty list if absent)
/// and normalize 'category' to lowercase baseline values.
class Migration2AddExercisesField extends HiveMigration {
  @override
  int get toVersion => 2;

  @override
  Future<void> apply() async {
    // Sessions stored in 'sessions' box as maps {session: {...}, series: [...]}
    if (!Hive.isBoxOpen('sessions')) return; // nothing to do if not opened yet
    final box = Hive.box('sessions');
    final keys = box.keys.toList();
    for (final k in keys) {
      final raw = box.get(k);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final session = Map<String, dynamic>.from(map['session']);
        // Add exercises key if missing
        session.putIfAbsent('exercises', () => []);
        // Normalize category (if any)
        if (session['category'] is String) {
          final c = (session['category'] as String).trim();
          if (c.isNotEmpty) {
            session['category'] = c.toLowerCase();
          }
        }
        map['session'] = session;
        await box.put(k, map);
      }
    }
  }
}
