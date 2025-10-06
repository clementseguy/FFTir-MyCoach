import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// AppConfig charge le fichier YAML `assets/config.yaml` et expose
/// quelques paramètres utiles avec valeurs de repli.
class AppConfig {
  static AppConfig? _instance;
  final int splashMinDisplayMs;
  final int splashFadeDurationMs;
  final String? mistralKey;
  final String mistralUrl;
  final String mistralModel;
  final List<String> calibers;

  AppConfig._({
    required this.splashMinDisplayMs,
    required this.splashFadeDurationMs,
    required this.mistralKey,
    required this.mistralUrl,
    required this.mistralModel,
    required this.calibers,
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

      // Option: fichier local non versionné pour surcharges
      Map local = {};
      try {
        final localRaw = await rootBundle.loadString('assets/config.local.yaml');
        local = loadYaml(localRaw) as Map;
      } catch (_) {}

      int _readInt(dynamic value, int fallback) {
        if (value == null) return fallback;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? fallback;
        return fallback;
      }
      final splash = yaml['splash'];
      final api = yaml['api'] ?? {};
      final apiLocal = local['api'] ?? {};
      final calibersYaml = (local['calibers'] ?? yaml['calibers']) as dynamic;
      final defaultCalibers = <String>[
        '.22 LR',
        '.32 S&W Long',
        '9mm (9x19)',
        '.38 Special',
        '.357 Magnum',
        '.380 ACP',
        '.40 S&W',
        '.45 ACP',
        'Autre',
      ];
      List<String> _readCalibers(dynamic val) {
        if (val == null) return defaultCalibers;
        if (val is Iterable) {
          return val.map((e) => e.toString()).toList();
        }
        return defaultCalibers;
      }

      String? _selectKey() {
        // Priorité: --dart-define > fichier local > env var > config.yaml > placeholder => null
        // --dart-define injecté via const String.fromEnvironment
        const defineKey = String.fromEnvironment('MISTRAL_API_KEY');
        if (defineKey.isNotEmpty && !defineKey.contains('PLACEHOLDER')) return defineKey;
        final localKey = apiLocal['mistral_key'];
        if (localKey != null && localKey.toString().isNotEmpty && !localKey.toString().contains('PLACEHOLDER')) {
          return localKey.toString();
        }
        // Variable env (surtout utile en CLI / tests) - non dispo sur web
        final envKey = !kIsWeb ? Platform.environment['MISTRAL_API_KEY'] : null;
        if (envKey != null && envKey.isNotEmpty && !envKey.contains('PLACEHOLDER')) return envKey;
        final yamlKey = api['mistral_key'];
        if (yamlKey != null && yamlKey.toString().isNotEmpty && !yamlKey.toString().contains('PLACEHOLDER')) {
          return yamlKey.toString();
        }
        return null; // pas de clé valide trouvée
      }

      final cfg = AppConfig._(
        splashMinDisplayMs: _readInt(splash?['min_display_ms'], 1500),
        splashFadeDurationMs: _readInt(splash?['fade_duration_ms'], 450),
        mistralKey: _selectKey(),
        mistralUrl: (api['mistral_url'] ?? 'https://api.mistral.ai/v1/chat/completions').toString(),
        mistralModel: (api['mistral_model'] ?? 'mistral-tiny').toString(),
        calibers: _readCalibers(calibersYaml),
      );
      _instance = cfg;
    } catch (e) {
      // En cas d'erreur, on installe une config par défaut.
      _instance = AppConfig._(
        splashMinDisplayMs: 1500,
        splashFadeDurationMs: 450,
        mistralKey: null,
        mistralUrl: 'https://api.mistral.ai/v1/chat/completions',
        mistralModel: 'mistral-tiny',
        calibers: const [
          '.22 LR',
          '.32 S&W Long',
          '9mm (9x19)',
          '.38 Special',
          '.357 Magnum',
          '.380 ACP',
          '.40 S&W',
          '.45 ACP',
          'Autre',
        ],
      );
    }
  }
}
