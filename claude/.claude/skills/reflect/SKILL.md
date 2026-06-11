---
name: reflect
description: "Curate and sharpen the active lesson list. Use at end of session, when lessons are piling up, or when the user wants to clean house. Detects contradictions, proposes merges/promotions/archives, narrows lessons that misfired, rewrites lessons that failed to fire, heals legacy lesson layouts."
user-invocable: true
---

# Reflect — Session Review + Lesson Curation

Scan the session for missed lessons, then curate the active lesson list.
The pruner, not the gatekeeper. All actions are proposals.

## Invocation

```
/reflect            (full review: layout check + session analysis + curation)
/reflect session    (session analysis only — extract lessons, skip curation)
```

/reflect is the deep clean, run manually. Incremental curation does NOT wait for it:
/learn proposes one curation action whenever the file is over budget (>20 active).

## File Locations

| File | Purpose |
|------|---------|
| `.claude/rules/lessons.md` | Active lessons (auto-loaded every session) |
| `.claude/settings.json` | Enforcement tier: hooks + permission/deny rules (top promotion destination) |
| `.claude/rules/{domain}.md` | Promoted cross-cutting rules (permanent, auto-loaded) |
| `.claude/lessons-archive.md` | Cold storage + tombstones (append-only, resurrection via /learn) |
| `.claude/dossiers/` | Case files behind complex lessons — cold, never auto-loaded; pointers travel with the line (see Dossier Lifecycle) |
| `.claude/skills/*/SKILL.md` | Graduation targets (project-owned skills ONLY) |

## Process

### Step 0: Layout Check

Lessons rot fastest in dead locations. Cheap check, run every time, skip silently if
the layout is already canonical:

- A `## Lessons` section inside CLAUDE.md (legacy)
- A `.claude/lessons.md` file (manual-pointer era, often orphaned)
- An active file missing the 4-line contract header /learn creates
- An orphaned dossier: a file in `.claude/dossiers/` whose filename appears nowhere in
  lessons.md, the archive, rules/, or skill files — propose re-linking it to its owner
  or adding an archive tombstone for it; never delete it

If any are found, propose a one-time migration as a numbered batch: entries move to
`.claude/rules/lessons.md` in one-line format (date trailing); entries too big for one
line move to `rules/{domain}.md` WITH their evidence preserved; the legacy store is
emptied, leaving a one-line pointer to the new location. User approves before anything
moves.

### Step 1: Session Analysis

Review the conversation for patterns worth capturing:

- **Re-corrections — highest value:** a correction that matches an EXISTING lesson means
  that lesson failed to fire. Propose REWRITE (sharper situation naming, stronger
  imperative) and add a `re` date. Never just re-confirm it.
- **Overrides:** the user waved off a lesson that fired ("not here", "doesn't apply") →
  add an `ov` date, propose NARROW
- **Corrections:** user said "no, use X not Y" or "actually, that's wrong"
- **Lessons that fired:** a lesson visibly prevented a mistake this session → propose
  adding a `re` date (promotion evidence)
- **Wrong assumptions:** something you believed that turned out false
- **Multi-attempt fixes:** took more than 1 try (the root cause is the lesson)
- **Workarounds:** unexpected behavior that required a non-obvious solution
- **Uncorrected inefficiencies:** something done wastefully this session that nobody
  flagged — repeated searches for the same thing, silently abandoned dead ends,
  avoidable retries → propose capture. The user not noticing doesn't mean no lesson.

For each new finding, follow the /learn flow: route, dedup, gate, user approves.
If nothing was found, say: "Clean session, nothing to capture."

If `$ARGUMENTS` is "session", stop here. Skip Steps 2-3.

### Step 2: Lesson Curation

Read all entries in `.claude/rules/lessons.md`. Review oldest-first.

#### Pre-check: Contradiction Scan

Before per-lesson review, scan for pairs of lessons that prescribe conflicting actions
for overlapping scope. If found, flag immediately:

```
CONTRADICT:
  A: Never use git mv — breaks wikilinks (2026-05-10)
  B: Use git mv for renames so git tracks the history (2026-06-01)
  These prescribe opposite actions for the same operation. Which is correct?
```

#### Per-Lesson Review

For each lesson (oldest-first), evaluate and propose the first action that fits.

**Actions** (all proposals, user approves):

