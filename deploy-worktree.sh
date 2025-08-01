# Détermine le nom du repo (utilisé pour le base-href par défaut)
REPO_NAME=$(basename -s .git "$(git rev-parse --show-toplevel)")
BASE_HREF="/${REPO_NAME}/"

if [ $# -ge 1 ]; then
  BASE_HREF="$1"
fi

# Prépare la worktree pour gh-pages
git worktree add .gh-pages gh-pages || git worktree add .gh-pages -b gh-pages

# Reconstruis
echo "🛠  Build Flutter Web avec base-href=${BASE_HREF}"
flutter build web --release --base-href "${BASE_HREF}"

# Copie le build dans la worktree
rm -rf .gh-pages/*
cp -r build/web/* .gh-pages/

# Commit & push depuis la worktree
cd .gh-pages
git add .
git commit -m "Deploy Flutter web to GitHub Pages"
git push --force origin gh-pages
