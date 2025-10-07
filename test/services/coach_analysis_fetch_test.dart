import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tir_sportif/services/coach_analysis_service.dart';

void main() {
  test('fetchAnalysis success returns content', () async {
    final client = MockClient((req) async => http.Response('{"choices":[{"message":{"content":"OK"}}]}', 200));
    final svc = CoachAnalysisService(apiKey: 'k', apiUrl: 'http://x', model: 'm', promptTemplate: 'p', client: client);
    final out = await svc.fetchAnalysis('prompt');
    expect(out, 'OK');
  });

  test('fetchAnalysis 401 throws CoachAnalysisException', () async {
    final client = MockClient((req) async => http.Response('unauthorized', 401));
    final svc = CoachAnalysisService(apiKey: 'k', apiUrl: 'http://x', model: 'm', promptTemplate: 'p', client: client);
    expect(()=> svc.fetchAnalysis('p'), throwsA(predicate((e)=> e.toString().contains('Clé API invalide'))));
  });

  test('fetchAnalysis 429 and 500 throw user-friendly messages', () async {
    final client429 = MockClient((req) async => http.Response('too many', 429));
    final svc429 = CoachAnalysisService(apiKey: 'k', apiUrl: 'http://x', model: 'm', promptTemplate: 'p', client: client429);
    expect(()=> svc429.fetchAnalysis('p'), throwsA(predicate((e)=> e.toString().contains('Trop de requêtes'))));

    final client500 = MockClient((req) async => http.Response('server error', 503));
    final svc500 = CoachAnalysisService(apiKey: 'k', apiUrl: 'http://x', model: 'm', promptTemplate: 'p', client: client500);
    expect(()=> svc500.fetchAnalysis('p'), throwsA(predicate((e)=> e.toString().contains('Erreur serveur'))));
  });

  test('fetchAnalysis malformed content throws', () async {
    final client = MockClient((req) async => http.Response('{"choices":[{"message":{}}]}', 200));
    final svc = CoachAnalysisService(apiKey: 'k', apiUrl: 'http://x', model: 'm', promptTemplate: 'p', client: client);
    expect(()=> svc.fetchAnalysis('p'), throwsA(predicate((e)=> e.toString().contains('Réponse vide'))));
  });
}
