import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// AppConfig charge le fichier YAML `assets/config.yaml` et expose
/// quelques paramètres utiles avec valeurs de repli.
class AppConfig {
  static AppConfig? _instance;
  final int splashMinDisplayMs;
  final int splashFadeDurationMs;

  AppConfig._({
    required this.splashMinDisplayMs,
    required this.splashFadeDurationMs,
  });

  static AppConfig get I {
    final inst = _instance;
    if (inst == null) {
      throw StateError('AppConfig not loaded yet. Call AppConfig.load() in main().');
    }
    return inst;
  }

  static Future<void> load({String path = 'assets/config.yaml'}) async {
    try {
      final raw = await rootBundle.loadString(path);
      final yaml = loadYaml(raw);
      int _readInt(dynamic value, int fallback) {
        if (value == null) return fallback;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? fallback;
        return fallback;
      }
      final splash = yaml['splash'];
      final cfg = AppConfig._(
        splashMinDisplayMs: _readInt(splash?['min_display_ms'], 1500),
        splashFadeDurationMs: _readInt(splash?['fade_duration_ms'], 450),
      );
      _instance = cfg;
    } catch (e) {
      // En cas d'erreur, on installe une config par défaut.
      _instance = AppConfig._(
        splashMinDisplayMs: 1500,
        splashFadeDurationMs: 450,
      );
    }
  }
}
