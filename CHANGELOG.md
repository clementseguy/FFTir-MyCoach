# Changelog

Toutes les modifications notables de ce projet seront listées ici.

## [Unreleased - 0.3.0]
### Planned / Scope
- Gestion des Exercices (création, catégories, association aux sessions)
- Suivi amélioré des Objectifs (types, statut enrichi, progression)
- Amélioration UI saisie des Séries (mode rapide, numpad, navigation optimisée)
- Améliorations mineures: calibres normalisés, UX micro-ajustements
- Stats étendues: moyennes glissantes 30j / 60j (1M / 2M), delta progression

### Added (prévisionnel)
- (À compléter au fil des merges)

### Changed (prévisionnel)
- (À compléter)

### Fixed (prévisionnel)
- (À compléter)

### Technical (prévisionnel)
- Migration BDD: tables/colonnes Exercices + enrichissement Objectifs
- Cache stats agrégées (si implémenté)

---

## [0.2.0] - 2025-09-28
### Added
- Bottom sheet "Rappels Essentiels" (Accueil) avec onglets Sécurité / Tir.
- Lien informatif vers des règles générales de sécurité (source externe).
- Export des sessions dans un dossier utilisateur (File Picker).
- Suppression des objectifs atteints (icône poubelle activée quand status = atteint).
- Animation splash overlay personnalisée (remplace l'ancien splash natif visuellement).
- Script de build unique `build_apk.sh` avec support debug + renommage versionné.

### Changed
- Branding global: application renommée NexTarget (icônes / libellés).
- Renommage APK: format `NexTarget-v<version>-<mode>-<timestamp>.apk`.
- Splash natif neutralisé (android/iOS) pour éviter double affichage.
- Amélioration messages d'erreur réseau (distinction SocketException / Timeout).

### Fixed
- Overflow layout sur la liste des objectifs.
- Échecs réseau sur Android release (ajout permission INTERNET).

### Technical
- Injection clé Mistral via `--dart-define` + fallback config/local/env.
- Stats améliorées (moyennes 30j, progression, distribution catégories, distances...).

## [0.1.0] - 2025-09-XX
- Version initiale (sessions, séries, objectifs de base, stats simples, export JSON initial).

---
Format inspiré de Keep a Changelog.
