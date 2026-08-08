# Scheduled task prompt — AIDigest daily status check

This is a manually-maintained snapshot of the live prompt for the Cowork scheduled task that checks in on this project daily, kept here purely for version history. **This file is not read by anything** — the actual source of truth is Cowork's own scheduled-task storage on the Mac. If the task prompt changes again, copy the new text in here by hand and note the date/reason below.

**Last synced:** 2026-07-11 — initial version, set up alongside the shared status-tracking habit across projects (see `~/claude/Projects/status/`).

**Note, 2026-08-07:** this file was written when the task was still called `ai-newsletter-digest` and the publish pipeline was intentionally paused — neither is true anymore (live task is `ai-daily`, runs ~6:01am; `publish.sh` has been running and pushing successfully via `launchd` since mid-July). Corrected below since this task (`aidigest-status-check`) is currently disabled and nobody had caught the drift. This note itself isn't reflected in the live task's actual prompt — re-sync by hand if that task gets re-enabled and edited.

---

Check in on the AI Digest Hub project (`/Users/divbox/claude/Projects/AIDigest/`) and update its status.

Context: the `ai-daily` scheduled task runs M–F at ~6:01am, using the `ai-newsletter-digest` skill, writing `ai-digest-YYYY-MM-DD.html` into the project root. A separate script (`scripts/publish.sh`) sweeps those into `dailies/`, rebuilds `index.html`/`archive.html`, and pushes to GitHub — this pipeline is live and running via `launchd`, not paused.

1. Did a digest get produced when expected? If today is a weekday, check for `ai-digest-<yesterday's date>.html` in the project root or already in `dailies/`. Missing on a weekday = flag (skill likely failed silently). If today is Monday, one file covering Fri–Sun is normal.

2. Count root-level `ai-digest-*.html` files not yet swept into `dailies/`. Now that the publish pipeline is live (`launchd` runs `publish.sh` every 5 minutes), this pile should stay at 0 or 1 — anything more than that sitting around means the pipeline isn't picking files up and is worth flagging.

3. Check `TODO.md`'s "Still to do" section for deferred items with a stated target (e.g., "next week" as of a given date). If today is more than ~7 days past that stated date and the item is still open with no update noting why, flag it as overdue against its own plan.

4. Check `git log -1` and `git status`: flag if the repo has diverged from `origin/main`, or if there are uncommitted/unexpected changes beyond the normal pile of untracked digest HTMLs.

5. Write the result to `~/claude/Projects/status/AIDigest.md`:
   - Update the "Current" line with today's date and a one-line status ("no change" or the specific flag).
   - Append one line to the log with today's date and what happened.
   - Trim the log to the most recent 30 entries, oldest dropped first. Cap by entry count, not raw line count — a flag entry can span multiple lines.

Don't fix anything found — just report it in the status file. Flag failures or anomalies clearly; don't ask for permission first.