| Action | Condition | What happens |
|--------|-----------|--------------|
| MERGE | Two lessons with high semantic overlap | Show both + proposed merge + "what is LOST" |
| NARROW | Has `ov` date(s), or fired this session where it shouldn't | Propose a tightened firing situation that excludes the override cases; ledger kept intact |
| PROMOTE | Has one or more `re` dates (recurred and held), OR violating it causes real damage — and it's stable, not still being figured out. `ov` dates argue AGAINST promotion (scope unstable — NARROW first) | Rewrite into a proper rule at the right destination tier (see Promotion Format) |
| GRADUATE | 3+ lessons cluster around one domain AND the synthesis test passes (see Graduation Mechanics) | Absorb into a project-owned skill's `## Operational Lessons` section |
| ARCHIVE | Applies to a situation that no longer exists, OR already captured in a rule | Move to `lessons-archive.md` |
| REWRITE | Vague, hedging, multi-line, doesn't name its firing situation, legacy date-first format, or missing inline example on a syntax/format lesson | Propose sharpened text (not auto) |

**Staleness is content-based, not calendar-based:**
- "Is this already captured in a rule?" → ARCHIVE (or GRADUATE if cluster)
- "Does this apply to a situation that no longer exists?" → ARCHIVE
- Never "is it N days old" — Claude can't compute date differences reliably, and
  old-but-true lessons are the most valuable ones. Recurrence (`re` dates), not age,
  is the promotion signal.

**One-line rule:** every active lesson is one line, date trailing:
`imperative — reason. (YYYY-MM-DD)` or `(orig-date, re YYYY-MM-DD, ov YYYY-MM-DD)`.
Legacy formats (date-first, WHY: blocks, continuation lines) get REWRITE to compress.
If an entry genuinely can't fit one line, it needed the space — PROMOTE it to
`rules/{domain}.md` with its evidence instead.

**Present proposals as a numbered list:**

```
Proposals:

1. REWRITE "be careful with Library edits" (2026-06-01)
   → "Move Library/ notes back to Inbox/ and set status: draft before editing." (no firing situation in original)

2. PROMOTE "obsidian move updates wikilinks, raw mv does not" (2026-05-28, re 2026-06-09)
   → rules/vault.md (tier 3 — applies to every session in this project):
     "Always use obsidian move for note moves, never raw mv or git mv. The CLI updates
     wikilinks; raw moves leave broken links." Tombstone to archive.

3. NARROW "always dry-run queries before running" (2026-05-20, ov 2026-06-05)
   → "Dry-run queries that scan >1GB before running." (override showed small queries don't need it)

4. ARCHIVE "workaround: restart flatpak after update" (2026-04-15)
   → situation no longer exists (bug fixed in v1.6)

5. MERGE two split-boundary lessons → show both + merge + what is LOST
```

User approves: "all" / "1, 3" / "none" / prose.

### Step 3: Summary Report

```
Reflect complete.
  Session:   1 captured, 1 rewritten (failed to fire)
  Promoted:  1 → rules/vault.md (tombstoned)
  Narrowed:  1
  Archived:  1
  ─────────────────────────
  Lessons: 12 active (budget 20) | Rules: 3 files
```

## Promotion Format

Promoted lessons are REWRITTEN into proper rules, not copy-pasted. The lesson is a
shorthand note; the rule is a clear directive Claude can follow.

**Destination gradient — promotion must reduce or scope attention cost, never just
relabel it.** Propose the highest tier that fits; every PROMOTE proposal names its
destination and a one-line why-this-tier:

1. **Enforcement** — a hook or permission/deny rule in `.claude/settings.json`.
   Zero tokens, cannot fail to fire. Right for mechanically-checkable rules
   ("never run command X", "never write to path Y").
2. **Project-owned skill or command file** — an `## Operational Lessons` section.
   Loads only when that work runs. Right for rules scoped to one kind of work.
3. **`rules/{domain}.md`** — auto-loads EVERY session. Reserve for genuinely
   cross-cutting law that applies to most sessions, regardless of task.

- Lesson: `obsidian move updates wikilinks, raw mv does not (2026-05-28, re 2026-06-09)`
- Promoted rule: `Always use obsidian move for note moves, never raw mv or git mv. The CLI updates wikilinks across the vault; raw moves leave broken links.`

**Counter-intuitive rules keep their evidence.** If a confident future Claude would
"fix" the rule backwards (it contradicts docs, intuition, or how things usually work),
the promoted rule MUST carry its proof: the numbers, the failing example, the date it
was re-learned. One-line purity applies to lessons.md, not to rules files. A dossier
pointer may ride along for the full history, but it never replaces the inline proof —
the dossier doesn't load at fire time.

Promotion creates or appends to the chosen destination. One rule per bullet. Group
related promotions into the same file. **The promoted lesson leaves a TOMBSTONE:** its
line moves to `lessons-archive.md` with the full date ledger plus
`| promoted → <destination>, YYYY-MM-DD`. The ledger is the rule's provenance — never
delete it. Any dossier pointer travels with the line into the tombstone, and the
dossier's `status:` header is updated (see Dossier Lifecycle).

Never promote into the main project instructions file (CLAUDE.md or equivalent).

## Graduation Mechanics

