# NexTarget v0.3.0 – Scope & Planning

---
Mise à jour (03/10/2025)

Résumé exécution v0.3.0:
- Objectif central réalisé: introduction des Exercices réutilisables + intégration directe dans la création / planification de sessions.
- Accent mis sur une fonctionnalité non explicitement prévue dans le scope initial: Sessions planifiées + conversion guidée (wizard) en sessions réalisées.
- Extension Objectifs (Lots A→D) livrée: Top3 + compteurs, stats macro, multi-carte, formulaire séparé, aide tendance. (Les enrichissements structurels prévus initialement: type, statut étendu, historique → toujours non livrés.)
- Plusieurs éléments du scope initial restent non livrés (objectifs enrichis structurés, stats 1M/2M, saisie plein écran) et sont reportés.
 - Stabilisation « Tableau de bord » (ex‑Accueil) livrée: filtrage central des sessions réalisées, tri chronologique strict des séries (ASC), titres centrés, renommage, et harmonisation des graphes (points, groupement, scatter) affichant désormais les 30 dernières séries. Modes Scatter alternatifs outillés (cap/downsampling) disponibles pour itérations futures.

Légende statut utilisée ci-dessous:
- ✅ Réalisé
- 🟡 Partiellement réalisé
- ⏩ Reporté / Non livré en 0.3.0
- ➕ Ajout hors scope initial
---

Date de création: 2025-09-28
Branche cible: `dev`
Objectif cible: Release v0.3.0 (itération fonctionnelle majeure après 0.2.0)

## 🎯 Objectifs principaux
1. Gestion des Exercices – ✅ (fondations livrées : modèle, UI liste/édition, planification, icônes, filtres/tri, cartes stats). Restant (reporté v0.4+) : usageCount / lastPerformedAt, tags libres, recommandations croisées.
3. Amélioration UI de saisie des Séries – ✅ (objectif v0.3 considéré atteint via wizard planifiée→réalisée + validations; plein écran & navigation directe hors scope restant)
4. Améliorations mineures – 🟡 (micro UX & préférences livrées; calibres harmonisés livrés; harmonisation réseau reportée)
5. Évolutions statistiques (1M / 2M) – ⏩ (non livré)

➕ Ajout majeur hors liste initiale: Sessions planifiées + conversion guidée.

## 1. Gestion des Exercices
### Description
Introduire une entité "Exercice" distincte des sessions, permettant de définir un type de travail (ex: précision 10m, cadence, groupement contrôlé, visée). Les exercices pourront être réutilisés dans différentes sessions.

Statut global: 🟡 (fondations livrées; catégories / paramètres typés / multi-exercices dans une session à compléter)

Livré:
- ✅ Modèle Exercise (id, nom, description, consignes, association objectifs)
- ✅ Association Session -> Exercise (sessions planifiées créées à partir d’un exercice, référence persistée)
- ✅ Création / édition / suppression basiques + consignes multi-étapes utilisées pour auto-générer les séries planifiées
- ✅ Lien Exercise -> Objectifs (sélection multiple)

### Besoins
- Modèle `Exercise` (id, nom, description courte, catégorie, paramètres optionnels selon type)
- Association Session -> Liste d'exercices utilisés (ordre)
- Association Exercice -> Objectifs

### Détails fonctionnels
- Création / édition / suppression
- Catégories (ex: Précision, Cadence, Stabilité, Respiration)

### UI/UX
- Nouvelle section "Exercices" (liste + bouton + détail)

Statut:
- ✅ Section Exercices (liste + détail + création) livrée

### Données / stockage
- Migration locale (ajout table/collection). Conserver compat 0.2.x

Statut:
- ✅ Ajout box Hive + compat ascendante (aucune rupture 0.2.x)
- 🟡 Pas encore de système de migrations généralisé type MigrationRunner (prévu mais non finalisé en 0.3)

### Risques
- Explosion des variantes (limiter les types au départ)

## 2. Suivi amélioré des Objectifs
### Objectifs
Rendre les objectifs plus actionnables et mesurables.

### Actions prévues
- Ajout d’un champ "type" (ex: score global, moyenne série, volume, régularité)
- Ajout d’une date cible ou période
- Statut enrichi: `planned`, `in_progress`, `achieved`, `abandoned`
- Historisation: journal des changements de statut

