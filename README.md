# NexTarget

<!-- SonarCloud Badges -->
![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=alert_status)
![Coverage](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=coverage)
![Maintainability](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=sqale_rating)
![Reliability](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=reliability_rating)
![Security](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=security_rating)

Application mobile pour suivre et analyser les entraînements de tir sportif (NexTarget).

## Fonctionnalités principales
- Suivi des sessions de tir (date, arme, calibre, séries...)
- Statistiques générales (points, groupement, etc.)
- Interface sombre, logo applicatif
- Stockage local, aucune authentification

## Lancer le projet

1. Installer Flutter : https://docs.flutter.dev/get-started/install
2. Installer les dépendances :
   flutter pub get
3. Lancer sur un émulateur ou appareil Android :
   flutter run

## Configuration de l'API (Coach IA / Mistral)

La clé API Mistral ne doit PAS être commitée.

Plusieurs méthodes pour la fournir au runtime :

1. Via un fichier local non versionné : `assets/config.local.yaml`
   ```yaml
   api:
     mistral_key: "VOTRE_CLE_ICI"
   ```
   (Seuls les champs que vous surchargez sont nécessaires.)

2. Via un `--dart-define` lors du run/build :
   ```bash
   flutter run --dart-define=MISTRAL_API_KEY=VOTRE_CLE_ICI
   ```

3. Via une variable d'environnement (tests / CI native) :
   ```bash
   export MISTRAL_API_KEY=VOTRE_CLE_ICI
   flutter run
   ```

Ordre de priorité: `--dart-define` > fichier local > variable d'environnement > valeur dans `assets/config.yaml` (ignorée si placeholder) > null.

En absence de clé valide, les appels d'analyse coach lèveront une erreur explicite.

## Sécurité & rotation des clés

Après exposition involontaire :
1. Révoquez la clé dans le dashboard Mistral.
2. Générez une nouvelle clé.
3. Mettez-la via une des méthodes ci-dessus.
4. (Optionnel) Purgez l'historique Git si vous voulez supprimer définitivement l'ancienne clé :
   - Utilisez `git filter-repo` ou l'outil "GitHub Secret scanning remediation".

## Exemple de configuration

Un fichier `assets/config.example.yaml` est fourni comme modèle.

## Cahier de Recette (tests manuels)

- Document: `docs/cahier_recette.md`
- Source (inventaire): `docs/specs/cahier_recette.yaml`
- Objectif: vérifier manuellement les fonctionnalités principales après refactor/évolutions.

Mise à jour / génération:

```bash
# depuis la racine du repo
dart run scripts/generate_cahier_recette.dart
```

Avant toute MR vers `main`:
- Jouer le cahier de recette (tests manuels) et s’assurer que les résultats attendus sont conformes.
- Si une fonctionnalité change: mettre à jour `docs/specs/cahier_recette.yaml`, régénérer le Markdown, et committer.

## Qualité / Pré-commit

Un script d'assurance basique avant commit : `scripts/verify_before_commit.sh`

Usage :
```
./scripts/verify_before_commit.sh         # analyse + tous les tests
./scripts/verify_before_commit.sh fast    # analyse + sous-ensemble rapide
```

Hook Git (optionnel) :
```
ln -sf ../../scripts/verify_before_commit.sh .git/hooks/pre-commit
```
Le hook empêchera le commit si l'analyse ou les tests échouent.
