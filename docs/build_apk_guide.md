# Guide de Build APK NexTarget

## 📦 Vue d'ensemble

Le script `scripts/build_apk.sh` permet de générer des APK de test (DEBUG ou RELEASE) pour l'application NexTarget.

## 🔧 Prérequis

1. **Flutter SDK** installé et dans le PATH
2. **Fichier de prompt local** : `assets/coach_prompt.local.yaml` (non versionné)
3. **Clé API Mistral** : fournie via variable d'environnement ou saisie interactive

## 📋 Fonctionnalités

### Version automatique
- ✅ Lit la version depuis `pubspec.yaml`
- ✅ Génère un APK nommé : `NexTarget-<version>-<mode>-<timestamp>.apk`

### Gestion des prompts Mistral

L'application charge automatiquement les prompts selon cette priorité :

1. **`assets/coach_prompt.local.yaml`** (non versionné, prioritaire)
2. `assets/coach_prompt.yaml` (versionné, fallback)

**Important** : Assurez-vous que `assets/coach_prompt.local.yaml` existe avec votre prompt personnalisé.

### Injection de la clé API

La clé Mistral est injectée via `--dart-define=MISTRAL_API_KEY=<clé>` lors du build.

**Ordre de priorité dans l'app** :
1. `--dart-define` (injection au build)
2. `assets/config.local.yaml` (clé locale)
3. Variable d'environnement `MISTRAL_API_KEY`
4. `assets/config.yaml` (fallback)

## 🚀 Utilisation

### Build RELEASE (par défaut)

```bash
# Avec clé en variable d'environnement
export MISTRAL_API_KEY="votre_clé_ici"
./scripts/build_apk.sh

# Ou avec saisie interactive
./scripts/build_apk.sh --ask-key
```

### Build DEBUG

```bash
./scripts/build_apk.sh --debug
```

### Options avancées

```bash
# Ne pas demander la clé (utilise $MISTRAL_API_KEY)
MISTRAL_API_KEY=xxx ./scripts/build_apk.sh --no-ask-key

# Build release avec flavors (future extension)
./scripts/build_apk.sh --flavor production
```

## 📂 Emplacement de sortie

```
build/app/outputs/flutter-apk/NexTarget-v0.4.0-release-20251017-1432.apk
```

## 🔍 Vérification post-build

### Tester le prompt local

Après installation de l'APK :
1. Créez une session avec plusieurs séries
2. Appuyez sur "Analyser avec Coach IA"
3. Vérifiez que l'analyse utilise bien votre prompt personnalisé

### Debug du prompt

Si l'analyse ne correspond pas à votre prompt local :

```bash
# Vérifier que le fichier local existe
ls -la assets/coach_prompt.local.yaml

# Vérifier qu'il est bien déclaré dans pubspec.yaml
grep coach_prompt pubspec.yaml

# Vérifier le contenu
cat assets/coach_prompt.local.yaml | head -20
```

## 🛠️ Troubleshooting

### Erreur : "coach_prompt.local.yaml not found"

**Cause** : Le fichier n'existe pas ou n'est pas dans `assets/`

**Solution** :
```bash
cp assets/coach_prompt.yaml assets/coach_prompt.local.yaml
# Puis éditez coach_prompt.local.yaml avec votre prompt
```

### L'APK utilise le mauvais prompt

**Cause** : Le fichier local n'était pas présent lors du `flutter build`

**Solution** :
```bash
# Vérifier la présence
ls assets/coach_prompt.local.yaml

# Rebuild complet
flutter clean
./scripts/build_apk.sh
```

### Version incorrecte dans le nom de l'APK

**Cause** : `pubspec.yaml` n'a pas été mis à jour

**Solution** :
```bash
# Vérifier la version
grep '^version:' pubspec.yaml

# Mettre à jour manuellement si nécessaire
# version: 0.4.0
```

## 📝 Checklist avant build

- [ ] `assets/coach_prompt.local.yaml` existe et contient votre prompt
- [ ] `pubspec.yaml` indique la bonne version (0.4.0)
- [ ] Clé API Mistral disponible (variable env ou saisie interactive)
- [ ] Flutter SDK à jour (`flutter doctor`)
- [ ] Dépendances à jour (`flutter pub get`)

## 🔐 Sécurité

**⚠️ ATTENTION** : Ne versionnez JAMAIS :
- `assets/coach_prompt.local.yaml` (contient votre stratégie de prompt)
- `assets/config.local.yaml` (peut contenir des clés)
- Les APK générés

Ces fichiers sont dans `.gitignore` par défaut.

## 📊 Exemple de workflow complet

```bash
# 1. Vérifier l'environnement
flutter doctor

# 2. Mettre à jour les dépendances
flutter pub get

# 3. Vérifier le prompt local
cat assets/coach_prompt.local.yaml | head -10

# 4. Build release
export MISTRAL_API_KEY="votre_clé"
./scripts/build_apk.sh

# 5. Installer sur device
adb install build/app/outputs/flutter-apk/NexTarget-v0.4.0-release-*.apk

# 6. Tester l'analyse coach
# (dans l'app, créer session + analyser)
```

## 🔄 Mise à jour de version

Quand vous passez à une nouvelle version (ex: 0.4.0 → 0.5.0) :

1. Mettre à jour `pubspec.yaml` :
   ```yaml
   version: 0.5.0
   ```

2. Le script utilisera automatiquement la nouvelle version :
   ```
   NexTarget-v0.5.0-release-20251017-1500.apk
   ```

---

**Dernière mise à jour** : 17 octobre 2025  
