#!/usr/bin/env bash
# Create a new private deck repo from the template and initialize it.
# Usage: new-deck.sh <name> <reveal|impress>
# The template is assumed to be <your GitHub login>/deck-template (set DECK_TEMPLATE=<owner>/<repo> for one run to override).
# Optional per run: DECK_NODE_CHANNEL=lts (default: latest).
# Branch protection is NOT applied here: it is unavailable for private repos on GitHub Free.
# Run scripts/protect.sh yourself once a deck is public.
set -euo pipefail

usage() { echo "Usage: $0 <name> <reveal|impress>" >&2; exit 1; }

name="${1:-}"
framework="${2:-}"
[[ -n "$name" && ( "$framework" == "reveal" || "$framework" == "impress" ) ]] || usage

template="${DECK_TEMPLATE:-$(gh api user --jq .login)/deck-template}"

gh repo create "$name" --template "$template" --private --clone
cd "$name"

# Prefer local Node (18+); otherwise run the init script in a throwaway container.
if command -v node >/dev/null 2>&1; then
  node scripts/init.mjs "$framework"
else
  docker run --rm --user "$(id -u):$(id -g)" -e DECK_NODE_CHANNEL -v "$PWD":/w -w /w node:lts-slim node scripts/init.mjs "$framework"
fi

git add -A
git commit -m "chore: initialize $framework deck"
git push

echo "Done. Open $PWD in VS Code and choose 'Reopen in Container'."
echo "Note: main is not protected (GitHub Free, private repo). Run scripts/protect.sh after making the repo public."
if command -v code >/dev/null 2>&1; then code .; fi
