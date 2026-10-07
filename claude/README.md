# claude

Claude Code's home. `./install.sh` copies this folder into `~/.claude` and merges `settings.json`. This README stays in the repo.

**The idea:** fast by default. Heavy checks run only when a mistake costs much. Hard rules live in code (deny rules), not in more text.

## TL;DR

- Edit here, never in `~/.claude`. Then re-run `./install.sh`.
- Ask plainly. Claude sizes the work. Small work stays Fast.
- Say **"verify this"** for a second opinion, **"align first"** for options, **"use the planner"** for work that needs more than one sitting.
- Claude commits only when you ask.

## What is here

| Path                           | What it is                                              | Why                                                                                                                                               |
| ------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                    | Rules for the main session                              | One short core. Less text, better adherence.                                                                                                      |
| `settings.json`                | Merged into `~/.claude/settings.json` by `install.sh`   | Repo keys win. Claude Code keeps the keys it writes.                                                                                              |
| `agents/`                      | `scout`, `verifier`, `worker`, `planner`, `clerk`       | A fresh context for a wide read, a refutation, delegated work, a long plan or a cheap narrow task.                                                |
| `hooks/`                       | Session plans, and the gate on agents a subagent starts | A plan survives compaction and resume. `scout`, `worker`, `verifier` and `planner` start only a Haiku `clerk`. Claude's git rules are deny rules. |
| `statusline-command.sh`        | The status line                                         | Profile, folder, branch, model, tokens, rate limits and prompt cache (dim until they need you), diff and age in one line.                         |
| [`../bin/quiet`](../bin/quiet) | `quiet <command>`, installed in `~/.local/bin`          | One line on a pass, the full output on a failure. Saves context.                                                                                  |

## How Claude sizes the work

| Path               | When                                                                                                                                                       | What happens                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Fast** (default) | The intent is clear. A mistake is cheap to see and undo.                                                                                                   | Follow the closest example. Cheapest check. The repo's checks only for the changed packages.        |
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

