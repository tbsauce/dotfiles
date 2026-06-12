---
name: learn
description: "Capture a reusable lesson when something goes wrong, surprises you, or takes multiple attempts. Use this whenever the user corrects you (especially a REPEAT correction — that means an existing lesson failed to fire), you discover a non-obvious constraint, or a workaround is found. Writes to .claude/rules/lessons.md (auto-loaded every session)."
argument-hint: "[lesson text]"
user-invocable: true
---

# Learn — Lesson Capture + Routing

Record a lesson to `.claude/rules/lessons.md`, where it is auto-loaded every session.
Captured lessons are immediately active. /learn is a ROUTER, not just an appender:
content that isn't a behavioral lesson gets pointed to where it belongs.

## Invocation

```
/learn "Always use obsidian move, never raw mv"
/learn
```

- With arguments: use the text directly as the lesson
- No arguments: scan the conversation for the most obvious correction, discovery, or
  workaround, then ask the user to confirm what to capture

## Lesson Format

One line per lesson. No multi-line entries, no continuation lines. Date trails the line.

```
imperative sentence naming its firing situation — reason. (YYYY-MM-DD)
```

Examples:

```
Always use `obsidian move` for note moves, never raw `mv` — the CLI updates wikilinks. (2026-06-08)
Use `CValidity.Description`, not `C.validity.Description` for validity structs. (2026-06-08)
Split boundary is 09:00 UTC on ex_date+1, not ex_date itself. (2026-04-04)
Never filter tape D trades from post-news bars — TRF prints are real retail volume. (2026-05-06)
Remove stale Singleton{Lock,Socket,Cookie} from ~/.var/app/<id>/cache/<app>/ when a Chromium Flatpak silently exits 0. (2026-04-25) → .claude/dossiers/flatpak-singleton-lock.md
```

Two format requirements, both checked at the quality gate:

- **The line must name its firing situation.** A lesson that doesn't say WHEN it applies
  can never fire. "Be careful with Library edits" fails; "Move Library/ notes back to
  Inbox/ before editing" passes.
- **The line must fit ~150 chars.** If it can't, it isn't a lessons.md entry — route it
  to `rules/{domain}.md` (Step 2).

**Date ledger.** The trailing parens are the lesson's event ledger. Two event types:

- `re YYYY-MM-DD` — recurred or reinforced: the lesson came up again, or visibly
  prevented a mistake
- `ov YYYY-MM-DD` — overridden: the lesson fired where it shouldn't have applied

Example: `(2026-03-01, re 2026-06-10, ov 2026-06-11)`. One or more `re` dates
(= two distinct incidents) makes it a promotion candidate for /reflect. `ov` dates make
it a NARROW candidate — the scope is wrong, not the lesson.

**Dossier pointer (optional).** When a saga lives behind the rule (long investigation,
evidence, version history), the line ends with a pointer to its case file AFTER the
date: `imperative — reason. (YYYY-MM-DD) → .claude/dossiers/<slug>.md`. Date stays
inside the canonical line shape; the pointer is always the last element. Same
location in every project, vaults included. The pointer doesn't count against the
~150 chars. The line is the reflex; the dossier
is the story. Dossiers are Claude's operational memory: cold storage, never
auto-loaded, zero context cost. They are NOT knowledge notes — if one turns out to
contain real domain knowledge, extract that into the project's knowledge system and
keep the dossier as the operational record.

## Process

### Step 1: Extract

If `$ARGUMENTS` is provided, use the text directly.

If no arguments, scan the conversation for:
- User corrections ("no, use X not Y", "actually...", "that's wrong")
- Discoveries that surprised you or assumptions that were wrong
- Multi-attempt fixes (the root cause is the lesson, not the retries)
- Workarounds or gotchas encountered

Ask the user to confirm if ambiguous: "I think the lesson here is X. Capture that?"

### Step 2: Route

Classify before writing. Most captures are lessons; the rest get pointed to their real home:

| Content | Destination |
|---------|-------------|
| Behavioral lesson, project-specific, fits one line | `.claude/rules/lessons.md` (default) |
| Stable convention or standard ("always UTC, no exceptions") | propose `rules/{domain}.md` directly — it's law, not a lesson on probation |
| Counter-intuitive rule that needs evidence to survive (a confident future Claude would "fix" it backwards) | propose `rules/{domain}.md` WITH the evidence kept (numbers, failing example) |
| Universal, nothing project-specific ("grep all call sites before closing a bug") | offer `~/.claude/CLAUDE.md` (global — taxes every project, highest bar) or keep local; user decides |
| Plain fact about the codebase | point to README/docs/CLAUDE.md — not a lesson |

Routing is a proposal like everything else. If the user says "just save it as a lesson",
save it as a lesson. Never block capture.

### Step 3: Duplicate Check

One pass over `.claude/rules/lessons.md`, `.claude/rules/*.md`, and CLAUDE.md
(semantic match, not string match).

**If found in lessons.md — the important case.** Ask ONE question:

"This already exists: `<line>`. Did the mistake happen again (it failed to fire), did it
fire where it shouldn't (override), or are you just re-capturing?"

