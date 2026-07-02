# AI Digest Hub — pick up here (post-migration, 2026-07-02)

This project just split off from "Claude Training" so the digest has its own clean repo/project. Picking this up in a fresh chat connected to this folder — here's exactly where things stand.

## What's already done (from the old project's chat)
- Copied (not moved) from Claude Training into this folder: `.git`, `.gitignore`, `.nojekyll`, `README.md`, `TODO.md` (this file), `dailies/`, `docs/`, `scripts/`, `skill/`, and the stray `ai-digest-2026-07-02.html`.
- This `CLAUDE.md` is new — digest-only content, no training-checklist cruft.
- `scripts/publish.sh` fixed: `cd` now goes to the repo root (parent of `scripts/`), not `scripts/` itself — the old bug would've built `dailies/`/`index.html`/`archive.html` inside `scripts/`.
- `scripts/com.divbox.digest-publish.plist` fixed: `ProgramArguments` and both log paths now point at `/Users/divbox/claude/Projects/AIDigest/...` instead of the old Claude Training path.
- The Cowork scheduled task (`ai-newsletter-digest`, runs 6:06am M–F) had its prompt updated to save here (`/Users/divbox/claude/Projects/AIDigest/`) instead of Claude Training. The task itself is stored independently of any project folder (`/Users/divbox/claude/Scheduled/ai-newsletter-digest/SKILL.md`) — it was never structurally "attached" to Claude Training, just pointed there in its instructions. It keeps running on schedule regardless of which project chat is open.
- The Latent Space source now searches `from:swyx+ainews@substack.com` instead of a subject-text fallback that was silently missing it.

## Important: this repo has never actually been pushed
`git log` shows exactly one commit, and it contains only `README.md`. Everything else in this folder — `TODO.md`, `dailies/`, `docs/`, `scripts/`, `skill/` — is untracked, sitting only in the local working copy. Nothing has reached GitHub yet except that first bare commit. Don't assume a `git clone` anywhere would get you a working copy of this project — it wouldn't.

## Still to do (all on your Mac — none of this can be driven from Cowork)
1. Confirm the copy from Claude Training landed correctly (check `dailies/` has all 11+ archived digests, `skill/ai-newsletter-digest.skill` is present, etc.).
2. Delete the digest-specific items from the old Claude Training folder now that they live here: `.git`, `.gitignore`, `.nojekyll`, `README.md`, `TODO.md`, `dailies/`, `docs/`, `scripts/`, `skill/`, `ai-digest-2026-07-02.html`. Claude Training should be left with just its own (already-trimmed) `CLAUDE.md` and `cowork-skills-reference.html`.
3. `chmod +x scripts/publish.sh` if it lost the executable bit in the copy.
4. Run `scripts/publish.sh` once by hand from this folder, confirm `index.html` and `archive.html` show up and look right.
5. `git add -A && git commit -m "Migrate AI Digest Hub to its own project" && git push` — this is the real first content commit; everything currently sitting here is still untracked.
6. Load the launchd agent: `launchctl load scripts/com.divbox.digest-publish.plist` (or `bootstrap`, depending on your macOS version) — it was never actually loaded before this migration, so there's nothing stale to unload first.
7. Enable GitHub Pages in the repo settings (Settings → Pages → Deploy from a branch → `main` / `(root)`) if not already on.
8. Let tomorrow's 6:06am scheduled run land here for real, then check `publish.log` and the live Pages URL end to end.

## Already decided, don't re-litigate
- **Sweep behavior:** `publish.sh` keeps sweeping any stray root-level `ai-digest-*.html` into `dailies/` itself (Option A from the earlier open question) — no skill repackaging needed. This is already what the fixed script does.
- **Stale duplicate spec file:** never existed at root, only ever in `docs/digest-hub-spec.md` — that earlier TODO concern was a false alarm.
