# setup

My agent setup for Claude Code, Codex, Cursor, Grok and opencode: one set of rules, git deny lists and 19 skills.

## Install

You need bash, rsync, [jq](https://jqlang.org) and [yq](https://github.com/mikefarah/yq).

```sh
git clone https://github.com/josechifflet/setup.git
cd setup
./install.sh -n   # list what would change
./install.sh
```

The models, login method and themes are mine. Edit `claude/settings.json`, `codex/config.toml`, `grok/config.toml` and `opencode/opencode.jsonc` before you install.

## What install.sh does

- It copies each tool folder into its home. A file it replaces stays beside it as `<name>.bak`.
- It merges five settings files instead of copying them, because the apps rewrite them: `claude/settings.json`, `codex/config.toml`, `grok/config.toml`, `cursor/mcp.json` and `cursor/cli-config.json`. Keys in the repo win, and keys the app wrote stay.
- It copies the skills into `~/.agents/skills` and `~/.cursor/skills`, and links each one into `~/.claude/skills`. It replaces a skill folder with the same name, and leaves other skills alone.
- It copies `bin/quiet` into `~/.local/bin`. Put that folder on your PATH: every tool runs its checks through `quiet`.
- On macOS, it also installs Codex's `requirements.toml` as the managed `com.openai.codex` preference. Codex then enforces its approval policies and runs no hook from another config.

It copies files and never links them: every agent writes state into its home, and a link would carry that state back into the repo. Run `install.sh` again after you pull.

## Upgrade from an older install

`install.sh` never deletes. After you pull, remove by hand what the repo dropped:

- Agents: in `~/.claude/agents`, `~/.codex/agents`, `~/.cursor/agents`, `~/.grok/agents` and `~/.config/opencode/agents`, keep only `planner`, `scout`, `verifier` and `worker`, and also `clerk` in `~/.claude/agents`.
- Old files: the `~/.config/opencode/agent` folder, and `~/.agents/AGENTS.md`, which no tool reads.
- Skills: `behaviour` is now `intent`. Delete `behaviour` from `~/.agents/skills`, `~/.cursor/skills` and `~/.claude/skills`.
- Git hooks: no tool runs one now. Delete `block-dangerous-git.sh` and `block-worktree.sh` from `~/.claude/hooks`, `block-dangerous-git.sh` from `~/.codex/hooks`, and `block-dangerous-git.sh` and `git-safety.json` from `~/.grok/hooks`.
- Settings: the merge keeps keys that the repo dropped. Delete `disableArtifact`, `cleanupPeriodDays`, `env.ENABLE_CLAUDEAI_MCP_SERVERS` and `env.CLAUDE_CODE_AUTO_COMPACT_WINDOW` from `~/.claude/settings.json`, and `hooks.PreToolUse` and `features.hooks` from `~/.codex/config.toml`.

## Layout

```text
agents/my-skills/  → ~/.agents/skills      skills I wrote
agents/skills/     → ~/.agents/skills      vendored skills, pinned in skills-lock.json
bin/quiet          → ~/.local/bin/quiet    one line on a pass, full output on a failure
claude/            → ~/.claude             rules, settings, five agents, hooks, status line
codex/             → ~/.codex              rules, config, four agents, policy, command rules
cursor/            → ~/.cursor             rules, four agents, MCP, permissions
grok/              → ~/.grok               rules, config, four agents
opencode/          → ~/.config/opencode    rules, config, four agents
```

## Rules

Every tool gets the same rules core, in short sentences and plain words.

- Agents do exactly what you ask, at the quality a strict senior reviewer would approve. They never trade quality for speed or a smaller change.
- While they work, they run the smallest check that covers the change.
- When all the work is done, they run the repo's checks, such as its linter, format check and type check, only on the changed files. They check the whole repo only when the change can break code outside those files.
- They check code by reading it first, and run checks through `quiet`.
- They review their work before they report, and then stop.
- They keep going unless they are blocked, or about to delete data or change something outside the repo.
- When a run can answer a question, they run it instead of asking you.
- They write to you in ASD-STE100 Simplified Technical English, and list each finding they can back with evidence.
- They write Markdown with no bold.

Each task goes on one or more of three paths:

- Fast is the default.
- Verify is for a mistake that is costly or hard to see. The `verifier` subagent checks the work claim by claim. When you ask for two models, Claude, Codex, Cursor and Grok also send the same brief to a second `verifier` on another model.
- Align is for a request that reads two ways, or a choice that is yours. The agent gives you 10 lines at most, with a pick.

Git:

- Git reads run freely. `add`, `commit`, `push` and a new pull request run only when you ask.
- Each other git write comes to you as the exact command.
- Many agents can work in the folder where a session started, so no agent changes the branch there.
- Work that needs its own branch goes in a separate folder, a worktree, with its own branch and pull request. In Claude, a subagent or workflow agent with worktree isolation does that work. In the other tools, only you make a worktree.

What a tool can start on its own:

- Claude and Grok start a workflow only when your message contains `ultracode`, and stop its retry loops after 3 rounds.
- Codex creates a goal, a scheduled task or a cloud task only when you ask, and marks a goal blocked after 3 turns on the same blocker.
- Cursor starts a loop, autopilot, automation or cloud agent only when you ask, and stops a loop after 3 rounds.
- opencode has no workflow feature, so it has no such rule.

## Subagents

Every tool defines `planner`, `scout`, `verifier` and `worker`, each in its own format. Each prompt follows the style of Claude Code's built-in `general-purpose` prompt. Any other subagent is the tool's built-in one.

- `planner` runs only when you name it.
- `scout` is read-only. It maps what exists and the open decisions before Align.
- `verifier` checks finished work claim by claim, quickly, the same way each run and with no bias to find problems. It reads first, runs only what reading cannot settle, and reports each part of the request that is missing, extra or wrong.
- `verifier` numbers the brief's claims, adds a claim of its own only for a defect it saw while it checked, and stops on a claim at the first proof that settles it. Its report is one plain line per claim, then the scope, then a verdict that follows from those lines. In Claude, a hook sends back once a report that breaks this format.
- `worker` is a better `general-purpose` for delegated work: research, code search, multi-step tasks and code changes.
- `worker` finds the repo's coding rules before it writes code, and runs a command that shows a bug's failure before it edits. It works to a named finish line, and reports first what it needs from the parent.
- Each agent knows that a message without a tool call ends its turn, so it keeps working until its report is ready.

Delegation, in every tool:

- The agent gives a subagent a read across many files or long logs, a large change split into independent parts on separate files, or a fresh-context `verifier` review of a long run before it reports.
- Delegated work goes to `worker`, not to the built-in general agent.
- When the reads and edits are few, the agent works directly.
- The agent reviews every diff that a subagent returns.

Claude:

- It also has `clerk`, a Haiku 5.5 agent for one narrow task that its brief spells out, such as a summary, a list, a count or a mechanical change.
- The other four agents can start clerks, and a `PreToolUse` hook stops them from starting any other agent.
- Its agents skip every CLAUDE.md file (`omitClaudeMd`). All but `clerk` read the repo's `AGENTS.md` and `CLAUDE.md` themselves.
- `planner` writes session-linked plan files to `~/.local/state/plans`. A `SessionStart` hook points at the session's plans, and says to work the one you name, else the newest, and to reread it.
- More in [claude/README.md](claude/README.md).

Codex:

- GPT-6.1 Sol runs the parent at xhigh, ordinary subagents at high and `scout` at medium. GPT-6 Astra runs `planner` and `verifier` at medium.
- At most three subagents run at the same time.
- Its `worker` replaces the built-in one. Its `planner` defaults to read-only and disables nested agents.

Grok:

- Its agents skip AGENTS.md (`agentsMd: false`).
- Its `scout` and `verifier` have no edit tools, and its `planner` is read-only.

opencode:

- Every agent denies nested agents and git or `gh` writes. Its `scout`, `verifier` and `planner` deny edits too.

All but Claude:

- Codex, Cursor and opencode cannot keep their rules out of a subagent, so each agent's own instructions win over them.
- Codex and Cursor cannot block edits, so their `verifier` reports each file it changed.
- Their planners write nothing. Each returns two to four steps, each backed by evidence, for the parent's plan or to-do list.

## Context

- Claude auto-compacts in a 400K window, and Grok at 80% of its 500K window, which is the same point.
- Claude's Haiku 5.5 compacts in a 100K window, because a Haiku prompt over 100K tokens costs 5 times more.
- Codex uses the native compaction defaults of the selected model. Its parent keeps one native plan, and after compaction or resume it recovers the accepted steps, checks and approvals.

## Safety

- No tool runs a git hook.
- Claude's deny list is the source. It refuses resets, branch switches, rebases, amends, stashes, worktree commands, history rewrites, tag and ref deletes, force and delete pushes, forced fetches, and the `wt` and `gh` commands that change or delete a branch, a repo or a release, also after a global option such as `git -C`.
- Grok, Cursor and opencode copy that list in their own syntax. Codex's prefix rules refuse the forms that begin a command.
- Each tool's rules cover the rest, and `add`, `commit`, `push` and a new pull request still need your request.
- Claude allows a subagent with worktree isolation, which Claude Code keeps in its own folder under `.claude/worktrees/`. It denies `EnterWorktree` and subagents with cloud isolation.
- Add `.claude/worktrees/` to your global gitignore, so git and search tools in the main folder skip the worktrees.
- Codex uses Full Access with `on-request` approvals. Ordinary local work runs directly. Rules ask first for deletion, credential tools, direct package publishing and named recipes that write outside the repo.
- Unattended Codex work that you ask for can select `never`. Prefix rules are a backstop, not a full command parser.

## MCP

- The servers are context7 and [Paper](https://paper.design) Desktop.
- Export `CONTEXT7_API_KEY`.
- For Codex, add the key by hand as `[mcp_servers.context7.http_headers]` in `~/.codex/config.toml`.

## Skills

Mine, under the repo's MIT license:

- `bet`: plans test coverage as a Branching Expectation Tree.
- `context-doctor`: trims AGENTS.md, CLAUDE.md, rules and skills to what earns its tokens.
- `diagnose`: finds a bug's cause from a command that shows the failure, tests ranked hypotheses that a run can disprove, and proves the fix with the same command.
- `handoff`: summarizes a conversation into a handoff document and a kickoff prompt that any model, harness or tool set can continue from.
- `intent`: writes intent trees that people align on, from epics and user stories down to acceptance criteria, then audits, checks and verifies the code against them. Its `verify` mode uses `typesafe-ai`, and `verify static` judges from the code alone.
- `paper-use`: builds, mirrors and audits Paper design files.
- `rate`: scores work on every axis until each is 10.
- `retro`: turns a session's mistakes and corrections into the strongest fix, such as a check, a hook, a script, a skill edit or a rule, and asks before it edits.
- `slim-context`: restructures a repo's agent context files. Three subagents each propose a version, from a trim of no-ops to a root file of pointers, and the repo changes only after you pick one.
- `ui-principles`: rules for clean, scannable UI layout.
- `wayfinder`: maps the open decisions of an idea too big for one session in a local file, and resolves one decision per session until nothing is left to decide.

Vendored. Each folder keeps its upstream `LICENSE`:

- `agent-browser` from [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), Apache-2.0.
- `grilling` from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
- `ponytail`, `ponytail-audit`, `ponytail-debt` and `ponytail-review` from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT.
- `thermo-nuclear-code-quality-review` from [cursor/plugins](https://github.com/cursor/plugins), MIT.
- `typesafe-ai` from [typesafe-ai/skills](https://github.com/typesafe-ai/skills), MIT.

Changes from upstream: a shorter `description` and a `metadata` block in the `SKILL.md` frontmatter, and an `agents/openai.yaml` with the Codex display name. `typesafe-ai` is unchanged.

Skills that start only by name:

- `grilling` and the four `ponytail` skills start only when you type their name.
- Claude reads `skillOverrides`. The installed copies get `disable-model-invocation` for Cursor and Grok, and `allow_implicit_invocation: false` for Codex. opencode denies them to its skill tool.
- `bet` and `thermo-nuclear-code-quality-review` are off in Claude, Codex and Grok, and opencode denies them too. Cursor has no switch for them.

## License

[MIT](LICENSE), except the vendored skills, which keep their own licenses.
