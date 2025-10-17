#!/usr/bin/env bash
set -euo pipefail

#############################################
# Script de build APK NexTarget
# - Support release (défaut) et debug (--debug)
# - Injection clé API Mistral via --dart-define
# - Lecture automatique de la version (pubspec.yaml)
# - Renommage: NexTarget-v<version>-<mode>-<timestamp>.apk
#
# Comportement prompt Mistral:
#   L'app charge automatiquement coach_prompt.local.yaml (non versionné)
#   en priorité, sinon fallback sur coach_prompt.yaml (versionné).
#   Assurez-vous que assets/coach_prompt.local.yaml existe.
#
# Usage de base:
#   ./build_apk.sh                 # build release
#   ./build_apk.sh --debug         # build debug
#   MISTRAL_API_KEY=xxxx ./build_apk.sh
#   ./build_apk.sh --ask-key       # force saisie clé
#
# Options:
#   --ask-key        Demande la clé si absente (par défaut true)
#   --no-ask-key     N'interroge pas si $MISTRAL_API_KEY présent
#   --debug          Mode debug (sinon release)
#   --flavor <f>     (réservé future extension flavors)
#
# Exemples noms générés:
#   NexTarget-v0.4.0-release-20251017-1432.apk
#   NexTarget-v0.4.0-debug-20251017-1434.apk
#############################################

ASK_KEY=true
BUILD_MODE="release" # ou debug
FLAVOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ask-key)
      ASK_KEY=true; shift ;;
    --no-ask-key)
      ASK_KEY=false; shift ;;
    --debug)
      BUILD_MODE="debug"; shift ;;
    --flavor)
      FLAVOR="$2"; shift 2 ;;
    *) echo "Option inconnue: $1"; exit 1 ;;
  esac
done

if [[ -z "${MISTRAL_API_KEY:-}" || "$ASK_KEY" == "true" ]]; then
  read -rsp "Entrer la clé API Mistral (input caché): " INPUT_KEY
  echo
  if [[ -z "$INPUT_KEY" ]]; then
    echo "Erreur: clé vide" >&2
    exit 2
  fi
  export MISTRAL_API_KEY="$INPUT_KEY"
fi

echo "==> Vérification environnement Flutter"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter introuvable dans le PATH" >&2
  exit 3
fi

# Optionnel: nettoyage
# flutter clean

echo "==> Récupération des dépendances"
flutter pub get

echo "==> Lecture version application"
if [[ ! -f pubspec.yaml ]]; then
  echo "pubspec.yaml introuvable" >&2; exit 5
fi
APP_VERSION=$(grep -E '^version:' pubspec.yaml | head -n1 | awk '{print $2}')
if [[ -z "$APP_VERSION" ]]; then
  echo "Impossible de déterminer la version" >&2; exit 6
fi
echo "Version détectée: $APP_VERSION"

echo "==> Préparation commande build ($BUILD_MODE)"
if [[ "$BUILD_MODE" == "release" ]]; then
  CMD=(flutter build apk --release --dart-define=MISTRAL_API_KEY="${MISTRAL_API_KEY}")
else
  CMD=(flutter build apk --debug --dart-define=MISTRAL_API_KEY="${MISTRAL_API_KEY}")
fi

if [[ -n "$FLAVOR" ]]; then
  CMD+=(--flavor "$FLAVOR")
fi

echo "==> Commande: ${CMD[*]}"
"${CMD[@]}"

APK_DIR="build/app/outputs/flutter-apk"

if [[ "$BUILD_MODE" == "release" ]]; then
  RAW_NAME="app-release.apk"
else
  RAW_NAME="app-debug.apk"
fi

APK_PATH="$APK_DIR/$RAW_NAME"
if [[ -f "$APK_PATH" ]]; then
  TS=$(date +%Y%m%d-%H%M)
  TARGET_NAME="NexTarget-v${APP_VERSION}-${BUILD_MODE}-${TS}.apk"
  mv -f "$APK_PATH" "$APK_DIR/$TARGET_NAME"
  SIZE=$(du -h "$APK_DIR/$TARGET_NAME" | cut -f1)
  echo -e "\nAPK généré: $APK_DIR/$TARGET_NAME ($SIZE)"
else
  echo "Échec: APK introuvable à $APK_PATH" >&2
  exit 4
fi

echo "Terminé."