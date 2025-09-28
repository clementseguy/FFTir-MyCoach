#!/usr/bin/env bash
set -euo pipefail

# Script de génération APK release avec clé API Mistral.
# Usage:
#   ./build_release_apk.sh                # utilisera $MISTRAL_API_KEY si définie
#   MISTRAL_API_KEY=xxxx ./build_release_apk.sh
#   ./build_release_apk.sh --ask-key      # force la saisie interactive
# Options:
#   --ask-key    Demande la clé si non fournie
#   --flavor <f> (réservé pour future extension)
# Sortie:
#   Génère build/app/outputs/flutter-apk/app-release.apk

ASK_KEY=false
FLAVOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ask-key)
      ASK_KEY=true; shift ;;
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

# Construction commande
CMD=(flutter build apk --release --dart-define=MISTRAL_API_KEY="${MISTRAL_API_KEY}")

if [[ -n "$FLAVOR" ]]; then
  CMD+=(--flavor "$FLAVOR")
fi

echo "==> Commande: ${CMD[*]}"
"${CMD[@]}"

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [[ -f "$APK_PATH" ]]; then
  SIZE=$(du -h "$APK_PATH" | cut -f1)
  echo "\nAPK généré: $APK_PATH ($SIZE)"
else
  echo "Échec: APK introuvable à $APK_PATH" >&2
  exit 4
fi

echo "Terminé."