# Scheduled task prompt — AIDigest daily status check

This is a manually-maintained snapshot of the live prompt for the Cowork scheduled task that checks in on this project daily, kept here purely for version history. **This file is not read by anything** — the actual source of truth is Cowork's own scheduled-task storage on the Mac. If the task prompt changes again, copy the new text in here by hand and note the date/reason below.

**Last synced:** 2026-07-11 — initial version, set up alongside the shared status-tracking habit across projects (see `~/claude/Projects/status/`).

---

Check in on the AI Digest Hub project (`/Users/divbox/claude/Projects/AIDigest/`) and update its status.

Context: the `ai-newsletter-digest` skill runs M–F at 6:06am, writing `ai-digest-YYYY-MM-DD.html` into the project root. A separate script (`scripts/publish.sh`) is supposed to sweep those into `dailies/`, rebuild `index.html`/`archive.html`, and push to GitHub — but that part is intentionally paused (see `TODO.md`) until digest generation itself has run cleanly for a while. Don't treat the pause itself as a problem.

1. Did a digest get produced when expected? If today is a weekday, check for `ai-digest-<yesterday's date>.html` in the project root or already in `dailies/`. Missing on a weekday = flag (skill likely failed silently). If today is Monday, one file covering Fri–Sun is normal.

2. Count root-level `ai-digest-*.html` files not yet swept into `dailies/`. This number is expected to grow for now — don't flag the pile itself, just note the count so drift is visible over time.

3. Check `TODO.md`'s "Still to do" section for deferred items with a stated target (e.g., "next week" as of a given date). If today is more than ~7 days past that stated date and the item is still open with no update noting why, flag it as overdue against its own plan.

4. Check `git log -1` and `git status`: flag if the repo has diverged from `origin/main`, or if there are uncommitted/unexpected changes beyond the normal pile of untracked digest HTMLs.

5. Write the result to `~/claude/Projects/status/AIDigest.md`:
   - Update the "Current" line with today's date and a one-line status ("no change" or the specific flag).
   - Append one line to the log with today's date and what happened.
   - Trim the log to the most recent 30 entries, oldest dropped first. Cap by entry count, not raw line count — a flag entry can span multiple lines.

Don't fix anything found — just report it in the status file. Flag failures or anomalies clearly; don't ask for permission first.
