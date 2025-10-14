import 'package:flutter/material.dart';

/// Utilitaire pour détecter et adapter l'interface aux appareils mobiles
class MobileUtils {
  /// Détecte si l'appareil est mobile (basé sur la largeur d'écran)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }
  
  /// Détecte si l'appareil est une tablette
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }
  
  /// Détecte si l'appareil est desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  /// Détecte si l'appareil supporte le touch (mobile/tablette)
  static bool isTouchDevice(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }
  
  /// Retourne la hauteur appropriée pour les cartes selon la plateforme
  static double getCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return 100; // Réduit pour mobile
    } else if (isTablet(context)) {
      return 120; // Standard pour tablette
    } else {
      return 140; // Plus grand pour desktop
    }
  }
  
  /// Retourne l'espacement approprié selon la plateforme
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0; // Moins d'espace sur mobile
    } else {
      return 16.0; // Espacement standard
    }
  }
  
  /// Configure les interactions tactiles pour les graphiques
  static bool shouldEnableTooltips(BuildContext context) {
    // Désactiver les tooltips mouseover sur mobile
    return !isTouchDevice(context);
  }
  
  /// Retourne la configuration d'interaction appropriée pour fl_chart
  static bool shouldEnableTouch(BuildContext context) {
    // Activer le touch sur tous les appareils
    return true;
  }
}