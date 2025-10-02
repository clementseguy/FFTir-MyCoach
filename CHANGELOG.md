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
- Objectifs: Carte récap Top3 + compteurs (F3, F4, F14) remplaçant l'ancienne carte prioritaire.
- Objectifs: Section statistiques macro (6 indicateurs: réalisés total, actifs, réalisés 7/30/60/90j) (F5, F6).
- Objectifs: Carte multi‑objectif affichant tous les objectifs actifs triés par progression (F5).
- Objectifs: Formulaire création/édition séparé avec icône sauvegarde + champ Période déplacé en bas (F7, F8, F9).
- Objectifs: Aide tendance (modal + doc) avec classification En hausse / Stable / En baisse (F10, F11).
- Objectifs: Documentation détaillée du calcul de tendance (objectifs_tendance.md) incluant seuil neutralité.

### Changed
- Différenciation visuelle sessions prévues (couleurs cartes, chips, header).
- FAB: appui long / clic droit (web) pour créer directement une session prévue.
- Refonte UI état vide historique (suppression bouton central redondant).
- Synthèse: préremplie depuis l'exercice + insertion newline pour édition.
- Objectifs: Suppression de la legacy `GoalsSummaryCard` et lien redondant "Tous les objectifs" au profit des nouveaux blocs.
- Objectifs: Carte stats tendance plus compacte + refresh global.

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
- Objectifs: Wrapper `macroAchievementStats()` (agrégation unique) + helper tendance (delta normalisé).
- Objectifs: Réorganisation GoalsListScreen (extraction GoalEditScreen, refresh via GlobalKeys).
- Objectifs: Doc interne `objectifs_tendance.md` (fenêtres, delta, epsilon=0.001).

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
