import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/coach_analysis_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';

void main() {
  group('CoachAnalysisService.buildPrompt ordering', () {
    test('keeps insertion order when ids missing', () {
      final session = ShootingSession(
        weapon: 'Pistolet',
        caliber: '9mm',
        series: [
          Series(distance: 25, points: 50, groupSize: 6, shotCount: 5, comment: 'A'),
          Series(distance: 25, points: 55, groupSize: 5, shotCount: 5, comment: 'B'),
          Series(distance: 25, points: 60, groupSize: 4, shotCount: 5, comment: 'C'),
        ],
      );
      final service = CoachAnalysisService(
        apiKey: 'dummy',
        apiUrl: 'http://dummy',
        model: 'dummy-model',
        promptTemplate: 'Analyse Coach',
      );
      final prompt = service.buildPrompt(session);
      final indexA = prompt.indexOf('Série 1');
      final indexB = prompt.indexOf('Série 2');
      final indexC = prompt.indexOf('Série 3');
      expect(indexA < indexB && indexB < indexC, true);
    });

    test('sorts by id when all ids present but inserted shuffled', () {
      final s1 = Series(id: 10, distance: 25, points: 60, groupSize: 4, shotCount: 5, comment: 'C');
      final s2 = Series(id: 2, distance: 25, points: 50, groupSize: 6, shotCount: 5, comment: 'A');
      final s3 = Series(id: 5, distance: 25, points: 55, groupSize: 5, shotCount: 5, comment: 'B');
      final session = ShootingSession(
        weapon: 'Pistolet',
        caliber: '9mm',
        series: [s1, s2, s3],
      );
      final service = CoachAnalysisService(
        apiKey: 'dummy',
        apiUrl: 'http://dummy',
        model: 'dummy-model',
        promptTemplate: 'Analyse Coach',
      );
      final prompt = service.buildPrompt(session);
      // After sorting by id ascending: ids 2 (A),5 (B),10 (C) => Série 1:A, Série 2:B, Série 3:C
  // Vérifier ordre via les segments 'Commentaire=A/B/C' pour éviter collisions.
  final posA = prompt.indexOf('Commentaire=A');
  final posB = prompt.indexOf('Commentaire=B');
  final posC = prompt.indexOf('Commentaire=C');
  expect(posA != -1 && posB != -1 && posC != -1, true, reason: 'Segments commentaire non trouvés');
  expect(posA < posB && posB < posC, true, reason: 'Expected A -> B -> C order');
    });
  });
}
