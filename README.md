# 261216-internundervisning

Framework: **impress.js** | Node 26.13.0 | npm 12.2.1 (pinned in `.deck.json`)

## Work on it

1. Open the folder in VS Code and choose **Reopen in Container**.
2. `npm run dev` and open http://localhost:5173
3. Edit index.html (slides are .step elements); styles are in `src/theme.css`.

## Commits and branch protection

`main` is meant to be protected (GitHub enforces this only on public repos on the Free plan: run `scripts/protect.sh` once the repo is public): no direct pushes, no force-push, squash merges only, the `build` check must pass,
and every commit message must follow Conventional Commits (`feat: ...`, `fix: ...`, `docs: ...`).
A local hook (commitlint) checks each commit; the `pr-title` check enforces the format on the PR title, which becomes the commit on `main`.

```bash
git switch -c feat/roadmap-slide
git commit -m "feat: add roadmap slide"
git push -u origin HEAD
gh pr create --title "feat: add roadmap slide" --template content.md   # title = commit on main
# templates: content.md, fix.md, chore.md (or omit --template for the default)
gh pr merge --squash --auto
```

Commit from inside the devcontainer (the hook needs the installed dependencies).

## Build

`npm run build` writes a static, relocatable site to `dist/`.
`npm run build:pdf` also writes `dist/261216-internundervisning.pdf` (uses the Chromium installed in the devcontainer).
PDF export defaults to one image per slide/step; text is not selectable.

```bash
# Build and create a screenshot-based PDF with impress.js:
npm run build:pdf

# Example screenshot capture settings:
PDF_WIDTH=1920 PDF_HEIGHT=1080 PDF_PAUSE_MS=500 npm run build:pdf
```

Capture dimensions control the browser viewport; they do not change the framework's logical slide dimensions.
Custom asynchronous content can expose an async `window.preparePdfSlide({ framework, index })` hook.
CI currently runs `npm run build` and uploads the HTML site as the `deck` artifact; it does not generate a PDF.

## Re-pin Node/npm

`node scripts/init.mjs --refresh-node` (set `DECK_NODE_CHANNEL=lts` for LTS), then rebuild the container.

## Publish (optional, read first)

On every plan except GitHub Enterprise Cloud, a GitHub Pages site is public even if this repository is private.
Do not enable Pages for confidential decks. To enable it deliberately:
`gh api -X POST repos/<owner>/261216-internundervisning/pages -f build_type=workflow`, then run the "Deploy to GitHub Pages" workflow.
