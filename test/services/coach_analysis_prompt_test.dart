import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/coach_analysis_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';

void main() {
  test('CoachAnalysisService.buildPrompt includes ordered series and synthese', () {
    final service = CoachAnalysisService(apiKey: 'k', apiUrl: 'http://x', model: 'm', promptTemplate: 'En tant que coach:');
    final session = ShootingSession(
      weapon: 'Pistolet', caliber: '22LR',
      date: DateTime(2025, 10, 7, 12),
      series: [
        Series(id: 2, distance: 10, points: 20, groupSize: 25, comment: 'B'),
        Series(id: 1, distance: 10, points: 10, groupSize: 30, comment: 'A'),
      ],
      synthese: 'Bonne séance',
    );
    final prompt = service.buildPrompt(session);
    expect(prompt.contains('En tant que coach:'), isTrue);
    // Series should be ordered by id: 1 then 2
    final idxA = prompt.indexOf('Série 1');
    final idxB = prompt.indexOf('Série 2');
    expect(idxA >= 0 && idxB > idxA, isTrue);
    expect(prompt.contains('Synthèse du tireur'), isTrue);
    expect(prompt.contains('Bonne séance'), isTrue);
  });
}
