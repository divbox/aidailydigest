# Scheduled task prompt — `ai-daily`

This is a manually-maintained snapshot of the live prompt for the Cowork scheduled task, kept here purely for version history. **This file is not read by anything** — the actual source of truth is Cowork's own scheduled-task storage at `/Users/divbox/claude/Scheduled/ai-daily/SKILL.md` on the Mac, outside this repo (see `CLAUDE.md` / `docs/digest-hub-spec.md` for why: keeping git off the Cowork side avoids needing GitHub credentials inside the sandbox).

If the task prompt changes again, copy the new text in here by hand and note the date/reason below. There's no automation syncing these — if this file and the live task ever disagree, the live task wins.

**Last synced:** 2026-09-03 — replaced the FULL_CONTENT-based retrieval method (in place since 2026-08-07) after it broke for the third time in two months, each time patched differently and reactively (WebSearch → FULL_CONTENT+file-read → today's ad hoc jq extraction mid-run). Root cause: FULL_CONTENT was pulling the full HTML body (htmlBody) purely to throw it away, and the HTML is what caused the size overflow in the first place — confirmed directly against today's mail: TLDR's full message was 88.7KB vs. 12KB plain text, Rundown 120KB vs. 16KB, Latent Space 282KB vs. 57KB. New method: always call get_thread with messageFormat: PLAIN_TEXT, which omits htmlBody entirely and returns plaintextBody directly. This alone eliminated the overflow for TLDR and Rundown (verified: identical content, no overflow). It does NOT eliminate it for Latent Space specifically — that newsletter's AI Twitter Recap format is long enough in plain text alone (57.7K chars) to still overflow. For that case, added one fixed, tested fallback: extract plaintextBody from that same PLAIN_TEXT call's overflow-dump file using Python's json module (verified byte-identical to the content actually used in today's digest). jq was tried first and also worked, but was dropped in favor of Python since Python's availability in the sandbox is explicitly documented and jq's isn't — no new tool/dependency gets introduced into this procedure again without asking first. Also added: a thread must contain exactly one message or that source is skipped (no guessing which message is real); any failure outside the two documented paths (inline PLAIN_TEXT, or the PLAIN_TEXT-overflow-then-Python fallback) means skip that source and keep going, never invent a third method; and the run's final message must explicitly state which sources succeeded/were skipped and why, since that's what surfaces via notification (see note below — notifyOnCompletion still needs to be turned on from a regular session, it can't be set from inside a scheduled-task run itself).

**2026-08-07 (second pass)** — removed WebSearch/`web_fetch` from the skill entirely. Background: recent runs kept failing on WebSearch calls, and separately a digest entry turned up with specific content and a working link that couldn't be traced back to anything in its source email (Rundown AI, Aug 4 "White House" story) — meaning the skill was reaching outside the email for content in ways that weren't fully understood or documented, for headline sources too, not just the three deep-dive ones. Investigated live against real inbox mail (18 unprocessed emails, all 7 sources) before changing anything: `get_thread FULL_CONTENT` does reliably exceed the token limit on every source (confirmed on today's actual mail, 59k-190k chars), but the error response still saves the full raw email to a local file, and that file's `plaintextBody` field (as opposed to `htmlBody`, which is 90%+ tracking/CDN noise) reliably contains real, usable story content and — for Latent Space, Interconnects, Import AI, and most Rundown editions — a direct "Read Online" / "View this post on the web at" link to the actual article, with the real article content continuing right there in the plaintext body. TLDR carries real per-story links too, in a bracketed reference list near the end (mixed with ad/sponsor noise to filter out). Alpha Signal has real story text but every link is wrapped in its own click-tracker (`app.alphasignal.ai/c?...`) — decided that's fine to use as-is, no cleaner URL exists. New rule: every source is sourced from `plaintextBody` only, nothing is ever fetched from the open web, and if a story's content or link genuinely isn't in the email, the story (or that day's edition, e.g. the occasional Rundown non-roundup email) is just skipped — silently, not treated as a failure. Also corrected the task ID this file documents: the live task is `ai-daily` (this was previously written as `ai-newsletter-digest`, which is a disabled, stale duplicate that hasn't run since 2026-07-03 — the docs just never caught up when the task got recreated under a new name; that task and another dead duplicate, `ai-daily-digest`, have since been deleted). Also added a rule to use `/Users/divbox/claude/Projects/AIDigest/.tmp/` for any scratch/intermediate files instead of `/tmp`, since `/tmp` is shared across concurrent Cowork sessions and a stale file left there by an unrelated session had collided with a digest run before. No changes made to how the platform's content safeguard is handled — that's intentionally left alone, not something a prompt change should work around.

**2026-07-03 sync (prior):** fixed the Latent Space sender (was silently falling back to a broken subject-search) and switched deep-dive extraction (Import AI, Interconnects, Latent Space) from Gmail `get_thread` to WebSearch + `web_fetch` against the source site, since `get_thread` with `FULL_CONTENT` reliably exceeded the tool's token limit on these newsletters. See `feedback_digest_gmail_body_size` and `project_digest_latent_space_sender_fix` in Claude's memory for the full story.

---

Generate the daily AI newsletter digest using the ai-newsletter-digest skill.

You have access to Gmail via the connected Gmail MCP. Use it to fetch recent newsletter emails.

Follow the ai-newsletter-digest skill instructions, with these corrections taking priority over the skill's own text if they conflict:

1. Determine the date window: Monday = previous 3 calendar days (Fri/Sat/Sun), Tuesday–Friday = yesterday only. Use explicit Gmail date operators (after:YYYY/MM/DD before:YYYY/MM/DD) — never use newer_than:. Search each source separately by sender: TLDR AI (dan@tldrnewsletter.com), Rundown AI (news@daily.therundown.ai), Alpha Signal (news@alphasignal.ai), Import AI (importai@substack.com), Interconnects (robotic@substack.com), The Batch (thebatch@deeplearning.ai), Latent Space (from:swyx+ainews@substack.com — use this sender directly, never the skill's subject-search fallback). If a source has no email in the target window, skip it entirely — do not pull older issues.

2. Email body retrieval — this is a fixed, hard rule, same for every source and every run (2026-09-03 correction, replacing the FULL_CONTENT-based method used since 2026-08-07 — see the sync note above for why):

   a. Use search_threads / get_thread MINIMAL only to locate the thread ID and confirm a source has mail in the date window. Never treat the MINIMAL snippet as story content.

   b. Call get_thread with messageFormat: PLAIN_TEXT — never FULL_CONTENT, never RAW. This returns plaintext_body directly without the tracking-pixel/CDN-proxy HTML that used to cause size overflows.

   c. Check the response's messages array. It must contain exactly one message. If it contains zero or more than one, that's unexpected — skip this source for today (do not guess which message is the real one), note it as skipped with the reason "unexpected message count," and move on to the next source.

   d. If the PLAIN_TEXT call returns normally: read plaintextBody straight from the response. Done, no further steps needed for this source.

   e. If the PLAIN_TEXT call errors with "result exceeds maximum allowed tokens": this is expected for some sources (Latent Space in particular routinely runs long) and has one fixed handling method:
      - The error message gives a file path. Take just the filename and locate the Bash-reachable copy with: find /sessions/*/mnt/.claude/projects -name "<filename>"
      - Extract the body with Python only: python3 -c "import json; print(json.load(open('<path>'))['messages'][0]['plaintextBody'])" > <scratch file>, then read the scratch file normally.
      - Do not use jq or any other tool for this. Do not introduce any new tool or dependency into this procedure without stopping and asking the user first — this includes trying jq again.

   f. If anything else happens — a different error, the file isn't found, the JSON doesn't parse, plaintextBody is missing, or anything not covered by (c) or (e) — do not improvise a new extraction method. Skip this source for today, note it as skipped with the specific error, and continue with the remaining sources. The digest still gets built from whatever sources did work.

   g. Never use htmlBody. Never call WebSearch or web_fetch for any source, for any reason.

   h. Extracting each story's real link from plaintextBody: Latent Space, Interconnects, and Import AI open with "View this post on the web at [URL]" as literally the first line — use that URL. Rundown usually opens with a "**[Read Online](URL)" markdown link — use that URL; if a Rundown email doesn't follow this pattern, skip it entirely. TLDR lists real per-story links in a bracketed reference list ([N] https://...) near the end of the body — match the right one to each story and ignore ad/sponsor/referral noise in the same list. Alpha Signal wraps every link in its own click-tracker (app.alphasignal.ai/c?...) — use as-is.

   i. If a story's real content and/or a usable link genuinely isn't there, don't substitute anything from outside the email or from general knowledge — publish without a link or drop the story. Never fabricate or guess a link or a fact.

3. Extract stories, deduplicate across sources, categorize into: Safety & Policy, Tools & Products, Models & Research, Business & Industry

4. Write main summaries (2-4 sentences, punchy) and deep dives (Import AI, Interconnects, and Latent Space stories only).

5. Load the HTML template from the skill's assets/template.html and fill in all placeholders including SOURCE_PILLS (only for sources with content), TAB1_STORIES, TAB2_DEEPDIVES, DATE, STORY_COUNT, SOURCE_COUNT

6. Save the final file to /Users/divbox/claude/Projects/AIDigest/ as ai-digest-YYYY-MM-DD.html using today's date

7. Scratch/intermediate files: never write to /tmp directly. Use /Users/divbox/claude/Projects/AIDigest/.tmp/ instead (create it if missing).

8. Before finishing, state plainly in your final message: which sources were processed successfully, which (if any) were skipped and why, and the final story/source counts. This final message is what the user is notified with — it's the only place a failure gets reported, so it must be explicit, not buried in narration.

The user skims daily newsletters (TLDR AI, Rundown AI, Alpha Signal, The Batch) for headlines. Daily/weekly technical newsletters (Import AI, Interconnects, Latent Space) get full deep-dive treatment in Tab 2. Assume a technical reader who follows AI closely.
