import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'migrations/v0_3.dart';

class LocalDatabase {
  // Mettre à jour une session et ses séries
  Future<void> updateSession(Map<String, dynamic> session, List<Map<String, dynamic>> seriesList) async {
    final db = await database;
    final sessionId = session['id'];
    if (sessionId == null) return;
    // Mettre à jour la session
    await db.update('sessions', session, where: 'id = ?', whereArgs: [sessionId]);
    // Supprimer les anciennes séries
    await db.delete('series', where: 'session_id = ?', whereArgs: [sessionId]);
    // Insérer les nouvelles séries
    for (final serie in seriesList) {
      serie['session_id'] = sessionId;
      await db.insert('series', serie);
    }
  }
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tir_sportif.db');
    return await openDatabase(
      path,
      version: MigrationV0_3.targetVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            weapon TEXT,
            caliber TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE series (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER,
            shot_count INTEGER,
            distance REAL,
            points INTEGER,
            group_size REAL,
            comment TEXT,
            FOREIGN KEY(session_id) REFERENCES sessions(id)
          );
        ''');
        // If we create directly at latest version, also create new tables.
        if (version >= 2) {
          await MigrationV0_3.upgrade(db, 1, version);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Apply incremental migrations. For now only v2.
        await MigrationV0_3.upgrade(db, oldVersion, newVersion);
      },
    );
  }

  // Insérer une session et ses séries
  Future<int> insertSession(Map<String, dynamic> session, List<Map<String, dynamic>> seriesList) async {
    final db = await database;
    int sessionId = await db.insert('sessions', session);
    for (final serie in seriesList) {
      serie['session_id'] = sessionId;
      await db.insert('series', serie);
    }
    return sessionId;
  }

  // Récupérer les sessions avec leurs séries
  Future<List<Map<String, dynamic>>> getSessionsWithSeries() async {
    final db = await database;
    final sessions = await db.query('sessions', orderBy: 'date DESC');
    List<Map<String, dynamic>> result = [];
    for (final session in sessions) {
      final series = await db.query('series', where: 'session_id = ?', whereArgs: [session['id']]);
      result.add({
        'session': session,
        'series': series,
      });
    }
    return result;
  }

  // Supprimer une session et ses séries
  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete('series', where: 'session_id = ?', whereArgs: [sessionId]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }
}
