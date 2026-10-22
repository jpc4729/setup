# Frontmatter and substitutions

Claude Code 2.1.306 reads these keys in the frontmatter of a skill's `SKILL.md`. Each line follows the key's schema text in the binary, plus what a test showed where the two differ.

## Keys

- `name`: the display name. It defaults to the name of the folder or file.
- `description`: the one-line summary in the skill listing and the Skill tool.
- `when_to_use`: when the model should reach for the skill. Claude Code adds it to the tool description.
- `argument-hint`: the placeholder text after the slash command name, such as `[path]`.
- `disable-model-invocation`: when true, only the user can start the skill, by its slash command.
- `user-invocable`: when false, the slash command is hidden, and only the model can start the skill.
- `allowed-tools`: tools that the skill grants from the skill call until the user's next message. A listed tool runs with no permission prompt. The key removes no other tool. Write a comma-separated or space-separated string, or a YAML list.
- `disallowed-tools`: the schema says the tools are "removed from the model" and the limit is "Cleared when the user sends the next message." In a test on 2.1.295, the tools stayed in the model's list, and each call returned "Permission to use Write has been denied.", also in `acceptEdits` mode. Keep a prose rule as well. A comma list with spaces, such as `Edit, Write, NotebookEdit`, works. `disallowedTools` is a second name for the same key.
- `model`: a model override, such as `haiku`, `sonnet`, `opus`, `fable`, a full model ID, or `inherit`.
- `effort`: `low`, `medium`, `high`, `max`, or an integer.
- `context: fork` with `agent`: the skill runs as a forked agent of that type. A fork runs in the background and reports back as a task notification, and `background: false` makes the caller wait. Native code-review sets its context in code, and runs as a fork in a normal session.
- `paths`: glob patterns. The skill loads only when the model touches a matching file.
- `hooks`: hooks that are active while the skill runs, in the same shape as `hooks` in `settings.json`. A `UserPromptSubmit` hook here first runs on the prompt after the one that starts the skill. The skills of one source, such as a repo, your own folder or a plugin, can register at most 1,024 hooks. When a policy allows hooks only from plugins and keeps out the hooks of a skill, the skill also loses its `allowed-tools`.
- `shell`: the shell for `!` command blocks, `bash` (the default on every platform) or `powershell`.
- `metadata`: a free map for the author's own fields. Claude Code keeps it on the loaded skill.

When the frontmatter does not parse, the skill loads with every key dropped and no warning: the name falls back to the folder name, and the description to the first line of the body. `claude plugin validate` on a folder named `skills` reports it.

## Skill listing

- `skillListingMaxDescChars` in `settings.json` cuts each description in the listing at 1536 characters by default.
- `skillListingBudgetFraction` sets the part of the context window for the whole listing, 0.01 by default. When the listing is longer, Claude Code shortens the descriptions to fit.

## Substitutions in the body

- `$ARGUMENTS`: all the arguments. `$ARGUMENTS[N]` and `$N` give one argument, counted from 0.
- With no placeholder in the body, Claude Code adds the arguments at the end as `ARGUMENTS: <arguments>`.
- `${CLAUDE_SKILL_DIR}`: the folder of the skill. Use it in each path to a script or reference file.
- `${CLAUDE_SESSION_ID}`: the ID of the current session.
- `` !`command` ``: Claude Code runs the command when the skill starts, and puts its output in the body. The `disableSkillShellExecution` setting turns this off, so say what to do when the output is missing.

## Other homes

- A home ignores a key that it does not know. It is never an error, so a typo in a key fails with no message.
- `disable-model-invocation: true` works in Claude Code, Cursor and Grok. Codex reads `policy.allow_implicit_invocation: false` in `agents/openai.yaml` instead, so set both.
- `paths` works in Claude Code and Cursor. `argument-hint`, `allowed-tools`, `model` and `effort` work in Claude Code and Grok.
