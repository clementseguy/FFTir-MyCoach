import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/forms/series_form_data.dart';

void main() {
  group('SeriesFormData', () {
    test('initialise avec les valeurs par défaut', () {
      final formData = SeriesFormData();
      
      expect(formData.shotCount, 5);
      expect(formData.distance, 0);
      expect(formData.points, 0);
      expect(formData.groupSize, 0);
      expect(formData.comment, '');
    });
    
    test('initialise avec les valeurs fournies', () {
      final formData = SeriesFormData(
        shotCount: 10,
        distance: 25,
        points: 95,
        groupSize: 8.5,
        comment: 'Test comment',
      );
      
      expect(formData.shotCount, 10);
      expect(formData.distance, 25);
      expect(formData.points, 95);
      expect(formData.groupSize, 8.5);
      expect(formData.comment, 'Test comment');
    });
  });
}