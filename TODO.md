# AI Digest Hub — pick up here (post-migration, 2026-07-02)

This project just split off from "Claude Training" so the digest has its own clean repo/project. Picking this up in a fresh chat connected to this folder — here's exactly where things stand.

## What's already done (from the old project's chat)
- Copied (not moved) from Claude Training into this folder: `.git`, `.gitignore`, `.nojekyll`, `README.md`, `TODO.md` (this file), `dailies/`, `docs/`, `scripts/`, `skill/`, and the stray `ai-digest-2026-07-02.html`.
- This `CLAUDE.md` is new — digest-only content, no training-checklist cruft.
- `scripts/publish.sh` fixed: `cd` now goes to the repo root (parent of `scripts/`), not `scripts/` itself — the old bug would've built `dailies/`/`index.html`/`archive.html` inside `scripts/`.
- `scripts/com.divbox.digest-publish.plist` fixed: `ProgramArguments` and both log paths now point at `/Users/divbox/claude/Projects/AIDigest/...` instead of the old Claude Training path.
- The Cowork scheduled task (`ai-newsletter-digest`, runs 6:06am M–F) had its prompt updated to save here (`/Users/divbox/claude/Projects/AIDigest/`) instead of Claude Training. The task itself is stored independently of any project folder (`/Users/divbox/claude/Scheduled/ai-newsletter-digest/SKILL.md`) — it was never structurally "attached" to Claude Training, just pointed there in its instructions. It keeps running on schedule regardless of which project chat is open.
- ~~The Latent Space source now searches `from:swyx+ainews@substack.com`~~ — **correction, 2026-07-03:** this line was written prematurely. The scheduled task's prompt text did already have the correct sender, but the *skill's own internal doc* still said "sender unknown, use subject-search fallback," and that stale fallback is what actually ran — silently, for every scheduled run since this project's Gmail connection went live. `subject:"latent space"` matched nothing, so Latent Space was skipped in every digest and 18 unprocessed emails piled up in the inbox back to 2026-06-24. Caught when the 2026-07-03 run flagged unprocessed "AINews" emails. Decided not to backfill the missed backlog — starting clean going forward instead. The scheduled task prompt was updated for real this time (now hardcodes the sender and forbids the skill's fallback) — see `skill/scheduled-task-prompt.md` for the current mirrored copy. **Still open:** the packaged skill itself (`skill/ai-newsletter-digest.skill`, and its live copy under Cowork's skill settings) still contains the stale "sender unknown" text — Cowork can't edit skills from inside a chat session, so this needs a manual fix via Settings → Capabilities (or skill-creator) to close the loop at the actual source. Same 2026-07-03 session also switched deep-dive extraction (Import AI, Interconnects, Latent Space) from Gmail `get_thread` to WebSearch + `web_fetch` against the source site, since `get_thread` FULL_CONTENT reliably exceeded the tool's token limit on these newsletters.
- New: `skill/scheduled-task-prompt.md` — a manually-maintained, version-controlled snapshot of the live scheduled task prompt (the actual task still lives in Cowork's own storage, outside git; this file just gives it a diff trail). Re-copy by hand whenever the task prompt changes.

## Repo status (updated 2026-07-03)
Pushed for real now — `git log` shows two commits (`first commit`, `Migrate AI Digest Hub to its own project`), tracking `origin/main` (`git@github.com:divbox/aidailydigest.git`), working tree clean. `scripts/publish.sh` already has its executable bit.

The rest of the pipeline (launchd agent, GitHub Pages enablement, first manual `publish.sh` run) is **intentionally still not hooked up** — deliberate choice to get the digest generation itself reliable first before wiring up auto-publish. Plan is to revisit once a few days of clean scheduled runs are in the bank, likely next week.

## Still to do
1. ~~Confirm the copy from Claude Training landed correctly~~ — done, folder confirmed connected 2026-07-03.
2. Delete the digest-specific items from the old Claude Training folder now that they live here: `.git`, `.gitignore`, `.nojekyll`, `README.md`, `TODO.md`, `dailies/`, `docs/`, `scripts/`, `skill/`, `ai-digest-2026-07-02.html`. Claude Training should be left with just its own (already-trimmed) `CLAUDE.md` and `cowork-skills-reference.html`.
3. ~~`chmod +x scripts/publish.sh`~~ — done, already executable.
4. Run `scripts/publish.sh` once by hand from this folder, confirm `index.html` and `archive.html` show up and look right. **(deferred — see Repo status above, planned for next week)**
5. ~~`git add -A && git commit ... && git push`~~ — done, repo is pushed and tracking `origin/main`.
6. Load the launchd agent: `launchctl load scripts/com.divbox.digest-publish.plist` (or `bootstrap`, depending on your macOS version). **(deferred, next week)**
7. Enable GitHub Pages in the repo settings (Settings → Pages → Deploy from a branch → `main` / `(root)`) if not already on. **(deferred, next week)**
8. Let a 6:06am scheduled run land here for real, then check `publish.log` and the live Pages URL end to end. **(deferred, next week — pending items 4/6/7)**
9. Fix the packaged skill's stale "Latent Space sender unknown" text at the source (Settings → Capabilities or skill-creator) — Cowork patched around it in the scheduled task prompt, but the skill doc itself is still wrong.
10. Recommend a manual "Run now" of the `ai-newsletter-digest` scheduled task before relying on Monday's automatic run — the corrected prompt now uses WebSearch/`web_fetch` for deep dives, tools this task hasn't exercised before, and Cowork may pause a fresh tool on its first use for approval. Better to hit that prompt on a manual run than have it stall a real morning.

## Already decided, don't re-litigate
- **Sweep behavior:** `publish.sh` keeps sweeping any stray root-level `ai-digest-*.html` into `dailies/` itself (Option A from the earlier open question) — no skill repackaging needed. This is already what the fixed script does.
- **Stale duplicate spec file:** never existed at root, only ever in `docs/digest-hub-spec.md` — that earlier TODO concern was a false alarm.