| Agent      | Model               | Job                                                                                                                                                               | Why this way                                                                                                                                                                                                                                               |
| ---------- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scout`    | Sonnet 5.5, `high`  | Maps what exists. Returns facts, checks, open decisions and risk, or `CLEAR:`. Read-only.                                                                         | Reading is cheap, and speed matters more.                                                                                                                                                                                                                  |
| `verifier` | Opus 5.5, `xhigh`   | Tries to refute finished work: code, an analysis, a plan, a number. Reports scope gaps as `MISSING`, `EXTRA` or `WRONG`. Has no Edit or Write tool.               | A missed failure costs more than tokens.                                                                                                                                                                                                                   |
| `worker`   | Opus 5.5, `xhigh`   | Does the work Claude delegates: research, code search, multi-step tasks and code changes. Used instead of `general-purpose`. Report leads with the outcome.       | `general-purpose` plus how to find the repo's coding rules, and pragmatism and concision rules. The rules live in one file, not in every brief.                                                                                                            |
| `planner`  | Opus 5.5, `xhigh`   | Writes one plan file in `~/.local/state/plans/<repo>/`, only when you ask by name.                                                                                | Outside the repo, so nothing commits it. A hook points to it after compaction.                                                                                                                                                                             |
| `clerk`    | Haiku 5.5, `medium` | Does one narrow task the parent checks: a summary, a list, a count, or a change the brief spells out, in the files it names, with its check. Several run at once. | At least 20 times cheaper than Opus 5.5 for a prompt up to 100K tokens, and at least 4 times above that. The fastest model. Weaker at agentic coding, so it gets no judgment, design or reviews. At `low`, Haiku more often skips a search or stops early. |

- All five set `omitClaudeMd: true`. Main-session rules ("fix each failure", "run the gate", "ask me") would fight their jobs. Each reads the repo's `AGENTS.md` and `CLAUDE.md` itself, except `clerk`: its brief is all its context.
- None sets `maxTurns`: each runs until its task is done.
- `scout`, `worker`, `verifier` and `planner` can start a `clerk`, so they go and do without a round trip to the main session. `hooks/nested-agents.sh` refuses any other agent type and any `model` override from them, because Claude Code ignores the type list in `Agent(...)` inside subagent frontmatter. A `clerk` starts nothing, and `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` stops a deeper chain.
- `scout` and `verifier` keep no Edit or Write tool, and brief their clerks to change nothing: `scout` maps before you choose, and `verifier` must not fix what it judges.
- Each prompt keeps the style of the built-in `general-purpose` prompt: an opening paragraph, then plain labeled lists such as `Your strengths:` and `Guidelines:`. No bold, and no headings outside the plan template.

## Settings, grouped

- **Few prompts:** `acceptEdits`, plus an allow list for git reads, `git add`, `shellcheck`, `shfmt` and `zsh -n`. Other commands ask first. The deny list blocks the risky git writes.
- **Models:** only Fable 5.1, Opus 5.5, Sonnet 5.5 and Haiku 5.5 (`enforceAvailableModels`). Default `claude-opus-5-5[1m]`. Effort `xhigh` on each, except `high` on Haiku 5.5: at `xhigh`, Haiku can end a turn with no visible text.
- **Context:** auto-compaction in a 400K window of the 1M (`autoCompactWindow`). Haiku 5.5 gets a 100K window: it compacts near 67K, so its requests mostly stay under 100K tokens, where every Haiku price goes up 5 times. Unused bundled skills are off (`skillOverrides`), so their descriptions use no context. `ponytail`, its `-review`, `-audit` and `-debt` skills, and `grilling` are `user-invocable-only`: they run only when you type their name. `workflowSizeGuideline: small`.
- **Git:** the deny list blocks resets, branch switches, rebases, amends, stashes, worktrees, force and delete pushes, and the `wt` and `gh` commands that change a branch, also after a global option such as `git -C`. Not caught: combined short flags such as `-uf`, a delete push written `origin :branch` and abbreviated options such as `--amen`. With a global option first, a commit message or path that holds a denied subcommand word is refused too. `GIT_EDITOR=true`, so git never waits for an editor. `includeGitInstructions: false`, because `CLAUDE.md` holds the git rules. Empty `attribution`: no Claude trailer.
- **Prompt cache:** Claude Code's defaults, on purpose. The main session gets a 1-hour cache on a subscription within plan usage. Subagents get 5 minutes, as they send a request every few seconds; a 1-hour cache on `verifier` pays only if most of its runs are resumed 5 to 60 minutes later. Tool search is on, so MCP tools load only when Claude needs one, and a server that connects during a session does not reset the cache.
- **Quiet and private:** Concise output style. No spinner tips, feedback survey or error reports. No claude.ai connectors or skill sync, no Gmail, Calendar or Drive MCP, no remote control. Auto memory is off: what Claude knows lives in files you can read.
- **Long history:** `cleanupPeriodDays: 3650`, so `/resume` finds old sessions.
- **Real edits:** `CLAUDE_CODE_THRIFTY_SONIC=0`, so Claude edits with Edit and Write, not `sed`. The docs do not list this switch: it turns off the `tengu_thrifty_sonic` test, as read in the 2.1.293 binary. Check it again after an update.
- **Plugins:** context7 (current library docs), TypeScript and Rust LSP, Paper (design), you-should-know (a side agent flags what you might miss).

## Get the most out of it

- **Small task:** just ask. No ceremony.
- **Second opinion on anything:** "verify this". Add "with two models" for a decision that is hard to undo; a second `verifier` runs on Fable 5.1.
- **A bug:** `/diagnose`. It finds a command that shows the failure before any theory.
- **A session that went wrong:** `/retro`. It turns each lesson into a check, hook, script or rule, and asks which to apply.
- **Fuzzy request:** "align first".
- **Big change on many files:** "use workers". Claude gives each independent part to a `worker`.
- **Cheap narrow work:** "use clerks". Haiku clerks summarize, count or make a change Claude spells out, several at once, and Claude checks each result.
- **More than one sitting:** "use the planner".
- **Keep the cache warm:** choose the model when the session starts. A model switch sends the whole conversation again at the cache-write price; an `/effort` change does not. When the status line shows `cache expired`, the next message does the same.
- **Big idea with open questions:** `/wayfinder`. It maps the open decisions in a local file and resolves one per session.
- **See the real app run:** `/verify`. Run `/run-skill-generator` once per repo; `/verify` and `verifier` then reuse its launch recipe.
- **Bugs in a diff:** `/code-review`. **Simpler code:** `/simplify`.
- **New session, same task:** the `handoff` skill.
- **Many agents at once:** put `ultracode` in the message.
- **After you edit the rules:** `/doctor prompt-audit` finds conflicts.

## Change it

1. Edit the files here. Run `./install.sh -n` to see what changes, then `./install.sh`.
2. A key you delete from `settings.json` stays in the live file. Delete it there too.
3. `install.sh` never deletes. Remove a file the repo dropped by hand.
