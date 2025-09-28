import 'package:hive/hive.dart';

/// Base contract for a migration.
abstract class HiveMigration {
  int get toVersion; // target schema version after applying this migration
  Future<void> apply();
}

/// Simple key/value storage of current schema version in a dedicated box.
class SchemaVersionStore {
  static const _boxName = '_schema_meta';
  static const _key = 'schema_version';
  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Future<int> readVersion() async {
    await init();
    return (_box!.get(_key) as int?) ?? 1; // default baseline version = 1
  }

  Future<void> writeVersion(int v) async {
    await init();
    await _box!.put(_key, v);
  }
}

class MigrationRunner {
  final List<HiveMigration> _migrations;
  final SchemaVersionStore _store;

  MigrationRunner(this._migrations, this._store);

  Future<void> run() async {
    final current = await _store.readVersion();
    // Sort migrations by target version to ensure order
    _migrations.sort((a, b) => a.toVersion.compareTo(b.toVersion));
    int appliedVersion = current;
    for (final m in _migrations) {
      if (m.toVersion > appliedVersion) {
        await m.apply();
        appliedVersion = m.toVersion;
        await _store.writeVersion(appliedVersion);
      }
    }
  }
}