- **Failed to fire** → the wording failed. Propose a REWRITE: sharper situation naming,
  stronger imperative. Update the ledger: `(orig-date, re YYYY-MM-DD)`.
- **Fired wrongly** → the scope failed. Mark `ov YYYY-MM-DD` and propose a NARROW
  rewrite: a tighter firing situation that excludes this case.
- **Re-capture** → keep the wording, mark it reinforced: `(orig-date, re YYYY-MM-DD)`.

**If found in rules/ or CLAUDE.md:** it's already law. Say where, write nothing —
unless the user is correcting the law itself, then propose editing that rule.

**If a similar-but-different lesson exists:** show BOTH originals, propose a MERGED
version, and include an explicit **"What is LOST"** line stating what information from
each original is NOT in the merge. User confirms, keeps both, or edits.
**NEVER auto-merge.**

### Step 4: Archive Resurrection

Only if Step 3 found nothing. Read `.claude/lessons-archive.md` (if it exists). If the
same concept is archived, RESURRECT it: move it back to the active file, mark it
`(orig-date, re YYYY-MM-DD)`, and inform the user:

"Resurrecting archived lesson — this concept came back."

### Step 5: Quality Gate + Write

Push back on captures that fail either check:

- Situational: "This sounds specific to today's bug. Reusable pattern or one-time fix?"
- No firing situation: "When would this apply? I can't tell from the wording."

The user can override ("save it anyway"). The gate is a nudge, not a block.

**Saga check — offer a dossier.** Char count is NOT the trigger (over ~150 routes to
rules/ in Step 2). The trigger is the story: the capture came from a multi-attempt
investigation, dead ends worth recording, evidence/numbers worth keeping, a reverted
approach — or the lesson is counter-intuitive and needs its proof preserved. If so,
draft BOTH while the context is fresh and present them together: the one-liner
(ending in `→ .claude/dossiers/<slug>.md`) and the dossier draft. The user approves
line only, both, or neither. When unsure, default to line-only and offer the dossier
in one sentence. Never push.

Dossier template (`.claude/dossiers/<slug>.md`):

```markdown
# <Short title> — dossier
status: active — owner: lessons.md
created: YYYY-MM-DD

## Rule
<the one-liner verbatim, as captured>

## What happened
<the incident: context, what was attempted, what broke or surprised — a few sentences>

## Evidence
<numbers, error messages, file:line refs, outputs — the liftable proof>

## Dead ends
<what was tried and why it failed — the "don't re-try this" section>

## Scope
<where it applies / where it doesn't>

## History
- YYYY-MM-DD — <new incident, narrowed, extracted to a note, ...>
```

Template rules: `Rule`, `What happened`, and at least ONE of `Evidence`/`Dead ends` are
required — a dossier with neither evidence nor dead ends shouldn't exist (the line's
reason clause was enough). `Scope` and `History` are optional; omit empty sections
entirely, never leave bare headers. `Rule` is frozen at capture — the live line lives
in lessons.md; a major rewrite gets one History line, not a sync. Distill, don't
transcribe: a dossier is a case file, typically 10-40 lines.

If `.claude/rules/lessons.md` doesn't exist, create it (and `.claude/rules/` if needed)
with this header:

```markdown
# Lessons
# Active constraints — apply these during work.
# If you catch yourself about to violate one, flag it to the user.
# Managed by /learn (capture) and /reflect (curate).
```

Append the approved lesson. If a dossier was approved with it, write the dossier to
`.claude/dossiers/` (create the directory if needed).

### Step 6: Budget Check

Count active lessons after writing.

- **≤ 20:** report passively: `Lessons: N active`
- **> 20:** over budget — forced-rank eviction. Name the lesson that defends its seat
  worst ("if this vanished, what would break next month?") and propose exactly ONE
  action for it inline: ARCHIVE it, or PROMOTE it if it's promotion-ready. One
  proposal, y/n. Not a full /reflect.

Curation rides capture because capture is the only event that reliably happens.
The budget never blocks the capture itself.

## Rules

1. **Never write without user approval.** Show the entry, wait for confirmation.
2. **Never auto-merge duplicates.** Show both versions, proposed merge, what is LOST.
3. **One lesson per /learn call.** Atomic. Multiple lessons = multiple calls.
4. **Every lesson names its firing situation.** Push back if it doesn't.
5. **Resurrection over duplication.** An archived concept that returns gets resurrected.
6. **Re-correction means the wording failed.** A lesson that existed but didn't prevent
   the mistake gets rewritten, not just reinforced.
7. **Override means the scope failed.** A lesson that fired where it shouldn't gets a
   NARROW rewrite and an `ov` date — not deletion.
8. **Never block capture.** Routing, gates, and budgets are nudges; "save it anyway" wins.
9. **No metadata from the user.** Dates are automatic. The user provides only the lesson.
10. **Dossiers follow their lesson.** Any action that moves, merges, or resurrects a
    pointered lesson — including Step 6 evictions — keeps the pointer on the surviving
    line or tombstone and updates the dossier's `status:` header.
