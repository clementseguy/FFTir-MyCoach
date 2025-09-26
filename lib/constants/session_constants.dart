/// Constantes centralisées pour éviter la répétition de chaînes "magiques".
/// Facilite aussi une future i18n ou une migration de stockage.
class SessionConstants {
  /// Statut : session réalisée / terminée
  static const String statusRealisee = 'réalisée';
  /// Statut : session prévue (non encore effectuée)
  static const String statusPrevue = 'prévue';
  /// Nom de la box Hive pour les sessions
  static const String hiveBoxSessions = 'sessions';
}
