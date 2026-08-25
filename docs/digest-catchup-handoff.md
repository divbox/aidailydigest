# AI Digest — Reliability & Catch-up: Handoff Notes

Purpose: brief for a fresh session to explore how to make the daily AI digest
run reliably and self-recover when it misses days. This is a problem-framing
doc, not a decided design. Nothing here is settled — the point is to reconsider
approaches, not just patch the current construct.

## The two problems (keep them separate)

1. **Missed days don't get built.** The scheduled task (`ai-daily`, cron
   `0 6 * * 1-5`) sometimes fails before producing anything. When it does, that
   day's digest is simply never built, and nothing catches it up later. The
   current skill only ever builds "today," derived from the wall clock, with no
   awareness of what's missing. Desired behavior: run every weekday with the
   correct date, AND when a run finally succeeds after one or more failed days,
   build every missed weekday, not just the current one.

2. **The 6am run itself fails.** Observed error:
   `API Error: Can't reach the API server — check your internet or DNS (ENOTFOUND)`.
   This is the machine failing to resolve the Anthropic API host at run time, so
   the agent can't start and the run produces nothing. This is a Mac
   network/DNS-at-6am issue, not the Gmail connector and not the schedule.
   **Explicitly deferred** — not solvable from inside the skill. Listed here only
   so it isn't conflated with problem 1. Problem 1's fix (catch-up) is what makes
   these failures survivable regardless of root cause.

The scheduler confirms the task fires on time (`lastRunAt` was 06:04 on the day
these notes were written) but yields no file when it fails — so the failure is
inside the run, downstream of the schedule.

## Hard requirements from the user

- **GitHub Pages must always have content. Always.**
- An **empty/quiet day is effectively impossible** given the volume of
  newsletters in this inbox. In practice, "no content" would only happen because
  of a script/run failure — and a failure doesn't publish anything anyway. So
  elaborate quiet-day handling is likely over-engineered and should not drive the
  design. Catching for an empty day is fine as a guard, but it should not be
  doing heavy lifting.
- Don't assume the current structure is the only option. Code can be arranged
  differently. Not asking for a full overhaul, but genuinely consider
  alternative places/ways to solve this rather than only patching the existing
  prompt.
- Date handling should use a single source of truth and deterministic logic, not
  the model hand-deriving the day of week. (A prior draft offered "get the date
  from the environment or run `date`" and asked the model to derive the weekday —
  flagged as the model doing by hand what a library/script should compute
  deterministically.)

## How the existing pipeline actually works (verified by reading the code)

- **Digest generation** — the `ai-daily` scheduled task runs the
  `ai-newsletter-digest` skill inside Cowork. It fetches newsletter emails via
  the Gmail MCP and writes `ai-digest-YYYY-MM-DD.html` into the project root
  (`~/claude/Projects/AIDigest/`). It cannot do git (sandbox restriction).
  Task prompt lives at `~/claude/Scheduled/ai-daily/SKILL.md`, mirrored for
  version control at `skill/scheduled-task-prompt.md`.
- **Publishing** — `scripts/publish.sh` runs natively on the Mac via launchd
  (`scripts/com.divbox.digest-publish.plist`), every 5 minutes. It:
  - moves any `ai-digest-*.html` from the repo root into `dailies/`;
  - **regenerates `index.html` and `archive.html` from scratch** every run by
    globbing `dailies/ai-digest-*.html` and sorting by date;
  - sets `index.html` = the highest-dated digest (newest);
  - `git add -A`, commits, pushes only if something changed (safe to re-run).
- **Consequence that matters for catch-up:** because the publisher rebuilds the
  archive and front page deterministically from whatever files exist, **the order
  in which digests are created does not matter.** Building a missed older day
  after a newer one still produces a correctly date-sorted archive, and the front
  page stays the newest digest. (The user's manual habit of rerunning oldest-first
  was protecting a property the publisher already guarantees.)
- **Anything named `ai-digest-*.html` in `dailies/` gets published.** So if a
  quiet/empty digest file is ever written, it publishes publicly and, if newest,
  becomes the site's front page.

## Date / window convention (current)

- Digest is named by its run date.
- Monday's digest covers the previous Fri+Sat+Sun (`after:(D-3) before:D`).
- Tue–Fri cover the prior day (`after:(D-1) before:D`).
- This tiles cleanly: every calendar day is "owned" by exactly one weekday
  digest, so building every missed weekday leaves no gaps or overlaps.
- Gmail search: explicit `after:YYYY/MM/DD before:YYYY/MM/DD`, never
  `newer_than:`. Sources searched separately by sender (TLDR, Rundown AI, Alpha
  Signal, Import AI, Interconnects, The Batch, Latent Space).

## The unresolved design tension (where the last conversation stopped)

A catch-up run needs to know "up to which date have we handled." Anchoring on
"most recent `ai-digest-*.html` on disk" works only if every handled day leaves a
file. That collides with two things:

- The user does not want empty pages published, and believes empty days can't
  really occur anyway.
- If an empty day leaves no file, a naive catch-up can't tell "handled but empty"
  from "never ran," and would retry it forever.

Given the user's view that real empty days are essentially impossible (only
failures cause no-content, and failures don't publish), the recommendation is to
**not let empty-day handling drive the architecture.** Treat it as a minor guard,
and focus the design on: reliably determining the set of missing weekdays and
building them.

## Directions to explore in the fresh session

- **Where should catch-up logic live?** Options: in the skill prompt (model
  reasons about gaps), in `publish.sh`/a separate deterministic script that
  computes the missing-date list and hands it to the skill, or a small state file
  the skill reads/writes. The user leaned toward deterministic code over
  model-derived date math.
- **Reconsider the clock-based, day-of-week-in-prompt approach entirely** rather
  than assuming the fix is more prompt instructions.
- **How to know what's already built** without publishing empties or looping —
  e.g., derive from `dailies/` file dates, or a lightweight `built.log`/state
  record, or a non-published marker. Keep it minimal given empty days are a
  non-issue in practice.
- **Root-cause track (separate):** the 6am ENOTFOUND. Options include changing
  when/how the job runs, adding a network-readiness wait/retry before the run, or
  simply relying on catch-up to make the failure survivable. Not for this pass
  unless the user wants it.

## Loose ends / corrections to verify

- During the session that produced these notes, the assistant initially misread
  the run date (treated Tuesday as Monday) and, when backfilling, built only 2 of
  the 3 missing digests. As of that session, **`ai-digest-2026-08-21.html`
  (covering Aug 20's newsletters) was still missing** from `dailies/`. A fresh
  session should check current gaps in `dailies/` before assuming the archive is
  complete.
- The `new_files[@]: unbound variable` errors seen historically in `launchd.log`
  are from an older `publish.sh`; the current on-disk version handles the empty
  glob correctly. No action needed there.
- Any change to the `ai-daily` task prompt must also be mirrored into
  `skill/scheduled-task-prompt.md` in the same session, with a dated note (repo
  convention in `CLAUDE.md`).
