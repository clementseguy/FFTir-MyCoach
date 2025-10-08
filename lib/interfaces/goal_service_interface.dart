import '../models/goal.dart';

/// Interface pour le service de gestion des objectifs
abstract class IGoalService {
  /// Initialise le service
  Future<void> init();
  
  /// Récupère tous les objectifs
  Future<List<Goal>> listAll();
  
  /// Ajoute un nouvel objectif
  Future<void> addGoal(Goal goal);
  
  /// Met à jour un objectif existant
  Future<void> updateGoal(Goal goal);
  
  /// Supprime un objectif par son ID
  Future<void> deleteGoal(String id);
  
  /// Récupère les N meilleurs objectifs actifs
  Future<List<Goal>> topActiveGoals(int n);
}