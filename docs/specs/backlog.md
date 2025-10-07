# NexTarget - Backlog (infini)

## Idées (hors scope à date)

- Revoir les règles de sécurité FFTir

## Coaches
- Plusieurs coachs (tons différents) : 
    - coach neutre
    - coach cool
- Ecran "Coach" :
    - Permet d'analyser l'ensemble de l'activité de l'utilsiateur : plusieurs sessions, changement d'armes ou de calibres, régularité (ou pas), identification de comportements répétés, ... et de proposer des actions pour améliorer
- Attacher un coach à un utilisateur (personnalisation des retours et )

## Exercices
- Création d'Exercice par le Coach (via retour analyse de session)
- Statistiques d'exécution par fenêtres glissantes.
    - Champs usageCount / lastPerformedAt.
- Recommandations croisées Objectifs ⇄ Exercices.
- Tags libres : pourquoi faire ??
- Gérer un niveau de difficulté : beginer / advanced / expert

## Propositions GPT5

Propositions à trier :
- P1 Qualité & Observabilité: SonarCloud + couverture cible minimale (>=60%) + job lint/metrics (dart_code_metrics) + badge qualité.
- P2 Sécurité & Secrets: Centraliser appels Mistral via serveur (proxy) + suppression clé API côté client (réduction surface fuite).
- P3 Auth Foundations: Intégrer auth social (Google) + abstraction provider pour extensions (Facebook, Apple plus tard).
- P4 Exercices Exécution (incrément léger): Compter usage (usageCount, lastPerformedAt) sans encore implémenter stats glissantes.
- P5 Migrations Framework: Finaliser MigrationRunner générique + script vérif cohérence schéma (évite endettement technique futur).
- P6 Expérience Saisie: Mode plein écran saisie séries + navigation rapide (next/prev) pour 30% friction en moins.
- P7 Stats Progressive: Ajouter comparatif 30j vs 60j (delta %) + petite sparkline intégrée aux cartes existantes.
- P8 Performance: Cache mémoire des stats calculées (TTL courte) + compactage Hive périodique (seuil taille/nb écritures).
- P9 Onboarding & Aide: Mini onboarding (3 écrans) + bouton “?” contextuel sur pages clés (Objectifs, Exercices, Sessions).
- P10 Backlog Data Hygiene: Normalisation calibres + persistance dernier calibre utilisé.