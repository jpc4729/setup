# claude

Claude Code's home. `./install.sh` copies this folder into `~/.claude` and merges `settings.json`. This README stays in the repo. Edit here, never in `~/.claude`, then run `./install.sh` again.

The idea: fast by default. Heavy checks run only when a mistake costs much. Hard limits live in settings, such as deny rules, not in more text.

## Use it

- Ask plainly. Claude picks the path, and small work stays Fast.
- "verify this": a `verifier` checks the work claim by claim. Add "with two models" for a decision that is hard to undo, and a second `verifier` runs on Fable 5.1.
- "align first": Claude gives options and a pick before it does any work.
- "use workers": Claude gives each independent part of a big change to a `worker`.
- "use clerks": Haiku clerks summarize, count or make a change that Claude spells out, several at once, and Claude checks each result.
- "use the planner": a plan file for work that needs more than one sitting.
- `ultracode` in a message: many agents at once.
- `/diagnose` for a bug. It finds a command that shows the failure before any theory.
- `/read-only` in a prompt for a task with no changes. The agent only reads and analyzes, and puts any change it proposes in its reply.
- `/retro` for a session that went wrong. It turns each lesson into a check, hook, script or rule, and asks which to apply.
- `/skills-claude` to write, review or fix a skill to the standards of the native Claude Code skills.
- `/wayfinder` for a big idea with open questions. It maps the open decisions in a local file and settles one per session.
- `/verify` to see the real app run. Run `/run-skill-generator` once per repo first; `/verify` and `verifier` then reuse its launch recipe.
- `/code-review` for bugs in a diff, `/simplify` for simpler code, and the `handoff` skill for a new session on the same task.
- `/doctor prompt-audit` after you edit the rules. It finds conflicts.
- Choose the model when the session starts. A model switch sends the whole conversation again at the cache-write price; an `/effort` change does not. When the status line shows `cache expired`, the next message does the same.

## Files

- `CLAUDE.md`: the rules for the main session. One short core, because less text means better adherence.
- `settings.json`: merged into `~/.claude/settings.json` by `install.sh`. Repo keys win, and Claude Code keeps the keys it writes.
- `agents/`: `scout`, `verifier`, `worker`, `planner` and `clerk`.
- `hooks/`: one keeps a session's plan through compaction and resume, one lets a subagent start only a `clerk`, and one sends a `verifier` report back once when it breaks the report format.
- `statusline-command.sh`: the status line. Profile, folder, branch, model, tokens, rate limits, prompt cache, diff and age in one line. Each part stays dim until it needs you.
- [`../bin/quiet`](../bin/quiet), installed in `~/.local/bin`: `quiet <command>` prints one line on a pass and the full output on a failure, to save context.

## The rules, in short

- Exact scope, senior quality.
- Fast is the default: the intent is clear, and a mistake is cheap to see and undo. Claude follows the closest example and runs the cheapest check.
- Verify: a mistake is costly or hard to see, as with a schema, a rewrite of stored data, money, how users prove who they are, permissions, concurrency, an API that others use, or a number behind a decision. A `verifier` checks the work claim by claim, and Claude fixes what it confirms, in 3 runs at most.
- Align: the request reads two ways, or the choice is yours. Claude gives you 10 lines at most, with a pick, and acts on the pick. It waits for you only when a wrong pick is costly and hard to undo. Verify and Align can both apply.
- Claude names the path only when it is not Fast. Say "Fast", "Verify" or "Align" to change it.
- Claude reads the change before it runs anything. Checks run through `quiet`, only on the changed files, and on the whole repo only when the change can break code outside them.
- Claude keeps working unless data or something outside the repo is at stake. A status note goes with the next action, not in a turn of its own.
- Replies are in STE. Findings come ranked, each with evidence.
- Markdown has only plain sentences, headings, lists, links and code. No bold.
- Git: reads are free. `add`, `commit`, `push` and a new pull request run only when you ask. For any other git write, Claude gives you the command. Claude never changes the branch in the session's folder. Work that needs its own branch goes to a subagent with worktree isolation.

## Agents

- `scout` (Sonnet 5.5, `high`): maps what exists, and returns facts, checks, open decisions and risks, or `CLEAR:`. Read-only. Reading is cheap, so speed matters more.
- `verifier` (Opus 5.5, `xhigh`): checks finished work claim by claim, such as code, an analysis, a plan or a number, quickly, the same way each run and with no bias to find problems. It reports scope gaps as `MISSING`, `EXTRA` or `WRONG`, and has no Edit or Write tool. A missed failure costs more than tokens.
- `worker` (Opus 5.5, `xhigh`): does the work that Claude delegates, in place of `general-purpose`: research, code search, multi-step tasks and code changes. It knows where to find the repo's coding rules, so a brief does not repeat them. In its own worktree, it commits, pushes and opens the pull request when the brief says that you asked.
- `planner` (Opus 5.5, `xhigh`): writes one plan file in `~/.local/state/plans/<repo>/`, only when you ask for it by name. The file is outside the repo, so nothing commits it, and a hook points to it after compaction.
- `clerk` (Haiku 5.5, `medium`): does one narrow task that the parent checks, such as a summary, a list, a count or a change the brief spells out. Several run at once. It costs at least 20 times less than Opus 5.5 for a prompt up to 100K tokens, and at least 4 times less above that, and it is the fastest model. It is weaker at agentic coding, so it gets no judgment, design or review. At `low`, Haiku more often skips a search or stops early. It is told never to call the advisor, which would read its whole transcript at Opus rates.