When 3+ lessons cluster around the same domain, apply the **synthesis test**: can you
write the principle that generates all of them plus unseen cases? If yes, propose
graduation. If all you can write is the bullets stapled together, it isn't ready —
keep them as lessons.

- **Synthesis precedes scaffolding.** Write the generating principle first (with the
  user), then place it.
- Default target: an existing **project-owned** skill — add an `## Operational Lessons`
  section. Graduated lessons load only when the skill runs — cheaper than rules/,
  which loads every session.
- **NEVER graduate into skills that are copied across projects or installed globally**
  (learn, reflect, handoff, and similar). Skills are the engine, identical everywhere;
  lessons are the fuel, project-specific. A project lesson baked into a shared skill
  poisons every other project. When unsure whether a skill is shared, ask.
- New skill ONLY if 3+ lessons have no existing skill home (rare). A newly minted skill
  MUST be scaffolded with the **skill-creator** skill — structure plus description and
  trigger tuning; the description decides whether the bundle ever loads. If
  skill-creator is not available in this project, stop and ask.
- Graduated lessons leave tombstones in the archive: full ledger +
  `| graduated → skills/<name>, YYYY-MM-DD`.
- Dossiers of graduated lessons stay in `.claude/dossiers/`, get cited as sources in
  the `## Operational Lessons` section, and have their `status:` header updated
  (see Dossier Lifecycle).

## Archive Mechanics

File: `.claude/lessons-archive.md` (created on first archive).

Format: same one-liner + archive metadata. Tombstone kinds — archived, promoted,
graduated; dossier pointers travel with the line:

```
workaround: restart flatpak after update (2026-04-15) | archived: 2026-06-07, bug fixed in v1.6
obsidian move updates wikilinks, raw mv does not (2026-05-28, re 2026-06-09) | promoted → rules/vault.md, 2026-06-11
prefer truth-table TCs for simple algorithms (2026-04-13, re 2026-05-13) | graduated → skills/tc-format, 2026-06-11
never filter tape D from post-news bars (2026-05-06) → .claude/dossiers/tape-d-trf.md | promoted → rules/data.md, 2026-06-11
```

Append-only. No scheduled reviews. Resurrection happens via /learn: if the same concept
is captured again, /learn finds the archived entry and resurrects it automatically.

## Dossier Lifecycle

Dossiers (`.claude/dossiers/`) are cold storage — never auto-loaded, zero context
cost. So they never move, are never deleted, and are never merged. The invariant is
bidirectional linkage: the lesson line carries the pointer, the dossier header
carries `status:` and owner. Every transition updates both ends.

| Lesson transition | Pointer (line side) | Dossier (file side) |
|---|---|---|
| REWRITE / NARROW | kept on the rewritten line | unchanged |
| MERGE | merged line keeps BOTH pointers — dossier files are never merged | unchanged |
| ARCHIVE | travels into the tombstone | stays; `status: lesson archived YYYY-MM-DD` |
| PROMOTE | rides on the promoted rule; inline evidence stays inline — the dossier supplements, never substitutes | stays; `status: promoted → rules/{domain}.md YYYY-MM-DD` |
| GRADUATE | the skill's `## Operational Lessons` cites the dossiers as sources | stays; `status: graduated → skills/<name> YYYY-MM-DD` |
| Resurrection | returns with the line (preserved in the tombstone) | `status: active` again |

If a dossier turns out to contain real domain knowledge (not just operational
history), suggest extracting it into the project's knowledge system (e.g., a vault
note through its normal pipeline); the dossier stays as the operational record with
a History line pointing to the extraction.

## Rules

1. **All actions are proposals.** Including REWRITE and NARROW. No auto-modifications.
   User approves every change.
2. **Present all proposals at once.** The approval protocol ("all" / "1, 3" / "none" /
   prose) handles volume. Don't artificially cap or require multiple runs.
3. **Promote to the highest destination tier that fits** (enforcement > project-owned
   skill/command > rules/{domain}.md) — never CLAUDE.md, never shared skills.
4. **Re-correction beats re-confirmation.** A lesson the user had to repeat is a failed
   lesson; rewriting it is worth more than any new capture.
5. **Graduate into project-owned skills only.** Shared skills stay verbatim-copyable.
6. **Tombstones, not deletion.** Promoted and graduated lessons move to the archive
   with their full ledger. Provenance never disappears. Dossier files are never
   deleted or merged — pointers travel, files stay.
7. **Be honest about empty sessions.** Nothing learned → say "clean session" and move
   on. Don't invent proposals to justify the command.
8. **Skip sections silently.** No contradictions → don't say "no contradictions found."
   Only show steps that have actual proposals.
9. **Merge ALWAYS shows "what is LOST."** Both originals, the proposed merge, and an
   explicit line stating what information from each original is NOT in the merged
   version. Silent information loss is the single highest-risk failure mode in this
   system.
