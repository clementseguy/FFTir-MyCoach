import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import '../models/shooting_session.dart';

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

  /// Construit le prompt complet à partir du template et de la session
  String buildPrompt(ShootingSession session) {
    final buffer = StringBuffer();
    buffer.writeln(promptTemplate.trim());
    buffer.writeln('\nSession :');
    buffer.writeln('Arme : ${session.weapon}');
    buffer.writeln('Calibre : ${session.caliber}');
    buffer.writeln('Date : ${session.date?.toIso8601String() ?? 'Non renseignée'}');
    buffer.writeln('Séries :');
    for (var i = 0; i < session.series.length; i++) {
      final s = session.series[i];
      buffer.writeln('- Série ${i + 1} : Coups=${s.shotCount}, Distance=${s.distance}m, Points=${s.points}, Groupement=${s.groupSize}cm, Commentaire=${s.comment}');
    }
    if (session.synthese != null && session.synthese!.trim().isNotEmpty) {
      buffer.writeln('\nSynthèse du tireur :');
      buffer.writeln(session.synthese);
    }
    return buffer.toString();
  }

  /// Appelle l'API Mistral (ou compatible) et retourne le texte d'analyse.
  Future<String> fetchAnalysis(String fullPrompt) async {
    final response = await http.post(
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
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    return data['choices']?[0]?['message']?['content']?.toString() ?? '';
  }

  /// Helper statique pour charger la config et instancier le service
  static Future<CoachAnalysisService> fromAssets({required Future<String> Function(String path) loadAsset}) async {
    final configStr = await loadAsset('assets/config.yaml');
    final config = loadYaml(configStr);
    final apiConfig = config['api'];
    final key = apiConfig['mistral_key'].toString();
    final url = apiConfig['mistral_url'].toString();
    final model = apiConfig['mistral_model'].toString();

    final promptStr = await loadAsset('assets/coach_prompt.yaml');
    final promptYaml = loadYaml(promptStr);
    final promptTemplate = promptYaml['prompt'].toString();

    return CoachAnalysisService(
      apiKey: key,
      apiUrl: url,
      model: model,
      promptTemplate: promptTemplate,
    );
  }
}