Statut: 🟡 Partiellement livré (Lots A-D apportent visibilité & tendance) / Non livré pour: type objectif, statut enrichi, historique, date cible.

### UI
- Vue liste triée par priorité & statut
- Détail objectif: progression + historique

### Calcul progression
- Basé sur métrique sous-jacente (ex: moyenne points 30j / objectif numérique)

## 3. Amélioration UI des Séries
### Problèmes actuels
- Saisie potentiellement lente en conditions réelles
- Peu de retours immédiats sur qualité

### Améliorations
- Mode plein écran de saisie rapide
- Validation instantanée (score cumul, moyenne série en cours)
- Passage d’une série à l’autre optimisé (swipe / raccourci)

Statut global: ✅ (cible v0.3 atteinte avec alternative wizard; éléments avancés restants hors scope v0.3)

Livré (différent du scope exact mais répond partiellement à l’intention):
- ✅ Wizard de conversion session planifiée → réalisée avec progression multi-étapes
- ✅ Champs obligatoires & validations strictes (distance, coups, score, groupement, commentaire)
- ✅ Inheritance automatisée des valeurs Distance / Coups / Prise entre séries
- ✅ Sélecteur de prise (1M / 2M) avec préférence utilisateur

Non livré:
- ⏩ Mode plein écran dédié
- ⏩ Navigation entre séries
- ⏩ Feedback temps réel (moyenne cumulée) hors synthèse finale

### Bonus (optionnel)
- Affichage groupement estimé simplifié (si données dispo)

Statut: ⏩ Non implémenté.

## 4. Améliorations mineures
### Liste initiale
- Gestion des calibres: normaliser et proposer liste déroulante fréquente
- Préservation dernier calibre utilisé
- Harmonisation messages d’erreur réseau
- Ajustements visuels (espacements, contrastes)
- Nettoyage code legacy (widgets dupliqués)

Statut global: 🟡 (reste: dernier calibre, harmonisation réseau)

Livré partiellement:
- ✅ Ajustements visuels ciblés (cartes sessions planifiées différenciées, couleurs filtres)
- ✅ Préférences utilisateur (prise par défaut) ajoutées
- ✅ Nettoyages ponctuels autour des écrans wizard / FAB

Non livré / partiel:
- ⏩ Préservation dernier calibre (non appliqué)
- ⏩ Harmonisation messages réseau (reporté)

### Tableau de bord – Stats (livré v0.3)
- ✅ Renommage « Accueil » → « Tableau de bord » et titres centrés sur les composants
- ✅ Filtrage central des sessions: exclusion systématique du statut `prévue` dans tous les calculs stats
- ✅ Tri chronologique strict des séries (date session puis ordre intra‑session)
- ✅ Graphes « Évolution points » et « Évolution groupement »: affichent les 30 dernières séries (ancien → récent)
- ✅ Graphe « Corrélation Points/Groupement » (scatter): affiche les 30 dernières séries
- ✅ Retrait de la section obsolète « Mes dernières sessions »
- 🧩 Modes Scatter alternatifs (fenêtre 30j cap / adaptatif + downsampling stride) outillés pour une activation ultérieure si souhaité (par défaut: 30 dernières séries)

## 5. Stats & Performances (1M / 2M)
### Contexte
Ajout d’indicateurs de tendance courte/moyenne: 1 mois, 2 mois.

### Détails
- Calcul moyennes glissantes 7j / 1 mois / 2 mois
- Comparaison delta (progression + / -)
- Ajout d’un mini graphe tendance (sparkline) sur page stats

Statut: ⏩ Non livré en v0.3.0 (indicateurs 1M/2M et sparkline restant à implémenter; actuelle couverture = 7j & 30j partielle via objectifs)

### Extension future
- Persistance des stats agrégées (cache) pour accélérer l’ouverture

Statut: ⏩ Reporté.

## 6. Non-objectifs (pour éviter le scope creep)
- Pas d’authentification / multi-device encore
- Pas d’IA coach avancée supplémentaire (outre existant)
- Pas d’export PDF avancé

## 7. Techniques / Architecture
- Rester sur Hive comme store principal (pas de bascule SQLite)
- Introduire repository Exercise (abstraction au cas où future persistence)
- Ajouter tests unitaires sur service stats & création exercices
- Refactor si nécessaire: séparation `models/` vs `services/` plus stricte
- Vérifier impact taille base locale (compaction périodique si besoin)
- Infrastructure de migrations Hive standardisée (`MigrationRunner` + version store)

