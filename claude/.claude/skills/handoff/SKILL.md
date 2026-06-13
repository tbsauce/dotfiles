---
name: handoff
description: "Generate a structured session summary for context preservation. Use when the session is getting long, before compacting, or when ending work to resume later. Prints to screen only."
argument-hint: "[optional focus hint]"
user-invocable: true
---

# Handoff — Session State Checkpoint

Generate a structured summary of the current session for continuity across compaction
or across conversations.

## Invocation

```
/handoff                              (auto-detect what matters)
/handoff "focus on the auth refactor" (guided focus)
```

## Process

### Step 1: Analyze the Session

Scan the conversation for:
- What the overall goal is
- Which files were created, modified, or read
- Key decisions made and their reasoning
- What was tried and failed (encode the lesson, not the attempt)
- What the next concrete step is
- Environmental quirks or gotchas discovered

If `$ARGUMENTS` is provided, use it as a focus hint to prioritize what to capture.

### Step 2: Generate and Display the Handoff

Produce a structured summary in this exact format and print it to screen:

```markdown
<branch> · <short-sha> · <N> dirty files · <clean|dirty|broken> · <UTC time>

## Goal
[One sentence: what we're doing and why]

## State
- DONE: [claim, file path]
- DONE (verified: `cmd`): [claim, file path]
- IN FLIGHT: [file path, stopping point]
- TODO: [bullet]

## Decisions
- [Decision]: [why, so it doesn't get re-debated]
- [Decision]: [why]

## Key values
- [verbatim values a prose summary would blur: MACs, IDs, thresholds, endpoints, error fingerprints — one per line, not already stated as a decision]

## Landmines
- [if-then, root-caused: "if you do X, Y happens because Z; do W instead"]

## Next action [SAFE | CONFIRM-FIRST]
[Exact next step, specific enough to act on immediately]
```

After displaying, suggest: "You can now `/compact` to reset context, or close and resume later.
Copy the above into your next prompt to continue where you left off."

## Rules

1. **Generate from the live conversation, not from files.** The handoff captures what's in
   context right now, including reasoning and decisions that aren't written anywhere.
2. **Be specific, not comprehensive.** The goal is a launchpad, not a logbook. 15-25 lines total.
   If a section has nothing, omit it.
3. **Encode lessons, not attempts.** Landmines prefer if-then, root-caused form ("if you
   do X, Y happens because Z; do W instead"). If the cause isn't known, write what you
   do know rather than skipping the landmine. Don't write "tried X, failed."
4. **State bullets naming a file use absolute or project-relative paths.** TODO bullets
   without a file path are fine.
5. **Decisions are the highest-value section.** Without them, post-compaction Claude re-debates
   settled questions. Always include the "why" for each decision.
6. **Anchor line metadata is live, not summarized.** Pull branch, short sha, dirty file count,
   and UTC time from `git` and the clock — not from the conversation. Outside a repo, drop the
   git fields and keep the UTC time. Status: `clean` = clean tree or expected-dirty, claims
   verified · `dirty` = uncommitted work or unverified claims · `broken` = failing
   build/tests, broken mid-edit, live issue.
7. **Verification is earned.** A `DONE (verified: cmd)` line requires the cmd to be visible
   in this session's transcript — no reconstruction from memory. Cap at 2 verified entries
   per handoff; reserve for claims where re-checking on resume costs meaningful time.
   Everything else is plain `DONE`.
8. **Tag Next action `CONFIRM-FIRST`** when it touches: `rm`, `git reset --hard`,
   `git push --force`, schema migrations, or shared state (prod DB, deployed config, shared
   branch). Otherwise `SAFE`.
