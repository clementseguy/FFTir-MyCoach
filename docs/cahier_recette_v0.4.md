# Cahier de Recette v0.4

- Dernière mise à jour: 2025-10-07
- Généré automatiquement depuis `docs/specs/cahier_recette.yaml`

## SESS-01 — Sessions – création/édition
Objectif: Créer une session réalisée avec armes/séries, puis l’éditer sans perte de données.
Pré-requis:
- Application installée
- Aucune session obligatoire
Étapes:
1. Ouvrir l’app et aller sur “+” → “Nouvelle session (réalisée)”
2. Renseigner arme, calibre, prise, au moins 1 série (coups, distance, points, groupement)
3. Enregistrer la session
4. Ouvrir la session et modifier un champ (ex: commentaire)
5. Enregistrer à nouveau
Résultats attendus:
- La session apparaît dans l’historique réalisée
- Les champs saisis sont persistés fidèlement
- La modification est bien visible après réouverture

## SESS-02 — Sessions prévues (planification) + conversion wizard
Objectif: Planifier une session, puis la convertir en réalisée via l’assistant.
Étapes:
1. Depuis un exercice, planifier une session prévue
2. Vérifier l’icône “prévue” et la présence dans la liste dédiée
3. Lancer la conversion (wizard), compléter séries et synthèse
4. Valider la conversion
Résultats attendus:
- La session disparaît des “prévues” et figure dans les sessions réalisées
- Les séries saisies via le wizard sont bien persistées

## DASH-01 — Tableau de bord – statistiques récap
Objectif: Afficher les statistiques macro et les dernières tendances.
Étapes:
1. Créer/ajouter une session avec au moins 1 série
2. Ouvrir l’accueil/Tableau de bord (onglet Synthèse)
3. Vérifier l’affichage des indicateurs (réalisés total, 7/30/60/90j) et cartes récap
Résultats attendus:
- Les valeurs sont cohérentes avec les sessions existantes

## DASH-02 — Tableau de bord – statistiques avancées
Objectif: Vérifier la mise à jour des statistiques dans l’onglet Avancé.
Étapes:
1. Créer/ajouter une session avec au moins 1 série
2. Ouvrir le Tableau de bord (onglet Avancé)
Résultats attendus:
- Les statistiques et graphes sont mis à jour avec la nouvelle session

## GOAL-01 — Objectifs – création/édition et listing
Objectif: Créer un objectif, vérifier son affichage et sa progression.
Étapes:
1. Créer un objectif (nom, période, métriques)
2. Vérifier la présence dans le listing et la carte “Top”
3. Modifier l’objectif et enregistrer
Résultats attendus:
- L’objectif est visible avec ses informations correctes
- La modification est persistée

## EX-01 — Exercices – création et association aux sessions
Objectif: Créer un exercice et l’associer à une session.
Étapes:
1. Créer un exercice (nom, catégorie, type, durée, matériel, consignes)
2. Depuis l’exercice, planifier puis convertir une session (cf. SESS-02)
Résultats attendus:
- L’exercice apparaît dans la liste et l’association session ↔ exercice est visible

## EX-02 — Exercices – session prévue depuis un exercice d’entraînement
Objectif: Vérifier que le nombre de séries prévues correspond au nombre de consignes.
Étapes:
1. Créer un exercice de type "entraînement" avec 3 consignes
2. Transformer cet exercice en session prévue
Résultats attendus:
- La session prévue est créée avec un nombre de séries égal au nombre de consignes (3)

## CAL-01 — Calibres – autocomplétion + préférence par défaut
Objectif: Saisie de calibre assistée et préremplie si préférence définie.
Étapes:
1. Ouvrir création de session, focus sur calibre → voir liste complète
2. Taper un alias (ex: 9mm) et sélectionner une option
Résultats attendus:
- La liste s’affiche au focus
- La sélection remplit le champ correctement

## CAL-02 — Calibres – préférence par défaut
Objectif: Préremplir le champ calibre depuis la préférence utilisateur.
Étapes:
1. Aller dans Préférences et sélectionner un calibre par défaut
2. Créer une nouvelle session
Résultats attendus:
- Le champ calibre est prérempli avec le calibre par défaut

## PREF-01 — Réglages – préférences utilisateur (Hive)
Objectif: Tester la préférence "1 main / 2 mains" et son effet de préremplissage.
Étapes:
1. Ouvrir l’écran Réglages et régler la préférence de prise d’arme (1 main / 2 mains)
2. Créer une nouvelle session et vérifier le préremplissage de la prise
Résultats attendus:
- La préférence est persistée et appliquée au formulaire de session

## PREF-02 — Réglages – préférence calibre
Objectif: Tester la préférence de calibre (saisie assistée + persistance).
Étapes:
1. Ouvrir l’écran Réglages et modifier la préférence de calibre (autocomplétion: la liste apparaît lors de la saisie)
2. Sauvegarder, puis rouvrir les préférences pour vérifier la persistance
Résultats attendus:
- La liste de calibres apparaît bien lors de la saisie et la valeur choisie est persistée

## EXP-01 — Export sessions
Objectif: Exporter les sessions et vérifier le fichier généré.
Étapes:
1. Ouvrir le module d’export, choisir un dossier
2. Lancer l’export
Résultats attendus:
- Un fichier est généré dans le dossier choisi

## SEC-01 — Règles de sécurité (dashboard)
Objectif: Afficher le bloc de règles FFTir et vérifier sa lisibilité.
Étapes:
1. Ouvrir l’accueil/Tableau de bord
2. Vérifier la section “Règles de sécurité”
Résultats attendus:
- Le contenu est à jour et lisible (révision FFTir 2024)

