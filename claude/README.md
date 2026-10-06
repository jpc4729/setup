# claude

Claude Code's home. `./install.sh` copies this folder into `~/.claude` and merges `settings.json`. This README stays in the repo.

**The idea:** fast by default. Heavy checks run only when a mistake costs much. Hard rules live in code (hooks, deny rules), not in more text.

## TL;DR

- Edit here, never in `~/.claude`. Then re-run `./install.sh`.
- Ask plainly. Claude sizes the work. Small work stays Fast.
- Say **"verify this"** for a second opinion, **"align first"** for options, **"use the planner"** for work that needs more than one sitting.
- Claude commits only when you ask.

## What is here

| Path                           | What it is                                            | Why                                                                                                                |
| ------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `CLAUDE.md`                    | Rules for the main session                            | One short core. Less text, better adherence.                                                                       |
| `settings.json`                | Merged into `~/.claude/settings.json` by `install.sh` | Repo keys win. Claude Code keeps the keys it writes.                                                               |
| `agents/`                      | `scout`, `verifier`, `worker`, `planner`              | A fresh context for a wide read, a refutation, delegated work or a long plan.                                      |
| `hooks/`                       | Git guard, worktree guard, session plans              | A rule in code always runs. A rule in text is only advice.                                                         |
| `statusline-command.sh`        | The status line                                       | Profile, folder, branch, model, tokens, rate limits and prompt cache when they need you, diff and age in one line. |
| [`../bin/quiet`](../bin/quiet) | `quiet <command>`, installed in `~/.local/bin`        | One line on a pass, the full output on a failure. Saves context.                                                   |

## How Claude sizes the work

| Path               | When                                                                                                                                                       | What happens                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Fast** (default) | The intent is clear. A mistake is cheap to see and undo.                                                                                                   | Follow the closest example. Cheapest check. Gate only for the changed packages.                     |
| **Verify**         | A mistake is costly or hard to see: a schema, a data migration, money, auth, permissions, concurrency, a public contract, a number that drives a decision. | `verifier` tries to refute the work. Claude fixes what it confirms. 3 runs at most.                 |
| **Align**          | The request reads two ways, or the choice is yours: product behavior, scope, priority, spend.                                                              | 10 lines at most: goal, options, out of scope, how we know it worked, a pick. Claude waits for you. |

- Claude names the path only when it is not Fast. Say "Fast", "Verify" or "Align" to change it.
- Verify and Align can both apply.
- Claude checks code by reading it first. It runs something only when reading cannot settle it, and starts the whole app only when the behavior spans it.

## Rules in `CLAUDE.md`, in short

- **Exact scope, senior quality.** Never trade one for the other.
- **Read before you run.** Checks run through `quiet`. No test weakened to pass.
- **Keep going** unless data or something outside the repo is at stake. A question a run can answer, Claude runs.
- **Replies in STE.** Findings ranked, each with evidence.
- **Git:** reads are free. `add`, `commit` and `push` only when you ask. For any other git write, Claude gives you the command.
- **Workflows** start only when your message says `ultracode`.

## Agents

| Agent      | Model              | Job                                                                                                                                                         | Why this way                                                                                                                                    |
| ---------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `scout`    | Sonnet 5.5, `high` | Maps what exists. Returns facts, checks, open decisions and risk, or `CLEAR:`. Read-only.                                                                   | Reading is cheap, and speed matters more.                                                                                                       |
| `verifier` | Opus 5.5, `xhigh`  | Tries to refute finished work: code, an analysis, a plan, a number. Reports scope gaps as `MISSING`, `EXTRA` or `WRONG`. Has no Edit or Write tool.         | A missed failure costs more than tokens.                                                                                                        |
| `worker`   | Opus 5.5, `xhigh`  | Does the work Claude delegates: research, code search, multi-step tasks and code changes. Used instead of `general-purpose`. Report leads with the outcome. | `general-purpose` plus how to find the repo's coding rules, and pragmatism and concision rules. The rules live in one file, not in every brief. |
| `planner`  | Opus 5.5, `xhigh`  | Writes one plan file in `~/.local/state/plans/<repo>/`, only when you ask by name.                                                                          | Outside the repo, so nothing commits it. A hook points to it after compaction.                                                                  |

- All four set `omitClaudeMd: true`. Main-session rules ("fix each failure", "run the gate", "ask me") would fight their jobs. Each reads the repo's `AGENTS.md` and `CLAUDE.md` itself.
- None of the four can start another agent.
- Each prompt keeps the style of the built-in `general-purpose` prompt: an opening paragraph, then plain labeled lists such as `Your strengths:` and `Guidelines:`. No bold, and no headings outside the plan template.

## Settings, grouped

- **Few prompts:** `acceptEdits`, plus an allow list for git reads, `git add`, `shellcheck`, `shfmt` and `zsh -n`. Other commands ask first. The deny list and the hooks block the risky git writes.
- **Models:** only Fable 5.1, Opus 5.5 and Sonnet 5.5 (`enforceAvailableModels`). Default `claude-opus-5-5[1m]`, effort `xhigh` on each.
- **Context:** auto-compaction at 400K of the 1M window. Unused bundled skills are off (`skillOverrides`), so their descriptions use no context. `ponytail`, its `-review`, `-audit` and `-debt` skills, and `grilling` are `user-invocable-only`: they run only when you type their name. `workflowSizeGuideline: small`.
- **Git:** the deny list blocks resets, branch switches, rebases, amends, stashes and worktrees. `GIT_EDITOR=true`, so git never waits for an editor. `includeGitInstructions: false`, because `CLAUDE.md` holds the git rules. Empty `attribution`: no Claude trailer.
- **Quiet and private:** Concise output style. No spinner tips, feedback survey or error reports. No claude.ai connectors or skill sync, no Gmail, Calendar or Drive MCP, no remote control. Auto memory is off: what Claude knows lives in files you can read.
- **Long history:** `cleanupPeriodDays: 3650`, so `/resume` finds old sessions.
- **Real edits:** `CLAUDE_CODE_THRIFTY_SONIC=0`, so Claude edits with Edit and Write, not `sed`.
- **Plugins:** context7 (current library docs), TypeScript and Rust LSP, Paper (design), you-should-know (a side agent flags what you might miss).

## Get the most out of it

- **Small task:** just ask. No ceremony.
- **Second opinion on anything:** "verify this". Add "with two models" for a decision that is hard to undo; a second `verifier` runs on Fable 5.1.
- **A bug:** `/diagnose`. It finds a command that shows the failure before any theory.
- **A session that went wrong:** `/retro`. It turns each lesson into a check, hook, script or rule, and asks which to apply.
- **Fuzzy request:** "align first".
- **Big change on many files:** "use workers". Claude gives each independent part to a `worker`.
- **More than one sitting:** "use the planner".
- **See the real app run:** `/verify`. Run `/run-skill-generator` once per repo; `/verify` and `verifier` then reuse its launch recipe.
- **Bugs in a diff:** `/code-review`. **Simpler code:** `/simplify`.
- **New session, same task:** the `handoff` skill.
- **Many agents at once:** put `ultracode` in the message.
- **After you edit the rules:** `/doctor prompt-audit` finds conflicts.

## Change it

1. Edit the files here. Run `./install.sh -n` to see what changes, then `./install.sh`.
2. A key you delete from `settings.json` stays in the live file. Delete it there too.
3. `install.sh` never deletes. Remove a file the repo dropped by hand.
