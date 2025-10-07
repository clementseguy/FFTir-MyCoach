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
1. Ouvrir l’accueil/Tableau de bord
2. Vérifier l’affichage des indicateurs (réalisés total, 7/30/60/90j) et cartes récap
Résultats attendus:
- Les valeurs sont cohérentes avec les sessions existantes

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

## CAL-01 — Calibres – autocomplétion + préférence par défaut
Objectif: Saisie de calibre assistée et préremplie si préférence définie.
Étapes:
1. Ouvrir création de session, focus sur calibre → voir liste complète
2. Taper un alias (ex: 9mm) et sélectionner une option
3. Dans Réglages, définir “Calibre par défaut”, créer une nouvelle session
Résultats attendus:
- La liste s’affiche au focus
- La sélection remplit le champ correctement
- Le champ calibre est prérempli si une préférence est définie (sinon vide)

## PREF-01 — Réglages – préférences utilisateur (Hive)
Objectif: Mettre à jour une préférence et vérifier l’effet dans l’app.
Étapes:
1. Ouvrir l’écran Réglages, modifier une préférence (ex: main dominante, calibre par défaut)
2. Créer une nouvelle ressource impactée (session/exercice) et vérifier le préremplissage
Résultats attendus:
- La préférence est persistée et appliquée

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

