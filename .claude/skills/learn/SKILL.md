---
name: learn
description: "Capture a reusable lesson when something goes wrong, surprises you, or takes multiple attempts. Use this whenever the user corrects you, you discover a non-obvious constraint, or a workaround is found. Writes to .claude/rules/lessons.md (auto-loaded every session)."
argument-hint: "[lesson text]"
user-invocable: true
---

# Learn — Direct Lesson Capture

Record a lesson directly to `.claude/rules/lessons.md`, where it is auto-loaded every session.
No staging area, no promotion pipeline. Captured lessons are immediately active.

## Invocation

```
/learn "Always use obsidian move, never raw mv"
/learn
```

- With arguments: use the text directly as the lesson
- No arguments: scan the conversation for the most obvious correction, discovery, or
  workaround, then ask the user to confirm what to capture

## Lesson Format

One line per lesson. No multi-line entries, no continuation lines.

```
(YYYY-MM-DD) imperative sentence — reason if needed.
```

Fold context into the sentence, don't add separate lines:

```
(2026-06-08) Always use `obsidian move`, never raw `mv` — CLI updates wikilinks.
(2026-06-08) Use `CValidity.Description`, not `C.validity.Description` for validity structs.
(2026-06-08) Split boundary is 09:00 UTC on ex_date+1, not ex_date itself.
(2026-06-08) Never filter tape D trades from post-news bars — TRF prints are real retail volume.
```

If a lesson can't fit one line (~150 chars), it belongs in `rules/{domain}.md`,
not the lessons file. /reflect handles that promotion.

## Process

### Step 1: Extract the Lesson

If `$ARGUMENTS` is provided, use the text directly.

If no arguments, scan the conversation for:
- User corrections ("no, use X not Y", "actually...", "that's wrong")
- Discoveries that surprised you or assumptions that were wrong
- Multi-attempt fixes (the root cause is the lesson, not the retries)
- Workarounds or gotchas encountered

Ask the user to confirm if ambiguous: "I think the lesson here is X. Capture that?"

### Step 2: Read Active Lessons

Read `.claude/rules/lessons.md`.

If the file doesn't exist, create it with this header:

```markdown
# Lessons
# Active constraints — apply these during work.
# If you catch yourself about to violate one, flag it to the user.
# Managed by /learn (capture) and /reflect (curate).
```

If the directory `.claude/rules/` doesn't exist, create it first.

### Step 3: Duplicate Check

Scan all active lessons for the same concept (semantic match, not string match).

**If similar lesson found:**
- Show BOTH originals side by side
- Propose a MERGED version that takes the best of both wordings
- Show a **"What is LOST"** line: explicitly state what information from each original
  is NOT present in the merged version
- User confirms the merge, chooses to keep both, or edits
- **NEVER auto-merge.** Always show and ask.

**If no match:** proceed to Step 4.

### Step 4: Archive Resurrection Check

**Only if no active duplicate was found in Step 3.**

Read `.claude/lessons-archive.md` (if it exists). If the same concept exists in the
archive, RESURRECT it: move it back to the active file and inform the user.

"Resurrecting archived lesson — this concept came back."

Skip this step entirely if a duplicate was found in Step 3 (no need to read the archive).

### Step 5: Quality Gate + Write

Before writing, push back on situational captures:
"This sounds specific to today's bug. Reusable pattern or one-time fix?"

The user can override ("save it anyway"). The gate is a nudge, not a block.

After confirmation, append the lesson to `.claude/rules/lessons.md`:

```
(2026-06-07) Always use `obsidian move`, never raw `mv` — CLI updates wikilinks.
```

After writing, show the passive count:

```
Lessons: N active
```

No prompt, no nudge, no suggestion to run /reflect. The user sees the count and decides.

## Rules

1. **Never write without user approval.** Show the entry, wait for confirmation.
2. **Never auto-merge duplicates.** Show both versions, proposed merge, what is LOST.
   User decides.
3. **One lesson per /learn call.** Keep it atomic. Multiple lessons = multiple calls.
4. **Be specific.** "Always use obsidian move for note moves" is good.
   "Remember to use the right commands" is too vague — push back and ask for specifics.
5. **Resurrection over duplication.** If the concept exists in the archive, resurrect it
   instead of creating a new entry.
6. **No metadata from the user.** Date is automatic. The user provides only the lesson text.
