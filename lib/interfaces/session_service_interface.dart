import '../models/shooting_session.dart';
import '../models/exercise.dart';
import '../models/series.dart';

/// Interface pour le service de gestion des sessions de tir
abstract class ISessionService {
  /// Récupère toutes les sessions
  Future<List<ShootingSession>> getAllSessions();
  
  /// Ajoute une nouvelle session
  Future<void> addSession(ShootingSession session);
  
  /// Met à jour une session existante
  Future<void> updateSession(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
    bool warnOnFallback = true,
  });
  
  /// Supprime une session par son ID
  Future<void> deleteSession(int id);
  
  /// Supprime toutes les sessions
  Future<void> clearAllSessions();
  
  /// Convertit une session prévue en session réalisée
  Future<ShootingSession> convertPlannedToRealized({
    required ShootingSession session,
    String? weapon,
    String? caliber,
    String? category,
    String? synthese,
    DateTime? forcedDate,
    List<Series>? updatedSeries,
  });
  
  /// Met à jour une série spécifique dans une session prévue
  Future<void> updateSingleSeries(ShootingSession session, int seriesIndex, Series newSeries);
  
  /// Crée une session prévue à partir d'un exercice
  Future<ShootingSession> planFromExercise(Exercise exercise);
}