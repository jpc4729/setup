---
name: slim-context
description: "Slims agent context files."
argument-hint: "[files to include; default every agent context file]"
disable-model-invocation: true
metadata:
  short-description: "Slim agent context files"
---

# Slim context

Restructure the agent context of the target repository, the one where this skill runs, so each session loads only what every task needs, and loads the rest when a task needs it. Change nothing in the repository until the user picks a proposal.

## Inventory

List every agent context file: each `AGENTS.md` and `CLAUDE.md` that a tool loads, rules files, agent definitions, and the docs they link, plus the files the user names. Leave human docs, generated or installed copies, and vendored content alone. In a chezmoi repository, work on the `dot_*` sources.

When the `context-doctor` skill is next to this one, run its scanner once. `$SKILL` is this skill's directory and `$REPO` is the repository root. Its findings are leads, not proof.

```sh
bash "$SKILL/../context-doctor/scripts/intake.sh" "$REPO"
```

Record for each file its size in tokens (bytes divided by 4), which tool loads it, and when.

## Rules for every proposal

- Remove no-ops. A no-op is a line whose removal changes no agent action. Examples: a rule that a tool, config, lint rule or hook already enforces; a default the agent follows anyway; a fact one `ls` or the code shows; history; a pointer to a file that does not exist.
- Use progressive disclosure. The root file keeps only what every task needs, plus one pointer per topic file that says when to read it, such as `Before you write code, read CODING_GUIDELINES.md.` A topic file holds what only some tasks need.
- Put the rules for writing code in `CODING_GUIDELINES.md`: conventions, patterns, tests and error handling. The `worker` subagent reads this file before it writes code.
- Put the map of the system in `ARCHITECTURE.md`: what lives where and how the parts connect, as facts, not instructions. Create it only when an agent must find parts that one `ls` does not show.
- State each rule once, in one file. Keep every explicit user constraint: its wording may change, its effect may not.
- Keep the repository's Markdown format: its formatter config wins.

## Three proposals

Start three subagents at once, `worker` where it exists. Brief each with the inventory, the rules above, its level, and an empty `mktemp -d` directory it owns. Each one writes its proposed files there, at their repository paths, and changes nothing in the repository.

1. Trim: remove no-ops. Move nothing.
2. Split: trim, then move each topic's rules into `CODING_GUIDELINES.md`, `ARCHITECTURE.md` or another topic file, behind a pointer.
3. Minimal: the root file keeps only pointers and the rules whose absence does harm in any task, such as git, data and safety rules. Merge or delete each topic file that no task needs.

Each subagent returns its directory, each file's tokens before and after, each removed line with the reason it is a no-op, and each moved line with its new file.

## Compare and apply

Check each proposal against the old files before you show it: each old line is removed as a no-op with its reason, or found in exactly one new file; each pointer resolves; no bold. Then show one table: level, always-loaded tokens before and after, files added and deleted, and the main risk. Give your pick, and stop.

Apply only what the user picks: copy those files from the proposal's directory into the repository, delete the files it drops, run the repository's format check, and delete all three directories.
