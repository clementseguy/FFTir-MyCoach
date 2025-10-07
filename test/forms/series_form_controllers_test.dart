import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/forms/series_form_controllers.dart';

void main() {
  group('SeriesFormControllers', () {
    test('initialise les controllers avec les valeurs fournies', () {
      final controllers = SeriesFormControllers(
        shotCount: 10,
        distance: 25.0,
        points: 95,
        groupSize: 8.5,
        comment: 'Test comment',
        handMethod: 'two',
      );
      
      // Vérifier les valeurs des contrôleurs
      expect(controllers.shotCountController.text, '10');
      expect(controllers.distanceController.text, '25.0');
      expect(controllers.pointsController.text, '95');
      expect(controllers.groupSizeController.text, '8.5');
      expect(controllers.commentController.text, 'Test comment');
      expect(controllers.handMethod, 'two');
      
      // Vérifier que les focus nodes sont créés
      expect(controllers.shotCountFocus, isA<FocusNode>());
      expect(controllers.distanceFocus, isA<FocusNode>());
      expect(controllers.pointsFocus, isA<FocusNode>());
      expect(controllers.groupSizeFocus, isA<FocusNode>());
      expect(controllers.commentFocus, isA<FocusNode>());
    });
    
    test('initialise les controllers avec des valeurs numériques zéro', () {
      final controllers = SeriesFormControllers(
        shotCount: 0,
        distance: 0.0,
        points: 0,
        groupSize: 0.0,
        comment: '',
        handMethod: 'one',
      );
      
      expect(controllers.shotCountController.text, '0');
      expect(controllers.distanceController.text, '0.0');
      expect(controllers.pointsController.text, '0');
      expect(controllers.groupSizeController.text, '0');
      expect(controllers.commentController.text, '');
      expect(controllers.handMethod, 'one');
    });
    
    test('dispose libère les ressources correctement', () {
      // Créer le contrôleur
      final controllers = SeriesFormControllers(
        shotCount: 5,
        distance: 10.0,
        points: 50,
        groupSize: 5.0,
        comment: '',
        handMethod: 'two',
      );
      
      // Vérifier qu'il n'y a pas d'erreur lors de l'appel à dispose
      expect(() => controllers.dispose(), returnsNormally);
      
      // Note: nous ne pouvons pas facilement tester si un controller a été
      // correctement disposé car Flutter ne fournit pas de moyen de vérifier
      // l'état interne d'un contrôleur après dispose.
    });
  });
}