# AI Digest Hub

## Purpose
Dedicated project for the AI Digest Hub — a daily AI newsletter digest generated from Gmail newsletters by the `ai-newsletter-digest` Cowork skill, published as a static site via GitHub Pages. Graduated out of the "Claude Training" project on 2026-07-02 (that project tracked it while it was being built as a training-course exercise; see its `CLAUDE.md` for that history).

## Repo
- GitHub: `git@github.com:divbox/aidailydigest.git` (public)
- This whole project folder is the git repo root and the GitHub Pages source, serving from the `main` branch root.
- `docs/digest-hub-spec.md` has the full architecture spec (goals, locked decisions, pipeline). `TODO.md` has current setup/migration status — check it before assuming anything below is fully wired up yet.

## Newsletter Sources

All sources active in the skill. Skill runs M–F; Monday looks back 3 days (covers Fri–Sun).

| Newsletter | Sender | URL | Cadence | Treatment |
|---|---|---|---|---|
| TLDR AI | dan@tldrnewsletter.com | tldr.tech/ai | Daily | Headlines |
| The Rundown AI | news@daily.therundown.ai | therundown.ai | Daily | Headlines |
| Alpha Signal | news@alphasignal.ai | alphasignal.ai | Daily | Headlines |
| Import AI | importai@substack.com | jack-clark.net | Weekly | Deep dive |
| Interconnects | robotic@substack.com | substack.com/interconnects | Weekly | Deep dive |
| The Batch | thebatch@deeplearning.ai | deeplearning.ai/the-batch | Biweekly | Headlines |
| Latent Space | swyx+ainews@substack.com | latent.space | Daily (AI News digest; occasional "AIEWF Daily Dispatch" during conference weeks from same sender) | Deep dive |

## Digest Structure

- **Tab 1 — Headlines:** All stories grouped by category (Safety & Policy / Tools & Products / Models & Research / Business & Industry). Source filter pills. High-signal badge when 3+ sources cover the same story.
- **Tab 2 — Deep Dives:** Extended analysis for Import AI, Interconnects, and Latent Space stories.
- **Fallback block:** Static "best of AI" links shown when no newsletters found for the target date.

## Digest Behavior

- Run schedule: M–F (no weekends), 6:06am — this is a Cowork scheduled task, stored independently of this project folder, not deleted or affected by the project split. Its prompt now points here (`/Users/divbox/claude/Projects/AIDigest/`) as of 2026-07-02.
- Date window: yesterday's date only (Monday: previous 3 days)
- No content found: renders a "quiet day" notice; fallback block rises to top
- Processed emails (i.e. ones that made it into that day's digest) get the `aidigest` label applied and `INBOX` removed — done as the last step, only after the HTML file saves. Emails that didn't make the cut stay in the inbox.

## Maintenance

- The Cowork scheduled task's prompt (`ai-newsletter-digest`, stored at `/Users/divbox/claude/Scheduled/ai-newsletter-digest/SKILL.md`, outside this repo) is mirrored for version control at `skill/scheduled-task-prompt.md`. **Whenever the scheduled task's prompt is edited again, copy the new text into `skill/scheduled-task-prompt.md` in the same session and note the date/reason.** Nothing syncs these automatically — if they ever disagree, the live Cowork task is the source of truth, this file is just the diff trail.

## Hub Pipeline (not the skill's job — see docs/digest-hub-spec.md)

The skill only ever writes `ai-digest-YYYY-MM-DD.html` into this project's root. Everything past that — moving it into `dailies/`, regenerating `index.html`/`archive.html`, committing, pushing to GitHub — is `scripts/publish.sh`, run natively on the Mac via `launchd` (see `scripts/com.divbox.digest-publish.plist`). Git credentials and pushes never happen from inside Cowork's sandbox by design.

## To Consider Adding Later
- Ahead of AI (Sebastian Raschka) — PhD-level ML research
- The Gradient Dispatch — academic/research angle
