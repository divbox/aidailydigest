# Scheduled task prompt — `ai-newsletter-digest`

This is a manually-maintained snapshot of the live prompt for the Cowork scheduled task, kept here purely for version history. **This file is not read by anything** — the actual source of truth is Cowork's own scheduled-task storage at `/Users/divbox/claude/Scheduled/ai-newsletter-digest/SKILL.md` on the Mac, outside this repo (see `CLAUDE.md` / `docs/digest-hub-spec.md` for why: keeping git off the Cowork side avoids needing GitHub credentials inside the sandbox).

If the task prompt changes again, copy the new text in here by hand and note the date/reason below. There's no automation syncing these — if this file and the live task ever disagree, the live task wins.

**Last synced:** 2026-07-03 — fixed the Latent Space sender (was silently falling back to a broken subject-search) and switched deep-dive extraction (Import AI, Interconnects, Latent Space) from Gmail `get_thread` to WebSearch + `web_fetch` against the source site, since `get_thread` with `FULL_CONTENT` reliably exceeded the tool's token limit on these newsletters. See `feedback_digest_gmail_body_size` and `project_digest_latent_space_sender_fix` in Claude's memory for the full story.

---

Generate the daily AI newsletter digest using the ai-newsletter-digest skill.

You have access to Gmail via the connected Gmail MCP. Use it to fetch recent newsletter emails.

Follow the ai-newsletter-digest skill instructions, with these corrections taking priority over the skill's own text if they conflict:

1. Determine the date window: Monday = previous 3 calendar days (Fri/Sat/Sun), Tuesday–Friday = yesterday only. Use explicit Gmail date operators (after:YYYY/MM/DD before:YYYY/MM/DD) — never use newer_than:. Search each source separately by sender: TLDR AI (dan@tldrnewsletter.com), Rundown AI (news@daily.therundown.ai), Alpha Signal (news@alphasignal.ai), Import AI (importai@substack.com), Interconnects (robotic@substack.com), The Batch (thebatch@deeplearning.ai), Latent Space (from:swyx+ainews@substack.com — use this sender directly, never the skill's subject-search fallback; Latent Space now publishes daily, not just weekly/irregular, so expect it in most runs). If a source has no email in the target window, skip it entirely — do not pull older issues.

2. Email body retrieval: `get_thread` with `FULL_CONTENT` reliably exceeds the tool's token limit on these newsletters (~80-120k chars of raw HTML per email). Never call it with FULL_CONTENT.
   - Headline sources (TLDR, Rundown, Alpha Signal, The Batch): use `search_threads`/`get_thread` with MINIMAL format (subject + snippet) as the story source. This is a skim for the reader, so it's an acceptable trade for speed.
   - Deep-dive sources (Import AI, Interconnects, Latent Space): after finding the relevant thread via MINIMAL format, resolve the article's public URL with a WebSearch for "<site> <exact subject line>" (Import AI → jack-clark.net, Interconnects → substack.com/interconnects, Latent Space → latent.space — check /Users/divbox/claude/Projects/AIDigest/CLAUDE.md's source table for the current list, it takes priority over anything in the skill doc), then `web_fetch` that page directly for the full deep-dive content. Fall back to snippet+subject only if search/fetch fails for that specific post — don't burn many tool calls chunking the Gmail body as a workaround, it doesn't work reliably.

3. Extract stories, deduplicate across sources, categorize into: Safety & Policy, Tools & Products, Models & Research, Business & Industry

4. Write main summaries (2-4 sentences, punchy) and deep dives (Import AI, Interconnects, and Latent Space stories only)

5. Load the HTML template from the skill's assets/template.html and fill in all placeholders including SOURCE_PILLS (only for sources with content), TAB1_STORIES, TAB2_DEEPDIVES, DATE, STORY_COUNT, SOURCE_COUNT

6. Save the final file to /Users/divbox/claude/Projects/AIDigest/ as ai-digest-YYYY-MM-DD.html using today's date

The user skims daily newsletters (TLDR AI, Rundown AI, Alpha Signal, The Batch) for headlines. Daily/weekly technical newsletters (Import AI, Interconnects, Latent Space) get full deep-dive treatment in Tab 2. Assume a technical reader who follows AI closely.
