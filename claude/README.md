# claude

Claude Code's home. `./install.sh` copies this folder into `~/.claude` and merges `settings.json`. This README and `WORKFLOWS.md` stay in the repo. Edit here, never in `~/.claude`, then run `./install.sh` again.

The idea: fast by default. Heavy checks run only when a mistake costs much. Hard limits live in settings, such as deny rules, not in more text.

## Use it

- [`WORKFLOWS.md`](WORKFLOWS.md): the flow, the words and commands to type, and prompts to copy. Ask plainly; Claude runs one flow for every task and skips the steps a small task does not need.
- Choose the model when the session starts. A model switch sends the whole conversation again at the cache-write price; an `/effort` change does not. When the status line shows `cache expired` or `cache cold`, the next message does the same.

## Files

- `CLAUDE.md`: the rules for the main session. One short core, because less text means better adherence.
- `settings.json`: merged into `~/.claude/settings.json` by `install.sh`. Repo keys win, and Claude Code keeps the keys it writes.
- `agents/`: `scout`, `verifier`, `worker`, `planner`, `clerk`, `researcher`, `reviewer` and `browser`.
- `hooks/`: `nested-agents.sh` lets a subagent start only a `clerk` or a `browser`, and `bash-reads.sh` refuses a file read through `cat`, `sed`, `head`, `tail` or `nl`.
- `statusline-command.sh`: the status line. Profile, folder, branch, model, tokens, rate limits, prompt cache, diff and age in one line. Each part stays dim until it needs you.
- [`../bin/quiet`](../bin/quiet), installed in `~/.local/bin`: `quiet <command>` prints one line on a pass and the full output on a failure, to save context.

## The rules, in short

- Senior quality in the fewest steps: correct first, then fast.
- One flow for every task: understand, plan, build, check, review once, report. A small task skips the plan, and Claude builds it itself. With a plan, a fresh `worker` builds each ticket, and one `verifier` on Fable 5.1 reviews the whole diff once. A subagent starts fresh with a brief, and a fork is only for side research.
- Claude asks only what the facts cannot settle, in one round with its picks, and goes on. It waits only when a wrong pick is costly and hard to undo.
- One review and one fix round, never a score or a loop. One task a session: Claude tells you to `/clear` between unrelated tasks, and to `/handoff` near 300k tokens.
- Claude reads the change before it runs anything. Checks run through `quiet`, only on the changed files, and on the whole repo only when the change can break code outside them.
- Tests follow the repo's rule. When the repo has none, Claude adds a test only when it catches a bug that no other check catches, and runs only the tests for the changed code.
- Claude does each step itself, also outside the repo, and stops for you only at a critical step: data that nothing can bring back, money, a production or shared system, something sent as you, credentials or access, or what only you have, such as a password or a 2FA code. A status note goes with the next action, not in a turn of its own.
- Replies are in STE. Findings come ranked, each with evidence.
- Markdown has only plain sentences, headings, lists, links and code. No bold.
- Git: reads are free. `add`, `commit`, `push` and a new pull request run only when you ask. For any other git write, Claude gives you the command. Claude never changes the branch in the session's folder. Agents and subagents work in that folder and branch. Only you make a worktree, and Claude tells you when work needs its own branch.

## Agents

- `scout` (Sonnet 5.5, `medium`): maps what exists, and returns facts, checks, open decisions and risks, or `CLEAR:`. Read-only. Reading is cheap, so speed matters more.
- `verifier` (Opus 5.5, `high`): checks finished work claim by claim, such as code, an analysis, a plan or a number, quickly, the same way each run and with no bias to find problems. It reports scope gaps as `MISSING`, `EXTRA` or `WRONG`, and has no Edit or Write tool. A missed failure costs more than tokens. With a plan, the main session starts it on Fable 5.1, so the model that checks the work is not the model that built it; "two models" adds a second one on Opus 5.5. It follows a repo's `.claude/skills/verify/` recipe, which `/verify-setup` writes.
- `worker` (Opus 5.5, `medium`): does the work that Claude delegates, in place of `general-purpose`: research, code search, multi-step tasks and code changes. It knows where to find the repo's coding rules, so a brief does not repeat them. It commits, pushes and opens the pull request when the brief says that you asked.
- `planner` (Opus 5.5, `high`): writes or revises one plan of tickets in `~/.local/state/plans/<repo>/`, when the work needs more than one ticket. A fresh `worker` builds each ticket. The file is outside the repo, so nothing commits it. Each ticket fits one fresh session, so the plan has no session owner.
- `clerk` (Haiku 5.5, `high`): does one narrow task that the parent checks, such as a summary, a list, a count or a change the brief spells out. Several run at once. It costs at least 20 times less than Opus 5.5 for a prompt up to 100K tokens, and at least 4 times less above that, and it is the fastest model. It is weaker at agentic coding, so it gets no judgment, design or review. At `low`, Haiku more often skips a search or stops early.
- `researcher` (Sonnet 5.5, `high`): answers one question from the web and current docs, and gives each fact with its URL and the date of the source. Read-only, with no code in the repo.
- `reviewer` (Opus 5.5, `high`): finds the defects in a diff or an area of code, most severe first, each with the input or state that breaks it and its evidence. It does not fix. Unlike `verifier`, it starts from no list of claims.
- `browser` (Sonnet 5.5, `high`): checks a web page or app in a real browser with the `agent-browser` CLI, and gives `PASS` or `FAIL` for each expected result with a screenshot. It changes no code.

How they work together:

