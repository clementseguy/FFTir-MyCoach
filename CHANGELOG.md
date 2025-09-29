# Changelog

Toutes les modifications notables de ce projet seront listées ici.

## [0.3.0] - 2025-09-29
### Added
- Exercices: création, description, durée, matériel, consignes (0..n).
- Association sessions ↔ exercices; planification de session depuis un exercice.
- Sessions prévues: statut 'prévue', filtre dédié, en-tête stats spécifiques.
- Wizard conversion session prévue → réalisée (intro + séries + synthèse).
- Consignes → génération séries placeholder; prise (1M/2M) éditable par série.
- Champs supplémentaires séries dans le wizard: Coups, Distance, Points, Groupement, Commentaire (validations obligatoires).
- Stats: moyennes glissantes (30/60j) + delta de progression (affichage amélioré).

### Changed
- Différenciation visuelle sessions prévues (couleurs cartes, chips, header).
- FAB: appui long / clic droit (web) pour créer directement une session prévue.
- Refonte UI état vide historique (suppression bouton central redondant).
- Synthèse: préremplie depuis l'exercice + insertion newline pour édition.

### Fixed
- Perte séries placeholder lors planification (valeurs minimales persistées).
- Overflow éditeur consignes + overflow wizard séries (scroll + layout fix).
- Defaults Coups / Distance séries suivantes hérités correctement (plus de 1).
- Préremplissage indésirable champs (Points, Groupement, Commentaire) supprimé.

### Technical
- Service conversion `convertPlannedToRealized` + persistance incrémentale séries.
- Tests: ajout planned_session_conversion_test & validations post-wizard.
- Script build APK: renommage versionné (réutilisé pour debug 0.3.0).
- Sélecteur prise: réutilisation préférence utilisateur (Hive app_preferences).

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
