# Changelog

Toutes les modifications notables de ce projet seront listées ici.

## [0.3.1] - 2025-10-03
### Added
- Stats: helpers et tests pour pipeline séries (verrouillage ordre ASC et sélection des N dernières).
- Scatter: modes alternatifs (last10, window30Cap, adaptive) + utilitaires publics (`scatter_mode.dart`, `scatter_utils.dart`).
- Tests: `scatter_modes_test.dart` (modes + downsampling), renforts sur filtres/ordre (Lot C).

### Changed
- Accueil → Tableau de bord (libellés UI et tests) [Lot D].
- Titres des tableaux/graphes centrés [Lot D].
- Graphes “Évolution points” et “Évolution groupement” affichent désormais les 30 dernières séries (ancien → récent).
- Graphe “Corrélation Points/Groupement” affiche les 30 dernières séries.
- Documentation `docs/statistiques.md` alignée (sélection des 30 dernières séries; clarifications).

### Fixed
- Bug d’ordre: les graphes pouvaient afficher les séries récentes à gauche. Pipeline corrigé pour garantir “récentes à droite” et SMA3 alignée sur les points visibles.
- Flakiness tests temporels: `StatsService` accepte un `now` injecté pour figer le temps dans les tests.

### Removed
- Section “Mes dernières sessions” obsolète retirée [Lot C].

### Technical
- Filtre centralisé statut sessions (exclusion `prévue`) appliqué dans `StatsService` et `RollingStatsService` [Lot C].
- Tri strict ASC des séries (date session puis ordre intra-session) [Lot C].
- Refactor pipeline Scatter et introduction du downsampling stride.
- Mise à jour et durcissement des tests (ordre, filtres, progression/consistency edge cases).

## [0.3.0] - 2025-09-29
### Added
- Sessions prévues: statut 'prévue', filtre dédié, en-tête stats spécifiques.
- Wizard conversion session prévue → réalisée (intro + séries + synthèse).
- Consignes → génération séries placeholder; prise (1M/2M) éditable par série.
- Champs supplémentaires séries dans le wizard: Coups, Distance, Points, Groupement, Commentaire (validations obligatoires).
- Stats: moyennes glissantes (30/60j) + delta de progression (affichage amélioré).
- Objectifs :
    - Carte récap Top3 + compteurs (F3, F4, F14) remplaçant l'ancienne carte prioritaire.
    - Section statistiques macro (6 indicateurs: réalisés total, actifs, réalisés 7/30/60/90j) (F5, F6).
    - Carte multi‑objectif affichant tous les objectifs actifs triés par progression (F5).
    - Formulaire création/édition séparé avec icône sauvegarde + champ Période déplacé en bas (F7, F8, F9).
    - Aide tendance (modal + doc) avec classification En hausse / Stable / En baisse (F10, F11).
    - Documentation détaillée du calcul de tendance (objectifs_tendance.md) incluant seuil neutralité.
- Exercices (introduction) :
    - Exercices: création, description, durée, matériel, consignes (0..n).
    - Association sessions ↔ exercices; planification de session depuis un exercice.
- Exercices (EX1–EX17):
	- EX1/EX2/EX14: Enums Catégorie & Type + migration rétrocompat.
	- EX3: Règle planification limitée aux exercices Stand.
	- EX4/EX5: Cartes statistiques total exercices (écran combiné & écran dédié).
	- EX6: Icône d'exercice planifié (sessions prévues liées).
	- EX7/EX8: Filtres multi-catégories & par type (chips togglables + panneau repliable).
	- EX9: Modes de tri (nom asc/desc, catégorie, type, récent).
	- EX10: Nettoyage UI (suppression bouton + topbar redondant).
	- EX11–EX13: Actions planifier depuis card, retrait planifier du formulaire, sauvegarde dans AppBar.
	- EX15–EX17: Carte récap Exercices cohérente, stats par type (chips), suppression TODO list combiné.

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
 - Exercices: Tests de migration, tri, filtres, planification, carte stats; widget test écran combiné.

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
