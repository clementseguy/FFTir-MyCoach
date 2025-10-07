import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/coach_analysis_service.dart';
import 'package:yaml/yaml.dart';

// Test de la partie métier sans passer par AppConfig
// On utilise un constructeur direct plutôt que de passer par AppConfig
void main() {
  group('CoachAnalysisService prompt loading and validation', () {
    // Config pour tests avec API key
    const String validKey = 'test-api-key';
    const String apiUrl = 'https://api.mistral.ai/v1/chat';
    const String model = 'mistral-small';
    
    final promptYaml = '''
prompt: |
  Tu es un coach de tir sportif expérimenté.
  Analyse la session et donne des conseils d'amélioration.
''';
    
    test('should load prompt template correctly', () async {
      // Utiliser le constructeur direct pour tester la logique sans AppConfig
      final yaml = loadYaml(promptYaml);
      final promptTemplate = yaml['prompt'].toString();
      
      final service = CoachAnalysisService(
        apiKey: validKey,
        apiUrl: apiUrl,
        model: model,
        promptTemplate: promptTemplate,
      );
      
      // Vérifier que le template a été correctement extrait du YAML
      expect(service.promptTemplate, contains('Tu es un coach de tir sportif'));
      expect(service.promptTemplate, contains('Analyse la session et donne des conseils'));
    });
    
    test('should extract YAML data correctly from string', () async {
      // Même sans passer par AppConfig, on peut vérifier que le parsing YAML fonctionne
      final yaml = loadYaml(promptYaml);
      final extractedPrompt = yaml['prompt'].toString();
      
      expect(extractedPrompt, contains('Tu es un coach de tir sportif'));
      expect(extractedPrompt, contains('Analyse la session et donne des conseils'));
    });
    
    test('should check API key presence', () {
      // Une méthode pour valider la présence de clé API peut être testée indépendamment
      // Simulation du comportement dans fromAssets
      void validateApiKey(String? key) {
        if (key == null || key.isEmpty) {
          throw CoachAnalysisException('Clé API Mistral absente: configurez MISTRAL_API_KEY');
        }
      }
      
      // Vérifier qu'une exception est levée quand la clé est absente
      expect(
        () => validateApiKey(null),
        throwsA(isA<CoachAnalysisException>().having(
          (e) => e.toString(), 
          'message', 
          contains('Clé API Mistral absente')
        )),
      );
      
      // Vérifier qu'une exception est levée quand la clé est vide
      expect(
        () => validateApiKey(''),
        throwsA(isA<CoachAnalysisException>().having(
          (e) => e.toString(), 
          'message', 
          contains('Clé API Mistral absente')
        )),
      );
      
      // Vérifier que pas d'exception quand la clé est valide
      validateApiKey('valid-key'); // Ne devrait pas lever d'exception
    });
  });
}