---
name: log
description: Display the dotfiles changelog — recent actions, file changes, and session history. Use when starting a conversation, reviewing what happened, or checking what was changed recently.
---

Read and display the contents of `~/dotfiles/.claude/changelog.md`.

## Behavior

1. Read the changelog file
2. If `$ARGUMENTS` is provided, filter entries:
   - Date (e.g., `2026-03-15`) → show only that date's entries
   - Keyword (e.g., `stow`, `polybar`) → show entries mentioning that term
   - Number (e.g., `3`) → show the last N entries
3. If no arguments, show the **5 most recent entries** (most recent first)
4. If the file has more entries than shown, note the total count

## Output Format

```
## Changelog (showing N of M entries)

### YYYY-MM-DD — Title
What: brief summary
Files: list of files touched
---
```

## Edge Cases

- **Empty changelog:** Say "No entries yet. Changes will be logged as work is done."
- **File missing:** Create it with a `# Changelog` header, then report it was initialized
- **Very long file (50+ entries):** Default to last 5, mention total count and suggest filtering
