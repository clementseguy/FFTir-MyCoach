import 'package:flutter/material.dart';

/// Provider pour gérer la navigation principale de l'application
class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 2; // Par défaut: tableau de bord
  
  /// Index de la page actuellement sélectionnée
  int get selectedIndex => _selectedIndex;
  
  /// Pour la compatibilité avec AppRouter (alias de selectedIndex)
  int get currentIndex => _selectedIndex;
  
  /// Définir la page actuellement sélectionnée
  set selectedIndex(int index) {
    if (index != _selectedIndex && index >= 0 && index <= 4) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
  
  /// Changer l'index courant (pour AppRouter)
  void changeIndex(int index) {
    selectedIndex = index;
  }
  
  /// Naviguer vers la page d'accueil
  void goToHome() {
    selectedIndex = 2;
  }
  
  /// Naviguer vers la page des sessions
  void goToSessions() {
    selectedIndex = 3;
  }
  
  /// Naviguer vers la page des exercices
  void goToExercises() {
    selectedIndex = 1;
  }
  
  /// Naviguer vers la page de coach
  void goToCoach() {
    selectedIndex = 0;
  }
  
  /// Naviguer vers la page des paramètres
  void goToSettings() {
    selectedIndex = 4;
  }
}