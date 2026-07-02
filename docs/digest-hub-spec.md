# AI Digest Hub — Spec

Status: architecture settled, one open item remains (see Open Questions).

## Problem

The digest already generates daily as a standalone HTML file, but getting it in front of colleagues is manual: download to Downloads, iMessage to self, download again on the work computer, share in a chat during a call. Each digest is also a one-off file — no running archive, no "latest" link to bookmark or pin.

## Goals

- One stable URL colleagues can pin/bookmark that always shows today's digest, no manual sharing per day.
- Zero manual steps between the digest generating and it being live on that URL.
- Earlier digests stay reachable via a simple archive list, grouped by month.
- Live well before colleagues need it — the digest runs at 6:06am M–F, so there's hours of slack before any morning meeting.

## Non-goals (v1)

- No auth/access control on the hub — public repo, public Pages site. If that changes later, re-scope.
- No search across archived digests, no RSS feed, no email notifications. Just a page with links.
- No redesign of the digest HTML itself — the template stays as-is; this is purely a distribution layer on top.
- No VM, no self-hosted webserver, no cron-on-a-server — GitHub Pages replaced that entire leg (see Locked Decisions).

## Locked decisions

- **Repo scope:** the whole `Claude Training` project folder is the git repo.
- **Visibility:** public repo.
- **Hosting:** GitHub Pages, serving from the `main` branch root. No work VM involved at all.
- **Archive layout:** links grouped by month.
- **Where the git work happens:** entirely on the maintainer's Mac, via a local script — not inside the Cowork sandbox, and not inside the skill itself.
- **Change detection:** `git diff` after regenerating, not a sentinel/marker file. No-op if nothing changed.
- **Dated digests live in `dailies/`**, not the repo root — moved there by the publish script, not the skill.

One consequence of "whole folder as repo" worth remembering: everything in `Claude Training` is public, including `CLAUDE.md` and the packaged skill. Nothing there looks sensitive today — just keep that in mind for anything dropped into this folder going forward.

## Why the skill doesn't change

The skill runs inside Cowork's sandboxed environment — a separate container from the Mac, even though it can write files directly into the real project folder (that's a mount, not a copy step). It does not have the Mac's SSH keys or git credentials, so no matter which skill executes it, pushing to GitHub from inside that sandbox needs its own separate credential to be provisioned and kept fresh across daily runs — complexity worth avoiding.

The fix is to keep git entirely off the Cowork side. The skill keeps doing exactly what it does today: write `ai-digest-YYYY-MM-DD.html` into the project root. Everything past that point — moving the file into `dailies/`, regenerating `index.html`/`archive.html`, committing, pushing — is a separate script that runs natively on the Mac, using the Mac's own already-configured git credentials. Claude is out of the loop for that entire leg.

## Architecture

```
Claude Training/                    (repo root = GitHub Pages source)
├── index.html                      regenerated each run — always the latest digest
├── archive.html                    regenerated each run — links grouped by month
├── .nojekyll                       disables GitHub's Jekyll processing (plain HTML only)
├── README.md
├── .gitignore                      excludes .DS_Store, publish.log, launchd.log
├── CLAUDE.md                       project instructions — must stay at root
├── dailies/
│   └── ai-digest-YYYY-MM-DD.html   one per run day, moved here by publish.sh
├── scripts/
│   ├── publish.sh
│   └── com.divbox.digest-publish.plist
├── docs/
│   └── digest-hub-spec.md          (this file)
└── skill/
    └── ai-newsletter-digest.skill
```

`index.html` is a full copy of the day's digest content, not a redirect — so a pinned link always shows today's content with no extra hop or JS dependency.

Only `index.html`, `archive.html`, and `.nojekyll` are pinned to the repo root by how GitHub Pages works. `CLAUDE.md` is pinned to root by how Cowork reads project instructions. Everything else (`scripts/`, `docs/`, `skill/`) is organizational preference, moved by hand — not something any automation depends on, apart from `publish.sh`'s own `cd` line needing to match wherever it actually lives.

## Pipeline (publish.sh, runs on the Mac via launchd — not part of the skill)

Runs every 5 minutes plus once at login. Safe to run constantly since it's a no-op unless something's actually new:

1. Move any `ai-digest-*.html` sitting in the repo root into `dailies/`.
2. Find the newest file in `dailies/`, copy its content into `index.html`.
3. Regenerate `archive.html` — list every file in `dailies/`, grouped by month, newest month first.
4. `git add -A`. If `git diff --cached` shows nothing staged, stop — nothing to publish.
5. Otherwise, commit and push. GitHub Pages picks up the push automatically (typically live within a minute or two).

## GitHub Pages setup (one-time, done in the GitHub UI)

Repo Settings → Pages → Source: Deploy from a branch → `main` / `(root)`. After that, every push from `publish.sh` triggers an automatic deploy — no separate hosting step, no server to maintain.

## Requirements

**P0:**
- `publish.sh` moves files, regenerates `index.html`/`archive.html`, and pushes correctly.
- GitHub Pages is enabled and serving from the repo root.
- `launchd` agent survives login/reboot without manual restart.

**P1:**
- Quick manual test of a quiet day (no newsletters found) to confirm the hub keeps showing the prior day's index rather than erroring.

**P2 (explicitly deferred):**
- Any access control, since this is public by choice for now.
- Pruning old digests from the repo — at ~260 files/year and a few KB each, this isn't a real problem for years.

## Open questions

- **(You)** GitHub personal access token / credential setup for `publish.sh`'s push — confirm which credential method (SSH key vs. HTTPS credential helper) is already configured for this repo on your Mac, since that's what the script relies on. Nothing to build here, just confirm it's in place before trusting the schedule.

## Rollout

1. `git init` (done), enable GitHub Pages in repo settings.
2. Run `publish.sh` once by hand, confirm `dailies/` gets populated, `index.html`/`archive.html` look right, and the push succeeds.
3. Install the `launchd` agent, confirm it fires on its own after a real digest run.
4. Run it for a few real mornings before sharing the link with colleagues.
