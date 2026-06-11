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
## Goal
[One sentence: what we're doing and why]

## State
- [File path]: [what was done / current status]
- [File path]: [what was done / current status]

## Decisions
- [Decision]: [why, so it doesn't get re-debated]
- [Decision]: [why]

## Next
[Exact next step, specific enough to act on immediately]

## Gotchas
- [Anything non-obvious: env quirks, things that look wrong but aren't, failed approaches to avoid]
```

After displaying, suggest: "You can now `/compact` to reset context, or close and resume later.
Copy the above into your next prompt to continue where you left off."

## Rules

1. **Generate from the live conversation, not from files.** The handoff captures what's in
   context right now, including reasoning and decisions that aren't written anywhere.
2. **Be specific, not comprehensive.** The goal is a launchpad, not a logbook. 5-15 lines total.
   If a section has nothing, omit it.
3. **Encode lessons, not attempts.** Don't write "tried X, Y, Z and they failed." Write
   "Use approach W (X/Y/Z don't work because...)."
4. **Use absolute or project-relative paths.** The handoff must work on both Linux and Windows.
5. **Decisions are the highest-value section.** Without them, post-compaction Claude re-debates
   settled questions. Always include the "why" for each decision.
