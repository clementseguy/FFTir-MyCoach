#!/usr/bin/env bash
set -euo pipefail

# Automates publication of the v0.2.0 release on GitHub.
# Tries to use GitHub CLI if available, else falls back to curl + GITHUB_TOKEN.
# Idempotent: if the release already exists, it will exit cleanly.

REPO_SLUG="clementseguy/NexTarget-app"
TAG="v0.2.0"
TARGET_COMMIT="ba04d8d"   # Commit pointed to by the existing tag
RELEASE_NAME="NexTarget v0.2.0"
NOTES_FILE=".release_notes_${TAG}.md"

cat > "${NOTES_FILE}" <<'EOF'
## 🚀 NexTarget v0.2.0 (2025-09-28)

Cette version marque le rebranding de l'application (NexTarget) et introduit des fonctionnalités d'analyse et d'ergonomie autour des sessions de tir, ainsi que des améliorations techniques importantes.

### ✨ Added
- Bottom sheet "Rappels Essentiels" (Accueil) avec onglets Sécurité / Tir.
- Lien informatif vers des règles générales de sécurité (source externe).
- Export des sessions dans un dossier utilisateur (File Picker).
- Suppression des objectifs atteints (icône poubelle activée quand status = atteint).
- Animation splash overlay personnalisée (remplace l'ancien splash natif visuellement).
- Script de build unique `build_apk.sh` avec support debug + renommage versionné.

### 🔄 Changed
- Branding global: application renommée NexTarget (icônes / libellés).
- Renommage APK: format `NexTarget-v<version>-<mode>-<timestamp>.apk`.
- Splash natif neutralisé (android/iOS) pour éviter double affichage.
- Amélioration messages d'erreur réseau (distinction SocketException / Timeout).

### 🐛 Fixed
- Overflow layout sur la liste des objectifs.
- Échecs réseau sur Android release (ajout permission INTERNET).

### 🧪 Technical / Internal
- Injection clé Mistral via `--dart-define` + fallback config/local/env.
- Stats améliorées (moyennes 30j, progression, distribution catégories, distances...).

### ✅ Migration / Notes d’utilisation
Aucune migration manuelle requise.
Veillez à :
- Fournir la clé Mistral via `--dart-define`, variable d'env ou fichier `assets/config.local.yaml`.
- Utiliser le script `./build_apk.sh` pour générer un APK nommé automatiquement.

### 🔐 Sécurité
En cas d’exposition de clé Mistral : révoquez-la et remplacez-la (voir README).

### 📦 Checks rapides
- [x] Tag présent (v0.2.0) sur commit ba04d8d
- [x] Version dans `pubspec.yaml`: 0.2.0
- [x] CHANGELOG synchronisé

---
Format inspiré de Keep a Changelog.
EOF

echo "[INFO] Prepared release notes in ${NOTES_FILE}" >&2

# Check if release already exists
if curl -fsSL "https://api.github.com/repos/${REPO_SLUG}/releases/tags/${TAG}" | grep -q '"tag_name":'; then
  echo "[OK] Release for ${TAG} already exists. Nothing to do." >&2
  exit 0
fi

if command -v gh >/dev/null 2>&1; then
  echo "[INFO] Using GitHub CLI to create release ${TAG}" >&2
  gh release create "${TAG}" -t "${RELEASE_NAME}" -F "${NOTES_FILE}" --target "${TARGET_COMMIT}"
  echo "[SUCCESS] Release created via gh." >&2
  exit 0
fi

echo "[WARN] gh CLI not found. Falling back to curl API." >&2

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "[ERROR] GITHUB_TOKEN not set. Export a token with repo scope and re-run." >&2
  exit 1
fi

API_JSON=$(jq -n \
  --arg tag "$TAG" \
  --arg target "$TARGET_COMMIT" \
  --arg name "$RELEASE_NAME" \
  --arg body "$(cat ${NOTES_FILE})" \
  '{tag_name:$tag, target_commitish:$target, name:$name, body:$body, draft:false, prerelease:false, generate_release_notes:false}')

curl -fsSL -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/${REPO_SLUG}/releases \
  -d "${API_JSON}" >/dev/null

echo "[SUCCESS] Release created via curl API." >&2
