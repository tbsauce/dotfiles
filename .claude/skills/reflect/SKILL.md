---
name: reflect
description: "Curate and sharpen the active lesson list. Use at end of session, when lessons are piling up, or when the user wants to clean house. Detects contradictions, proposes merges/promotions/archives, rewrites vague text."
user-invocable: true
---

# Reflect — Session Review + Lesson Curation

Scan the session for missed lessons, then review active lessons for curation.
The pruner, not the gatekeeper. All actions are proposals.

## Invocation

```
/reflect            (full review: session analysis + lesson curation)
/reflect session    (session analysis only — extract lessons, skip curation)
```

Manual-only. No auto-triggers.

## File Locations

| File | Purpose |
|------|---------|
| `.claude/rules/lessons.md` | Active lessons (auto-loaded every session) |
| `.claude/rules/{domain}.md` | Promoted rules (permanent, auto-loaded) |
| `.claude/lessons-archive.md` | Cold storage (append-only, resurrection via /learn) |
| `.claude/skills/*/SKILL.md` | Graduation targets (existing skills only) |

## Process

### Step 1: Session Analysis

Review the conversation for patterns worth capturing:

- **Corrections:** User said "no, use X not Y" or "actually, that's wrong"
- **Wrong assumptions:** Something you believed that turned out false
- **Multi-attempt fixes:** Took more than 1 try to solve (the root cause is the lesson)
- **Workarounds:** Unexpected behavior that required a non-obvious solution

For each finding, follow the same flow as `/learn`: check for duplicates, propose the
entry, user approves. If nothing was found, say: "Clean session, nothing to capture."

If `$ARGUMENTS` is "session", stop here. Skip Step 2.

### Step 2: Lesson Curation

Read all entries in `.claude/rules/lessons.md`. Review oldest-first.

#### Pre-check: Contradiction Scan

Before per-lesson review, scan for pairs of lessons that prescribe conflicting actions
for overlapping scope. If found, flag immediately:

```
CONTRADICT:
  A: (2026-05-10) Never use git mv — breaks wikilinks
  B: (2026-06-01) Use git mv for renames so git tracks the history
  These prescribe opposite actions for the same operation. Which is correct?
```

Contradictions are flagged before per-lesson review.

#### Per-Lesson Review

For each lesson (oldest-first), evaluate and propose the first action that fits.

**Actions** (all proposals, user approves):

| Action | Condition | What happens |
|--------|-----------|--------------|
| MERGE | Two lessons with high semantic overlap | Show both + proposed merge + "what is LOST" |
| PROMOTE | Age >= 7 days (noise filter, not a staleness check) + specific + universal enough to be a standalone rule | Rewrite into a proper rule → `rules/{domain}.md` |
| GRADUATE | 5+ lessons cluster around same domain AND an existing skill covers that domain | Absorb into skill's `## Operational Lessons` section |
| ARCHIVE | Applies to a situation that no longer exists, OR already captured in a skill/rule | Move to `lessons-archive.md` |
| REWRITE | Vague, hedging, multi-line, or missing inline example on a syntax/format lesson | Propose sharpened text (not auto) |

**Staleness is content-based, not calendar-based:**
- "Is this already captured in a skill file or rule?" → ARCHIVE (or GRADUATE if cluster)
- "Does this apply to a situation that no longer exists?" → ARCHIVE
- Never use "has it been 90 days" — Claude can't compute date differences reliably

**Present proposals as a numbered list:**

```
Proposals:

1. PROMOTE (2026-05-28) "obsidian move updates wikilinks, raw mv does not"
   → rules/vault.md: "Always use obsidian move for note moves, never raw mv
     or git mv. The CLI updates wikilinks; raw moves leave broken links."

2. ARCHIVE (2026-04-15) "workaround: restart flatpak after update"
   → situation no longer exists (bug was fixed in v1.6)

3. REWRITE (2026-06-01) "be careful with Library edits"
   → sharpen to: "Always move Library/ notes to Inbox/ before editing"

4. REWRITE (2026-06-01) "use PascalCase for validity structs"
   → add inline example: "Use `CValidity.Description`, not `C.validity.Description` for validity structs."

5. REWRITE (2026-06-01) multi-line entry with WHY block
   → compress to one line: "Always use `obsidian move`, never raw `mv` — CLI updates wikilinks."
```

**One-line rule:** Every lesson must be one line. If an entry has WHY: or e.g.
continuation lines (legacy format), propose REWRITE to compress into a single
imperative sentence with the reason and/or inline backtick example folded in.
If it genuinely can't fit one line, propose PROMOTE to `rules/{domain}.md` instead.

User approves: "all" / "1, 3" / "none" / prose.

### Step 3: Summary Report

```
Reflect complete.
  Session:  1 new lesson captured
  Promoted: 1 → rules/vault.md
  Archived: 1
  Rewritten: 1
  ─────────────────────────
  Lessons: 12 active | Rules: 3 files
```

## Promotion Format

Promoted lessons are REWRITTEN into proper rules, not copy-pasted. The lesson is a
shorthand note; the rule is a clear directive Claude can follow.

- Lesson: `(2026-05-28) obsidian move updates wikilinks, raw mv does not`
- Promoted rule: `Always use obsidian move for note moves, never raw mv or git mv. The CLI updates wikilinks across the vault; raw moves leave broken links.`

Promotion creates or appends to `.claude/rules/{domain}.md`. One rule per bullet.
Group related promotions into the same file (e.g., all vault lessons → `rules/vault.md`).
Remove the lesson from the active file after promotion.

Never promote to the main project instructions file (CLAUDE.md or equivalent).

## Graduation Mechanics

When 5+ lessons cluster around the same domain and an existing skill file covers that
domain, propose absorbing them into the skill.

- Add an `## Operational Lessons` section to the target skill file (bullet list)
- Natural targets: any existing skill in the project's `.claude/skills/` directory
- New skill only if 5+ lessons have no existing skill home (rare)
- Remove graduated lessons from the active file

## Archive Mechanics

File: `.claude/lessons-archive.md` (created on first archive).

Format: same one-liner + archive metadata:

```
(2026-04-15) workaround: restart flatpak after update | archived: 2026-06-07, bug fixed in v1.6
```

Append-only. No scheduled reviews. Resurrection happens via /learn: if the same concept
is captured again, /learn finds the archived entry and resurrects it automatically.

## Rules

1. **All actions are proposals.** Including REWRITE. No auto-modifications. User approves
   every change. This is consistent with the vault's approval protocol.
2. **Present all proposals at once.** The approval protocol ("all" / "1, 3" / "none")
   handles volume. Don't artificially cap or require multiple runs.
3. **Promote to `rules/{domain}.md`**, never CLAUDE.md. CLAUDE.md is the vault's operating
   manual, not a dumping ground for lessons.
4. **Graduate into EXISTING skills only.** Never create a one-lesson skill. If 5+ lessons
   have no skill home, that's the rare case where a new skill is justified.
5. **Be honest about empty sessions.** If nothing went wrong and nothing was learned, say
   "clean session" and move on. Don't invent proposals to justify the command.
6. **Skip sections silently.** If there are no contradictions, don't say "no contradictions
   found." Just move to the next step. Only show steps that have actual proposals.
7. **Merge ALWAYS shows "what is LOST."** The proposal must display both originals, the
   proposed merge, and an explicit line stating what information from each original is
   NOT in the merged version. Silent information loss is the single highest-risk failure
   mode in this system.
