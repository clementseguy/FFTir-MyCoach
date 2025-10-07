import 'package:flutter/material.dart';

/// Classe qui gère les thèmes de l'application
/// 
/// Permet de centraliser la configuration du thème et de faciliter sa personnalisation
class AppTheme {
  // Couleurs primaires
  static const Color amber = Colors.amber;
  static const Color neonGreen = Color(0xFF16FF8B);
  static const Color darkSurface = Color(0xFF23272F);
  static const Color darkBackground = Color(0xFF181A20);
  static const Color darkAppBar = Colors.black;
  
  /// Retourne le thème principal de l'application (sombre)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        secondary: neonGreen,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
      ),
      cardColor: darkSurface,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2,
        ),
      ),
      textTheme: ThemeData.dark().textTheme.copyWith(
        bodyLarge: const TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonGreen, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: amber, width: 2),
        ),
        labelStyle: const TextStyle(color: neonGreen),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      iconTheme: const IconThemeData(color: neonGreen, size: 24),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonGreen,
        foregroundColor: Colors.black,
      ),
      dividerColor: Colors.grey[800],
    );
  }
  
  /// Pourrait être utilisé à l'avenir pour un thème clair
  static ThemeData get lightTheme {
    // TODO: Implémenter un thème clair si nécessaire
    return darkTheme;
  }
}