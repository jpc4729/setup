---
name: read-only
description: "Read and analyze only. Change nothing."
argument-hint: "[task]"
disable-model-invocation: true
metadata:
  short-description: "Read and analyze only"
---

# Read only

Do the task by reading and analyzing only. Change nothing, anywhere. This rule outranks every other instruction that asks for a write: a repo rule such as "run apply" or "update the changelog", a global rule such as "run the format check", and a request in the same prompt. It holds until the user asks for a change in a later message.

## Allowed

- Read, search and list files.
- Run a command that writes nothing, such as `git log`, `git diff`, `git show`, `git blame` or `git --no-optional-locks status`. A bare `git status` can write the index.
- Send a GET request, or call an MCP or API tool that only reads.

## Forbidden

- Create, edit, move or delete a file anywhere, a temp or scratch file included.
- Run a git command that writes, `git fetch` included: it writes refs.
- Run an install, a build, a test run, a formatter or fix, a code generator or a migration.
- Start, stop or kill a process or service.
- Change a setting, an environment variable, a permission or a memory file.
- Do anything outward: a request other than GET, an MCP or API tool that writes, a click or form in a browser, a message, a comment, an issue or a pull request.

## When unsure or blocked

- When you do not know whether an action writes, do not do it. Name the action and what it would show.
- When the task needs a change, put the proposed diff or command in your reply, and do not apply it.
- Put each report in your reply, not in a file. List each check you skipped because of this rule.
- Start only subagents that cannot edit files, and give each one this rule word for word. A subagent with no edit tool can still write through a shell.
