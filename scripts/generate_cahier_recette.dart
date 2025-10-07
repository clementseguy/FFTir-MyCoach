// Simple generator: reads docs/specs/cahier_recette.yaml and writes docs/cahier_recette.md
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

  String norm(Object? v) {
    if (v == null) return '';
    var s = v.toString();
    // Strip accidental leading/trailing braces that sometimes appear
    if (s.length >= 2 && s.startsWith('{') && s.endsWith('}')) {
      s = s.substring(1, s.length - 1);
    }
    return s;
  }

  final lastUpdated = data['last_updated'] ?? DateTime.now().toIso8601String();
  final features = (data['features'] as YamlList?) ?? YamlList();

  final buf = StringBuffer();
  buf.writeln('# Cahier de Recette');
  buf.writeln();
  buf.writeln('- Dernière mise à jour: $lastUpdated');
  buf.writeln('- Généré automatiquement depuis `docs/specs/cahier_recette.yaml`');
  buf.writeln();

  for (final f in features) {
    final m = f as YamlMap;
  final id = norm(m['id']);
  final name = norm(m['name']);
  final objectif = norm(m['objectif']);
  final preconditions = ((m['preconditions'] as YamlList?)?.toList() ?? const [])
    .map((e) => norm(e))
    .toList();
  final steps = ((m['steps'] as YamlList?)?.toList() ?? const [])
    .map((e) => norm(e))
    .toList();
  final expected = ((m['expected'] as YamlList?)?.toList() ?? const [])
    .map((e) => norm(e))
    .toList();

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

  final outFile = File('$repoRoot/docs/cahier_recette.md');
  await outFile.writeAsString(buf.toString());
  stdout.writeln('Generated ${outFile.path}');
}
