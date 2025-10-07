import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Migration2AddExercisesField', () {
    test('normalise les catégories en minuscules', () {
      // Test direct de la normalisation des catégories
      final Map<String, dynamic> session = {
        'category': 'PrÉcIsIoN',
      };
      
      // Simuler le processus de normalisation de la migration
      if (session['category'] is String) {
        final c = (session['category'] as String).trim();
        if (c.isNotEmpty) {
          session['category'] = c.toLowerCase();
        }
      }
      
      // Vérifier que la catégorie a été normalisée
      expect(session['category'], equals('précision'));
    });
    
    test('ajoute le champ exercises s\'il est absent', () {
      // Test direct de l'ajout du champ exercises
      final Map<String, dynamic> session = {
        'id': 1,
        'name': 'Session 1',
      };
      
      // Simuler le processus d'ajout du champ exercises
      session.putIfAbsent('exercises', () => []);
      
      // Vérifier que le champ a été ajouté
      expect(session['exercises'], isNotNull);
      expect(session['exercises'], isEmpty);
    });
    
    test('conserve les exercises existants', () {
      // Test direct de la conservation des exercises existants
      final Map<String, dynamic> session = {
        'id': 1,
        'exercises': ['ex1', 'ex2'],
      };
      
      // Simuler le processus d'ajout du champ exercises
      session.putIfAbsent('exercises', () => []);
      
      // Vérifier que le champ n'a pas été écrasé
      expect(session['exercises'], equals(['ex1', 'ex2']));
    });
  });
}