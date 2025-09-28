# NexTarget v0.3.0 – Scope & Planning

Date de création: 2025-09-28
Branche cible: `dev`
Objectif cible: Release v0.3.0 (itération fonctionnelle majeure après 0.2.0)

## 🎯 Objectifs principaux
1. Gestion des Exercices
2. Suivi amélioré des Objectifs
3. Amélioration UI de saisie des Séries (ergonomie stand)
4. Améliorations mineures (calibres, cohérence données, micro UX)
5. Évolutions statistiques & performance (ajout suivi 1M / 2M, raffinement indicateurs)

## 1. Gestion des Exercices
### Description
Introduire une entité "Exercice" distincte des sessions, permettant de définir un type de travail (ex: précision 10m, cadence, groupement contrôlé, visée). Les exercices pourront être réutilisés dans différentes sessions.

### Besoins
- Modèle `Exercise` (id, nom, description courte, catégorie, paramètres optionnels selon type)
- Association Session -> Liste d'exercices utilisés (ordre)
- Possibilité de filtrer l’historique par exercice

### Détails fonctionnels
- Création / édition / suppression
- Catégories (ex: Précision, Cadence, Stabilité, Respiration)
- Option: tag(s) libres

### UI/UX
- Nouvelle section "Exercices" (liste + bouton + détail)
- Sélecteur d’exercice dans l’écran de session (ajout rapide)

### Données / stockage
- Migration locale (ajout table/collection). Conserver compat 0.2.x

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
- Clavier custom (numpad rapide + gestes)
- Mode plein écran de saisie rapide
- Validation instantanée (score cumul, moyenne série en cours)
- Passage d’une série à l’autre optimisé (swipe / raccourci)

### Bonus (optionnel)
- Affichage groupement estimé simplifié (si données dispo)

## 4. Améliorations mineures
### Liste initiale
- Gestion des calibres: normaliser et proposer liste déroulante fréquente
- Préservation dernier calibre utilisé
- Harmonisation messages d’erreur réseau
- Ajustements visuels (espacements, contrastes)
- Nettoyage code legacy (widgets dupliqués)

## 5. Stats & Performances (1M / 2M)
### Contexte
Ajout d’indicateurs de tendance courte/moyenne: 1M = 1 mois, 2M = 2 mois.

### Détails
- Calcul moyennes glissantes 30j / 60j
- Comparaison delta (progression + / -)
- Ajout d’un mini graphe tendance (sparkline) sur page stats
- Exposition API interne (service stats) pour réutilisation

### Extension future
- Persistance des stats agrégées (cache) pour accélérer l’ouverture

## 6. Non-objectifs (pour éviter le scope creep)
- Pas d’authentification / multi-device encore
- Pas d’IA coach avancée supplémentaire (outre existant)
- Pas d’export PDF avancé

## 7. Techniques / Architecture
- Ajouter tests unitaires sur service stats & migration exercices
- Refactor si nécessaire: séparation `models/` vs `services/` plus stricte
- Vérifier impact taille base locale (index si besoin)

## 8. Migration & Compatibilité
- Script/méthode de migration BDD locale: ajout tables / colonnes (exercices, enrichissement objectifs)
- Stratégie fallback si corruption: log + skip migration + message utilisateur

## 9. Suivi / Kanban interne (suggestion)
Colonnes: Backlog | En cours | Test | Fini (0.3 scope)

## 10. Critères de sortie (Definition of Done v0.3.0)
- Tous les modules ci-dessus implémentés (min. sans bonus optionnels marqués)
- Pas de régression sur fonctionnalités 0.2.0 (tests manuels de base)
- Changelog mis à jour avec section 0.3.0
- Build release testée sur appareil réel

## 11. Versioning
- Incrément: `pubspec.yaml` passera à `0.3.0` lors de la phase de stabilisation (pré-release) avant tag.

## 12. Changelog (pré-création entrée)
Ajout d’une section Unreleased dans `CHANGELOG.md` pour préparer l’agrégation.

---
Document vivant – mettre à jour au fur et à mesure.
