// Simple generator: reads docs/specs/cahier_recette.yaml and writes docs/cahier_recette_v0.4.md
import 'dart:io';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  final repoRoot = Directory.current.path;
  final yamlFile = File('$repoRoot/docs/specs/cahier_recette.yaml');
  if (!await yamlFile.exists()) {
    stderr.writeln('YAML not found: ${yamlFile.path}');
    exit(1);
  }
  final yamlContent = await yamlFile.readAsString();
  final data = loadYaml(yamlContent) as YamlMap;

  final version = data['version'] ?? 'v0.4';
  final lastUpdated = data['last_updated'] ?? DateTime.now().toIso8601String();
  final features = (data['features'] as YamlList?) ?? YamlList();

  final buf = StringBuffer();
  buf.writeln('# Cahier de Recette $version');
  buf.writeln();
  buf.writeln('- Dernière mise à jour: $lastUpdated');
  buf.writeln('- Généré automatiquement depuis `docs/specs/cahier_recette.yaml`');
  buf.writeln();

  for (final f in features) {
    final m = f as YamlMap;
    final id = m['id'] ?? '';
    final name = m['name'] ?? '';
    final objectif = m['objectif'] ?? '';
    final preconditions = (m['preconditions'] as YamlList?)?.cast() ?? const [];
    final steps = (m['steps'] as YamlList?)?.cast() ?? const [];
    final expected = (m['expected'] as YamlList?)?.cast() ?? const [];

    buf.writeln('## $id — $name');
    if (objectif.toString().isNotEmpty) {
      buf.writeln('Objectif: $objectif');
    }
    if (preconditions.isNotEmpty) {
      buf.writeln('Pré-requis:');
      for (final p in preconditions) {
        buf.writeln('- $p');
      }
    }
    if (steps.isNotEmpty) {
      buf.writeln('Étapes:');
      var i = 1;
      for (final s in steps) {
        buf.writeln('$i. $s');
        i++;
      }
    }
    if (expected.isNotEmpty) {
      buf.writeln('Résultats attendus:');
      for (final e in expected) {
        buf.writeln('- $e');
      }
    }
    buf.writeln();
  }

  final outFile = File('$repoRoot/docs/cahier_recette_v0.4.md');
  await outFile.writeAsString(buf.toString());
  stdout.writeln('Generated ${outFile.path}');
}