- All eight set `omitClaudeMd: true`, because main-session rules such as "run the checks" or "ask me" would fight their jobs. Each reads the repo's `AGENTS.md` and `CLAUDE.md` itself, except `clerk`, `researcher` and `browser`, whose brief is all their context.
- None sets `maxTurns`, so each runs until its task is done.
- `scout`, `planner` and `reviewer` can start a `clerk`, and `worker` and `verifier` a `clerk` or a `browser`, with no round trip to the main session. `hooks/nested-agents.sh` refuses any other agent type and any `model` override from them, because Claude Code ignores the type list in `Agent(...)` in subagent frontmatter. A `clerk`, `researcher` or `browser` starts nothing, and `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` stops a deeper chain.
- `scout`, `verifier`, `reviewer`, `researcher` and `browser` have no Edit or Write tool. `scout`, `verifier` and `reviewer` tell their clerks to change nothing: `scout` maps before you choose, and `verifier` and `reviewer` must not fix what they judge.
- Each prompt follows the style of the built-in `general-purpose` prompt: an opening paragraph, then plain labeled lists such as `Your strengths:` and `Guidelines:`.

## Settings

- Permissions: `acceptEdits`, plus an allow list for git reads, `git add`, `shellcheck`, `shfmt` and `zsh -n`. Other commands ask first. The deny list blocks the risky git writes.
- Models: only Fable 5.1, Opus 5.5, Sonnet 5.5 and Haiku 5.5 (`enforceAvailableModels`). The default is `claude-opus-5-5[1m]`.
- Effort: `high` on Opus 5.5, Sonnet 5.5 and Haiku 5.5, and `xhigh` on Fable 5.1. On Anthropic's SWE-bench Pro run, Opus 5.5 at `xhigh` scored about 1.4 points above `high`, at 2.5 times the cost, so the main session runs `high`, and `/effort xhigh` sets one session higher for a hard task. Each agent's `effort` frontmatter outranks these: `verifier` and `planner` run Opus 5.5 at `high`, `worker` runs it at `medium`, the model's own default, and `scout` runs Sonnet 5.5 at `medium`, to move the balance toward speed. `verifier` and `planner` stay at `high` because they are the quality gate and a bad plan multiplies work. None runs at `xhigh`, because at `xhigh` most of their time was model time (64% for `worker`, 89% for `verifier`, 98% for `planner`), with a median of about 15 minutes a run, over about 450 runs in October 2026. At `xhigh`, Sonnet can start its own review rounds, sometimes with reviewer subagents, and Haiku can end a turn with no visible text.
- Refusals: a request that a safety classifier flags ends with a refusal. Its fallback models (Opus 4.8, Opus 5 and Sonnet 5) are not in the list, so Claude Code does not switch.
- Advisor: off. With Opus 5.5 as the main model it was Opus advising Opus: no stronger model, but 18 to 30% of model time, at about 2 minutes a call.
- Context: compaction in a 400K window of the 1M (`autoCompactWindow`). Haiku 5.5 gets a 100K window and compacts near 67K, so its requests mostly stay under 100K tokens. Above that, every Haiku price is 5 times higher.
- Skills: unused bundled skills are off (`skillOverrides`), so their descriptions use no context. `ponytail`, its `-review`, `-audit` and `-debt` skills, `grilling` and `security-audit` run only when you type their name. `workflowSizeGuideline: small`.
- Git: the deny list blocks resets, branch switches, rebases, amends, stashes, worktree commands, history rewrites, tag and ref deletes, force and delete pushes, forced fetches, and the `wt` and `gh` commands that change or delete a branch, a repo or a release, also after a global option such as `git -C`. `EnterWorktree`, worktree isolation (`Agent(isolation:worktree)`) and cloud isolation are denied, so every agent works in your folder and branch. It does not catch combined short flags such as `-uf`, a delete push written `origin :branch`, or shortened options such as `--amen`. With a global option first, a commit message or path that contains a denied word is refused too. `GIT_EDITOR=true`, so git never waits for an editor. `includeGitInstructions: false`, because `CLAUDE.md` holds the git rules. `attribution` is empty, so commits get no Claude trailer.
- Prompt cache: Claude Code's defaults, on purpose. The main session gets a 1-hour cache on a subscription within plan usage. Subagents get 5 minutes, because they send a request every few seconds. A 1-hour cache on `verifier` pays only if most of its runs resume 5 to 60 minutes later. Tool search is on, so MCP tools load only when Claude needs one, and a server that connects during a session does not reset the cache.
- Quiet and private: Concise output style. No spinner tips, feedback survey or error reports. No claude.ai connectors or skill sync, no Gmail, Calendar or Drive MCP, and no remote control. Auto memory is off, so what Claude knows is in files you can read.
- History: Claude Code's default of 30 days. Older transcripts, checkpoints and plans are deleted at startup.
- Real edits: `CLAUDE_CODE_THRIFTY_SONIC=0`, so Claude edits with Edit and Write, not `sed`. The docs do not list this switch. It turns off the `tengu_thrifty_sonic` test, as read in the 2.1.293 binary, so check it again after an update.
- Plugins: context7 for current library docs, TypeScript, Rust and Swift LSP, Paper for design, and you-should-know, a side agent that flags what you might miss.

## Change it

1. Edit the files here. Run `./install.sh -n` to see what changes, then `./install.sh`.
2. A key you delete from `settings.json` stays in the live file. Delete it there too. `install.sh` deletes only the keys this repo dropped: `advisorModel`, `cleanupPeriodDays`, `env.CLAUDE_CODE_AUTO_COMPACT_WINDOW` and the old hooks.
3. `install.sh` never deletes a file. Remove a file the repo dropped by hand, such as `~/.claude/hooks/session-plans.sh` and `~/.claude/hooks/verifier-report.sh`.
