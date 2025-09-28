import 'package:sqflite/sqflite.dart';

/// Migration logic for NexTarget v0.3 (DB schema version 2).
///
/// Changes introduced:
/// - New table `exercises` to store reusable exercise definitions.
/// - Junction table `session_exercises` to associate exercises with sessions (ordering & contextual note).
/// - (Future) Columns for enriched goals / stats (placeholder comments).
///
/// IMPORTANT:
/// - This migration assumes previous version = 1 (initial schema with `sessions` & `series`).
/// - Safe to run multiple times? We guard using simple existence checks.
///
class MigrationV0_3 {
  static const targetVersion = 2;

  static Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create exercises table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT,
          description TEXT,
          tags TEXT, -- JSON string (list)
          created_at TEXT,
          updated_at TEXT
        );
      ''');

      // Junction table linking sessions <-> exercises (many-to-many with ordering)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            exercise_id INTEGER NOT NULL,
            position INTEGER, -- order inside the session
            note TEXT,
            FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE,
            FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
        );
      ''');

      // (Placeholder) Future alterations for objectives / stats if needed:
      // await db.execute("ALTER TABLE goals ADD COLUMN target_value REAL");
      // etc.
    }
  }
}
