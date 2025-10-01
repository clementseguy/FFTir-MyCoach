import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import '../models/shooting_session.dart';
import '../config/app_config.dart';

/// Service responsable de :
///  - Charger la configuration d'API (clé, modèle, url) via fromAssets
///  - Construire le prompt d'analyse à partir d'une session
///  - Appeler le modèle distant pour obtenir l'analyse du coach
///  - Fournir une gestion d'erreurs basique et un timeout
class CoachAnalysisService {
  final String apiKey;
  final String apiUrl;
  final String model;
  final String promptTemplate; // Contenu de coach_prompt.yaml -> key 'prompt'

  CoachAnalysisService({
    required this.apiKey,
    required this.apiUrl,
    required this.model,
    required this.promptTemplate,
  });

  /// Construit le prompt complet à partir du template et de la session.
  /// Idempotent / sans effet de bord.
  String buildPrompt(ShootingSession session) {
    final buffer = StringBuffer();
    buffer.writeln(promptTemplate.trim());
    buffer.writeln('\nSession :');
    buffer.writeln('Arme : ${session.weapon}');
    buffer.writeln('Calibre : ${session.caliber}');
    buffer.writeln('Date : ${session.date?.toIso8601String() ?? 'Non renseignée'}');
    buffer.writeln('Séries :');
    // Assurer l'ordre logique des séries :
    // 1. Si les IDs sont présents, on trie par id croissant.
    // 2. Sinon on conserve l'ordre existant (index original).
    final indexed = <int, dynamic>{};
    for (var i = 0; i < session.series.length; i++) {
      indexed[i] = session.series[i];
    }
    final ordered = session.series.toList();
    final hasAllIds = ordered.every((s) => s.id != null);
    if (hasAllIds) {
      ordered.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    }
    for (var i = 0; i < ordered.length; i++) {
      final s = ordered[i];
      buffer.writeln('- Série ${i + 1} : Coups=${s.shotCount}, Distance=${s.distance}m, Points=${s.points}, Groupement=${s.groupSize}cm, Commentaire=${s.comment}');
    }
    if (session.synthese != null && session.synthese!.trim().isNotEmpty) {
      buffer.writeln('\nSynthèse du tireur :');
      buffer.writeln(session.synthese);
    }
    return buffer.toString();
  }

  /// Appelle l'API Mistral (ou compatible) et retourne le texte d'analyse.
  /// Lève une Exception avec un message user-friendly en cas d'erreur.
  Future<String> fetchAnalysis(String fullPrompt) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': fullPrompt}
              ]
            }),
          )
          // Timeout augmenté pour réduire les erreurs dues aux prompts plus longs / modèle plus lent
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw CoachAnalysisException('Le serveur ne répond pas (timeout).');
    } on SocketException catch (e) {
      // Résout notamment: Failed host lookup (DNS) ou absence réseau
      throw CoachAnalysisException('Connexion impossible (réseau ou DNS): ${e.message}');
    } catch (e) {
      throw CoachAnalysisException('Erreur réseau inattendue: $e');
    }

    if (response.statusCode == 401) {
      throw CoachAnalysisException('Clé API invalide (401).');
    }
    if (response.statusCode == 429) {
      throw CoachAnalysisException('Trop de requêtes (429), réessayez plus tard.');
    }
    if (response.statusCode >= 500) {
      throw CoachAnalysisException('Erreur serveur (${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoachAnalysisException('Erreur HTTP ${response.statusCode}.');
    }

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content']?.toString();
    if (content == null || content.trim().isEmpty) {
      throw CoachAnalysisException('Réponse vide du modèle.');
    }
    return content;
  }

  /// Helper statique pour charger la config et instancier le service.
  /// Permet d'injecter un loader custom (utile pour tests plus tard).
  static Future<CoachAnalysisService> fromAssets({required Future<String> Function(String path) loadAsset}) async {
    // AppConfig doit être chargé dans main() déjà.
    final cfg = AppConfig.I;
    final promptStr = await loadAsset('assets/coach_prompt.yaml');
    final promptYaml = loadYaml(promptStr);
    final promptTemplate = promptYaml['prompt'].toString();
    if (cfg.mistralKey == null) {
      throw CoachAnalysisException('Clé API Mistral absente: configurez MISTRAL_API_KEY (dart-define, env ou config.local.yaml).');
    }
    return CoachAnalysisService(
      apiKey: cfg.mistralKey!,
      apiUrl: cfg.mistralUrl,
      model: cfg.mistralModel,
      promptTemplate: promptTemplate,
    );
  }
}

/// Exception dédiée pour distinguer les erreurs d'analyse.
class CoachAnalysisException implements Exception {
  final String message;
  CoachAnalysisException(this.message);
  @override
  String toString() => 'CoachAnalysisException: $message';
}
