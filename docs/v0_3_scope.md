# NexTarget v0.3.0 – Scope & Planning

---
Mise à jour (29/09/2025)

Résumé exécution v0.3.0:
- Objectif central réalisé: introduction des Exercices réutilisables + intégration directe dans la création / planification de sessions.
- Accent mis sur une fonctionnalité non explicitement prévue dans le scope initial: Sessions planifiées + conversion guidée (wizard) en sessions réalisées.
- Plusieurs éléments du scope initial restent non livrés (principalement objectifs enrichis, stats 1M/2M et améliorations clavier/saisie avancées) et sont reportés.

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
1. Gestion des Exercices – 🟡 (base livrée, certains attributs/options non faits)
3. Amélioration UI de saisie des Séries – 🟡 (wizard conversion & validations livrés, pas de clavier custom/saisie plein écran)
4. Améliorations mineures – 🟡 (quelques micro UX + préférences, pas la normalisation calibres complète)
5. Évolutions statistiques (1M / 2M) – ⏩ (non livré)

➕ Ajout majeur hors liste initiale: Sessions planifiées + conversion guidée.

## 1. Gestion des Exercices
### Description
Introduire une entité "Exercice" distincte des sessions, permettant de définir un type de travail (ex: précision 10m, cadence, groupement contrôlé, visée). Les exercices pourront être réutilisés dans différentes sessions.

Statut global: 🟡 (fondations livrées, certains raffinements non faits)

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

Statut: ⏩ Non livré en v0.3.0 (aucune de ces extensions implémentée). Seul le lien Exercice -> Objectifs est disponible.

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

Statut global: 🟡

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

Statut global: 🟡

Livré partiellement:
- ✅ Ajustements visuels ciblés (cartes sessions planifiées différenciées, couleurs filtres)
- ✅ Préférences utilisateur (prise par défaut) ajoutées
- ✅ Nettoyages ponctuels autour des écrans wizard / FAB

Non livré / partiel:
- ⏩ Normalisation complète des calibres + liste standard
- ⏩ Préservation dernier calibre (non appliqué)
- ⏩ Harmonisation messages réseau (reporté)

## 5. Stats & Performances (1M / 2M)
### Contexte
Ajout d’indicateurs de tendance courte/moyenne: 1 mois, 2 mois.

### Détails
- Calcul moyennes glissantes 30j / 60j
- Comparaison delta (progression + / -)
- Ajout d’un mini graphe tendance (sparkline) sur page stats
- Exposition API interne (service stats) pour réutilisation

Statut: ⏩ Non livré en v0.3.0

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
- 🟡 Pas de tests stats (fonctionnalités stats non implémentées)
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

Réalité v0.3.0:
- 🟡 Modules: partiellement (Objectifs enrichis & Stats non livrés)
- ✅ Pas de régression majeure observée (tests ciblés & scénarios wizard)
- ✅ Changelog 0.3.0 publié
- 🟡 Build: APK debug validé; build release à produire pour diffusion finale

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
