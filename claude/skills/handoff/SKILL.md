---
name: handoff
description: Use when the user asks for a handoff, to "write a handoff", to pass work to a new session, or to continue the work "in a new tab" / "in a new iTerm tab".
---

# Handoff

Write a short handoff so a fresh session can pick the work up cold, then optionally start that session.

## 1. Write the file

Path: `~/Projects/planning/{project}/YYYY-MM-DD-handoff[-topic].md` (today's date; add `-topic` if a handoff for
today already exists). Never put it in the project repo.

Keep it short (aim for under 40 lines). Only what the next session can't easily re-derive:

```markdown
# Handoff: {what's next} ({date})

Repo `{path}` ({branch}, clean/dirty; last merge or commit). Read first: {docs, plan files}.

## Decided with {user}
- {decisions and the reasoning behind them, so they aren't reopened}

## Facts found so far
- {findings, numbers, file:line pointers, dead ends already ruled out}

## Next
1. {ordered steps; name the plan file and the branch to use}

## Ways of working
{only the project-specific bits: build/test commands, merge rules, what needs the user's review, things not to do}
```

Rules:
- Facts, not narrative. No recap of the conversation.
- Say plainly what is unfinished or unverified.
- Point to existing plan or spec files instead of copying them.
- Use hyphens, not em-dashes.

## 2. Start the next session (only if asked, e.g. "in a new tab")

```bash
osascript <<'EOF'
tell application "iTerm"
  activate
  if (count of windows) = 0 then
    create window with default profile
  else
    tell current window to create tab with default profile
  end if
  tell current session of current window
    write text "cd {repo} && claude \"Pick up from the handoff at {handoff path}: {one-line goal}.\""
  end tell
end tell
EOF
```

You can't see the new tab, so tell the user to check it started.

## 3. Report

Give the handoff path, and in one or two lines what's in it.