Statut:
- ✅ Hive conservé
- ✅ Repository / service Exercise implémenté (niveau basique)
- ✅ Tests autour de la conversion planifiée → réalisée (service sessions) ajoutés
- ✅ Tests stats ajoutés (filtres statut, ordre des séries, progression/consistency edge cases, pipeline « dernières N séries », sélection/downsampling Scatter)
- 🟡 Refactor structure partiel (pas de refonte complète models/services)
- ⏩ Infrastructure de migrations standardisée non finalisée

## 8. Migration & Compatibilité
- Stratégie d'évolution Hive: nouvelle box ou extension schéma serialisé (compat ascendante)
- Prévoir un utilitaire de mise à niveau (lecture anciennes entrées -> réécriture normalisée)
- Stratégie fallback si corruption: log + nettoyage box + notification utilisateur
 - v2: ajout clé `exercises: []` + normalisation catégorie (appliquée au démarrage)

Statut:
- ✅ Compat ascendante préservée
- 🟡 Pas d’utilitaire générique de mise à niveau (logiciel minimaliste seulement)
- ⏩ Fallback corruption & stratégie nettoyage non implémentés
- 🟡 Ajout structure exercises OK, normalisation catégories pas en place

## 9. Suivi / Kanban interne (suggestion)
Colonnes: Backlog | En cours | Test | Fini (0.3 scope)

## 10. Critères de sortie (Definition of Done v0.3.0)
- Tous les modules ci-dessus implémentés (min. sans bonus optionnels marqués)
- Pas de régression sur fonctionnalités 0.2.0 (tests manuels de base)
- Changelog mis à jour avec section 0.3.0
- Build release testée sur appareil réel

Réalité v0.3.0 (état intermédiaire continué):
- 🟡 Modules: partiellement (Objectifs structure avancée & Stats 1M/2M non livrés; extension visibilité/tendance livrée)
- ✅ Exercices: socle complet livré (EX1–EX17); approfondissements replanifiés.
- ✅ Pas de régression majeure observée (tests ciblés & scénarios wizard)
- ✅ Changelog 0.3.0 enrichi (Objectifs Lots A-D & Exercices EX1–EX17)
- ✅ Build: APK release générée et testée sur appareil

## 11. Versioning
- Incrément: `pubspec.yaml` passera à `0.3.0` lors de la phase de stabilisation (pré-release) avant tag.

Statut: ✅ Version bump effectué (pubspec 0.3.0). Tag git à créer (non encore poussé au moment de la rédaction).

## 12. Changelog (pré-création entrée)
Ajout d’une section Unreleased dans `CHANGELOG.md` pour préparer l’agrégation.

---
Document vivant – mettre à jour au fur et à mesure.

---
## Synthèse livraisons hors scope initial (v0.3.0)
➕ Sessions planifiées (statut « prévue », filtrage, différenciation visuelle)
➕ Wizard de conversion planifiée → réalisée (multi-étapes, validations, synthèse finale)
➕ Auto-génération de séries à partir des consignes d’un exercice
➕ FAB avec appui long / clic droit pour créer une session planifiée
➕ Héritage intelligent Distance / Coups / Prise entre séries
➕ Stockage préférence utilisateur pour la prise (1M / 2M)
➕ Validation stricte des champs série + messages d’erreur cohérents
➕ Synthèse auto pré-remplie (« Session créée à partir de … »)

## Éléments reportés (candidats v0.4+)
- Objectifs enrichis (type, statut étendu, historique)
- Statistiques 30j / 60j + sparkline
- Filtrage sessions par exercice dans l’historique
- Catégories & tags d’exercices
- Normalisation calibres + dernier calibre
- Infrastructure de migrations standardisée / fallback corruption

---
Fin de mise à jour post-release v0.3.0.

### Note de progression
Bien que les fondations Exercices soient marquées ✅, certains incréments restent à livrer avant clôture formelle totale de la version (objectif enrichi, stats profondes, normalisation calibres). Le statut global reste donc "version en stabilisation" jusqu'à intégration des derniers correctifs mineurs ou décision de bascule vers v0.4.