How they work together:

- All five set `omitClaudeMd: true`, because main-session rules such as "run the checks" or "ask me" would fight their jobs. Each reads the repo's `AGENTS.md` and `CLAUDE.md` itself, except `clerk`, whose brief is all its context.
- None sets `maxTurns`, so each runs until its task is done.
- `scout`, `worker`, `verifier` and `planner` can start a `clerk` with no round trip to the main session. `hooks/nested-agents.sh` refuses any other agent type and any `model` override from them, because Claude Code ignores the type list in `Agent(...)` in subagent frontmatter. A `clerk` starts nothing, and `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` stops a deeper chain.
- `scout` and `verifier` have no Edit or Write tool, and tell their clerks to change nothing: `scout` maps before you choose, and `verifier` must not fix what it judges.
- Each prompt follows the style of the built-in `general-purpose` prompt: an opening paragraph, then plain labeled lists such as `Your strengths:` and `Guidelines:`.

## Settings

- Permissions: `acceptEdits`, plus an allow list for git reads, `git add`, `shellcheck`, `shfmt` and `zsh -n`. Other commands ask first. The deny list blocks the risky git writes.
- Models: only Fable 5.1, Opus 5.5, Sonnet 5.5 and Haiku 5.5 (`enforceAvailableModels`). The default is `claude-opus-5-5[1m]`.
- Effort: `xhigh` on Opus 5.5 and Fable 5.1, because quality comes first. On Anthropic's SWE-bench Pro run, Opus 5.5 at `xhigh` scored about 1.4 points above `high`, at 2.5 times the cost. Fable 5.1 at `xhigh` has no published coding result, and on one research benchmark its higher effort added only cost, so its `xhigh` is for quality and not measured. `high` on Sonnet 5.5 and Haiku 5.5: at `xhigh`, Sonnet can start its own review rounds, sometimes with reviewer subagents, and Haiku can end a turn with no visible text.
- Refusals: a request that a safety classifier flags ends with a refusal. Its fallback models (Opus 4.8, Opus 5 and Sonnet 5) are not in the list, so Claude Code does not switch.
- Advisor: Opus 5.5 (`advisorModel`). Claude can consult it at decision points with the full transcript, uncached, so each call costs a full read at Opus rates. Subagents inherit it, and `clerk` is told never to call it. A Fable 5.1 session has no advisor, because only Fable 5.1 can advise Fable 5.1. The advisor's effort has no setting.
- Context: compaction in a 400K window of the 1M (`autoCompactWindow`). Haiku 5.5 gets a 100K window and compacts near 67K, so its requests mostly stay under 100K tokens. Above that, every Haiku price is 5 times higher.
- Skills: unused bundled skills are off (`skillOverrides`), so their descriptions use no context. `ponytail`, its `-review`, `-audit` and `-debt` skills, and `grilling` run only when you type their name. `workflowSizeGuideline: small`.
- Git: the deny list blocks resets, branch switches, rebases, amends, stashes, worktree commands, history rewrites, tag and ref deletes, force and delete pushes, forced fetches, and the `wt` and `gh` commands that change or delete a branch, a repo or a release, also after a global option such as `git -C`. A subagent or workflow agent with worktree isolation gets its own folder and branch under `.claude/worktrees/`, and Claude Code blocks its edits, commands and git redirects into your folder. `EnterWorktree` and cloud isolation are denied. It does not catch combined short flags such as `-uf`, a delete push written `origin :branch`, or shortened options such as `--amen`. With a global option first, a commit message or path that contains a denied word is refused too. `GIT_EDITOR=true`, so git never waits for an editor. `includeGitInstructions: false`, because `CLAUDE.md` holds the git rules. `attribution` is empty, so commits get no Claude trailer.
- Prompt cache: Claude Code's defaults, on purpose. The main session gets a 1-hour cache on a subscription within plan usage. Subagents get 5 minutes, because they send a request every few seconds. A 1-hour cache on `verifier` pays only if most of its runs resume 5 to 60 minutes later. Tool search is on, so MCP tools load only when Claude needs one, and a server that connects during a session does not reset the cache.
- Quiet and private: Concise output style. No spinner tips, feedback survey or error reports. No claude.ai connectors or skill sync, no Gmail, Calendar or Drive MCP, and no remote control. Auto memory is off, so what Claude knows is in files you can read.
- History: Claude Code's default of 30 days. Older transcripts, checkpoints and plans are deleted at startup.
- Real edits: `CLAUDE_CODE_THRIFTY_SONIC=0`, so Claude edits with Edit and Write, not `sed`. The docs do not list this switch. It turns off the `tengu_thrifty_sonic` test, as read in the 2.1.293 binary, so check it again after an update.
- Plugins: context7 for current library docs, TypeScript and Rust LSP, Paper for design, and you-should-know, a side agent that flags what you might miss.

## Change it

1. Edit the files here. Run `./install.sh -n` to see what changes, then `./install.sh`.
2. A key you delete from `settings.json` stays in the live file. Delete it there too.
3. `install.sh` never deletes. Remove a file the repo dropped by hand.
