import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/backup_service.dart';
import '../services/session_service.dart';
import 'dart:io';

/// Provider pour gérer l'état de l'écran des paramètres
class SettingsProvider extends ChangeNotifier {
  final BackupService _backupService;
  final SessionService _sessionService;
  final Box _preferencesBox;
  
  SettingsProvider({
    BackupService? backupService,
    SessionService? sessionService,
    Box? preferencesBox,
  }) : 
    _backupService = backupService ?? BackupService(),
    _sessionService = sessionService ?? SessionService(),
    _preferencesBox = preferencesBox ?? Hive.box('app_preferences');
    
  // Getters pour les préférences
  String get defaultHandMethod => 
      _preferencesBox.get('default_hand_method', defaultValue: 'two');
      
  String? get defaultCaliber => 
      _preferencesBox.get('default_caliber');
  
  // Méthodes pour mettre à jour les préférences
  Future<void> updateDefaultHandMethod(String value) async {
    await _preferencesBox.put('default_hand_method', value);
    notifyListeners();
  }
  
  Future<void> updateDefaultCaliber(String value) async {
    if (value.isEmpty) {
      await _preferencesBox.delete('default_caliber');
    } else {
      await _preferencesBox.put('default_caliber', value);
    }
    notifyListeners();
  }
  
  // Méthodes pour l'exportation et l'importation
  Future<void> exportToJson(Function(String) onSuccess, Function(String) onError) async {
    try {
      final file = await _backupService.exportAllSessionsToJsonFile();
      onSuccess('Fichier exporté: ${file.path}');
    } catch (e) {
      onError('Erreur export: $e');
    }
  }
  
  Future<void> exportToFolder(Function(String?) onSuccess, Function(String) onError) async {
    try {
      final file = await _backupService.exportAllSessionsToUserFolder();
      if (file == null) {
        onSuccess(null); // Export annulé
      } else {
        onSuccess(file.path);
      }
    } catch (e) {
      onError('Erreur sauvegarde: $e');
    }
  }
  
  Future<void> importFromJson(String path, Function(String) onSuccess, Function(String) onError) async {
    try {
      final content = await _backupService.readJsonFile(path);
      final imported = await _backupService.importSessionsFromJson(content);
      final total = (await _sessionService.getAllSessions()).length;
      onSuccess('$imported sessions importées. Total: $total');
    } catch (e) {
      onError('Erreur import: $e');
    }
  }
}