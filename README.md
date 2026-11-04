# deck-template

GitHub template for private presentation repos. Choose **reveal.js** or **impress.js** per repo.
Both flavors share one interface: `npm run dev`, `npm run build` -> `dist/`.

## One-time setup

1. Install: Docker, VS Code + "Dev Containers" extension, git, Node 18+ (or rely on Docker), GitHub CLI (`gh auth login`).
2. Keep this repo private and marked as a template: `gh repo edit --template`.
3. Make the wrapper available as `new-deck`. No environment variables are needed. Keep an existing alias, or run this from the repo
   (`~/.local/bin` must be on your PATH):
   ```bash
   mkdir -p ~/.local/bin && ln -s "$PWD/scripts/new-deck.sh" ~/.local/bin/new-deck
   ```
   The wrapper uses `<your GitHub login>/deck-template`. For another template repo, set `DECK_TEMPLATE=<owner>/<repo>` for that run.

## Every new deck

```bash
new-deck quarterly-review reveal                          # or: impress
DECK_NODE_CHANNEL=lts new-deck quarterly-review reveal    # pin the LTS line instead of the newest release
```

The wrapper creates the private repo, pins the newest Node and npm at that moment (`.nvmrc`, Dockerfile, `.deck.json`),
commits `chore: initialize ...` and pushes. It does not protect `main` (see below).
Then in VS Code: **Reopen in Container**, `npm run dev`, open http://localhost:5173.

## Created the repo in the web UI instead?

Actions tab -> **Initialize deck** -> Run workflow (framework + Node channel), then `git pull`.

## Branch protection on GitHub Free

Rulesets and branch protection are unavailable for private repos on GitHub Free. While a deck is private, `main` is guarded only by:

- local hooks (installed by `npm ci` in the devcontainer): `commit-msg` checks Conventional Commits, `pre-push` blocks pushes to `main`
  (bypassable with `git push --no-verify`);
- the `build` and `pr-title` workflows, which report but do not block.

Work through branches and PRs anyway: `gh pr create --title "feat: ..." --template content.md`, then `gh pr merge --squash`.

### When you make a deck public

1. Check that nothing confidential is in the files or in the git history.
2. `gh repo edit <owner>/<repo> --visibility public --accept-visibility-change-consequences`
3. From `main`, run `./scripts/protect.sh` (PR required, `build` and `pr-title` checks required, linear history,
   no force-push, no deletion, squash merges only).
4. Verify: `git commit --allow-empty -m "chore: test" && git push --no-verify` must be rejected (GH013); then `git reset --hard HEAD~1`.

## Issue and PR templates

- Issues: `.github/ISSUE_TEMPLATE/` (presentation brief, content task, build/render problem, review feedback,
  maintenance). Blank issues are disabled in `config.yml`.
- Pull requests: `.github/PULL_REQUEST_TEMPLATE.md` is the default; `content.md`, `fix.md` and `chore.md` live in
  `.github/PULL_REQUEST_TEMPLATE/` and are selected with `gh pr create --template <file>` or `?template=<file>` in the URL.
- Squash merges use the PR title only (`protect.sh` sets the commit body to blank), so template text never lands on `main`.

## Notes

- Node/npm are resolved when the deck is created and then pinned. Re-pin with `node scripts/init.mjs --refresh-node`.
- impress.js is vendored (`public/vendor/impress.js`, version in `IMPRESS_VERSION`); a weekly workflow opens a PR
  for new releases (needs "Allow GitHub Actions to create and approve pull requests").
- GitHub Pages is opt-in and **public** unless you are on Enterprise Cloud. See the generated deck README.
- `.template/` and `scripts/init.mjs` only matter until a repo is initialized.

## PDF export

`npm run build:pdf` builds the deck and writes `dist/<package name>.pdf` (`npm run pdf` alone if `dist/` is current).
It uses the Chromium installed in the devcontainer image (`CHROMIUM_PATH`).

- Default for both frameworks: one screen-rendered PNG per slide/step, embedded in a PDF.
  This captures screen backgrounds and spatial impress.js overview steps. Text is not selectable,
  links are not interactive, and file size may be larger than a vector PDF.
- reveal: captures the final fragment state once per slide, including vertical and uncounted slides.
- impress: captures each `.step` in DOM order using zero-duration `goto()` and waits for `impress:steprefresh`.
  Custom routes and substep animations need a deck-specific `window.preparePdfSlide` hook.
- Optional reveal.js native/vector export: `PDF_MODE=native npm run build:pdf`.
  This uses the print layout and retains selectable text. Tall slides may span multiple pages.
  It is not a workaround for PDF-viewer differences.

The default capture size is 1920 x 1080. Override it with `PDF_WIDTH` and `PDF_HEIGHT` to match
the intended display aspect ratio. Use `PDF_PAUSE_MS` (default 300) for additional settling time.
The exporter also waits for framework readiness, network idle, fonts and visible images.
For asynchronous charts or custom state, define an async `window.preparePdfSlide({ framework, index })`
function in the deck; it is called after navigation, with a zero-based index (null in native mode).
Resolve it only when the content is ready. Videos are paused at their current frame; use a poster or
the hook for a deliberate still. This exporter does not make arbitrary iframes or animation deterministic.

Existing initialized deck repositories do not inherit template updates. Copy the revised
`scripts/export-pdf.mjs` and, for reveal.js, merge the `src/main.js` export integration into each deck.
Rebuild before exporting. The npm commands, package dependencies and Vite configuration stay the same.

### Examples

```bash
# Build and create a screenshot-based PDF, with either framework:
npm run build:pdf

# Build and use reveal.js' native print layout:
PDF_MODE=native npm run build:pdf

# Example capture settings:
PDF_WIDTH=1920 PDF_HEIGHT=1080 PDF_PAUSE_MS=500 npm run build:pdf
```
