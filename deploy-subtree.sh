#!/bin/bash
set -euo pipefail

# Usage: ./deploy.sh [base-href]
# Exemple: ./deploy.sh /mon-repo/   (pour que <base href="/mon-repo/"> soit utilisé)

# Détermine le nom du repo (utilisé pour le base-href par défaut)
REPO_NAME=$(basename -s .git "$(git rev-parse --show-toplevel)")
BASE_HREF="/${REPO_NAME}/"

if [ $# -ge 1 ]; then
  BASE_HREF="$1"
fi

echo "🛠  Build Flutter Web avec base-href=${BASE_HREF}"
flutter build web --release --base-href "${BASE_HREF}"

echo "📦  Pousser build/web vers gh-pages avec git subtree"
# Commit éventuel de la source (facultatif, évite d'échouer si rien à committer)
git add -A
git commit -m "Mise à jour des sources avant déploiement" || true

# Pousse seulement build/web comme racine de gh-pages
git subtree push --prefix build/web origin gh-pages --force

echo "✅ Déployé sur la branche gh-pages"
