# setup

My agent setup for Claude Code, Codex, Cursor, Grok and opencode. It holds one set of rules, git deny lists and 18 skills.

## Install

Needs bash, rsync, [jq](https://jqlang.org) and [yq](https://github.com/mikefarah/yq).

```sh
git clone https://github.com/josechifflet/setup.git
cd setup
./install.sh -n   # list what would change
./install.sh
```

1. Each tool folder is copied into its home. A replaced file stays beside it as `<name>.bak`.
2. Five settings files are merged, not copied, because the apps rewrite them: `claude/settings.json`, `codex/config.toml`, `grok/config.toml`, `cursor/mcp.json` and `cursor/cli-config.json`. Keys here win; keys the app wrote stay.
3. Skills are copied into `~/.agents/skills` and `~/.cursor/skills`, and each is linked into `~/.claude/skills`. A skill folder with the same name is replaced; other skills are left alone. `grilling` and the four `ponytail` skills start only when you type their name: Claude reads `skillOverrides`, the installed copies get `disable-model-invocation` for Cursor and Grok and `allow_implicit_invocation: false` for Codex, and opencode denies them to its skill tool. `bet` and `thermo-nuclear-code-quality-review` are off in Claude, Codex and Grok, and opencode denies them too; Cursor has no switch for them.
4. `bin/quiet` is copied into `~/.local/bin`. Put that folder on your PATH: every tool runs its checks through `quiet`.
5. On macOS, Codex's `requirements.toml` is also installed as the managed `com.openai.codex` preference, so Codex enforces its approval policies and runs no hook from another config.

Copies, not symlinks: every agent writes state into its home, and a symlink would carry it back into the repo. Re-run `install.sh` after you pull. It never deletes, so remove a file the repo dropped by hand: an older install leaves obsolete files in `~/.claude/agents`, `~/.codex/agents`, `~/.cursor/agents`, `~/.grok/agents` and `~/.config/opencode/agents` (keep `planner`, `scout`, `verifier` and `worker` in each, and `clerk` in `~/.claude/agents`), the old `~/.config/opencode/agent` folder, and `~/.agents/AGENTS.md`, which no tool reads. The `behaviour` skill is now `intent`, so delete `behaviour` from `~/.agents/skills`, `~/.cursor/skills` and `~/.claude/skills`. No tool runs a git hook now, so delete `block-dangerous-git.sh` and `block-worktree.sh` from `~/.claude/hooks`, `block-dangerous-git.sh` from `~/.codex/hooks`, and `block-dangerous-git.sh` and `git-safety.json` from `~/.grok/hooks`. The settings merge keeps keys the repo dropped, so delete `disableArtifact`, `env.ENABLE_CLAUDEAI_MCP_SERVERS` and `env.CLAUDE_CODE_AUTO_COMPACT_WINDOW` from `~/.claude/settings.json`, and `hooks.PreToolUse` and `features.hooks` from `~/.codex/config.toml`.

## Layout

```text
agents/my-skills/  → ~/.agents/skills      skills I wrote
agents/skills/     → ~/.agents/skills      vendored skills, pinned in skills-lock.json
bin/quiet          → ~/.local/bin/quiet    one line on a pass, full output on a failure
claude/            → ~/.claude             CLAUDE.md, settings, planner, scout, verifier, worker, clerk, session-plans and nested-agents hooks, status line; see claude/README.md
codex/             → ~/.codex              AGENTS.md, config, planner, scout, verifier, worker, managed policy, command rules
cursor/            → ~/.cursor             rule, planner, scout, verifier, worker, MCP, permissions
grok/              → ~/.grok               AGENTS.md, config, planner, scout, verifier, worker
opencode/          → ~/.config/opencode    AGENTS.md, config, planner, scout, verifier, worker
```

## How it works

- **Rules.** Each tool gets the same core, which keeps scope and quality apart: scope is exactly the request, including the tests, error handling and files it needs, and quality is what a strict senior reviewer would approve, never traded for speed or a smaller diff. Agents fix causes, iterate until the narrowest check passes and run the gate when all the work is done, review their work before they report and stop, keep going unless blocked or about to delete data or change something outside the repo, write to you in ASD-STE100 Simplified Technical English, and list only findings they can back with evidence. Each tool also sizes each piece of work: Fast by default, Verify with its `verifier` subagent when a mistake is costly or hard to see, and Align, 10 lines at most with a pick, when the request reads two ways or the choice is yours. A question that a run can answer is run, not asked. When you ask for two models, Claude, Codex, Cursor and Grok also send the same brief to a second `verifier` on another model. Each checks code by reading first, runs checks through `quiet`, and never weakens a test to make it pass. Git reads run freely, and `add`, `commit` and `push` run once you ask. Every other git write goes to you as the exact command, and no agent or subagent leaves the branch or checkout its session started in. Two more rules cover what each tool can start on its own. Claude and Grok start a workflow only when your message contains `ultracode` and stop its retry loops after 3 rounds. Codex creates a goal, a scheduled task or a cloud task only when you ask, and marks a goal blocked after 3 turns on the same blocker. Cursor starts a loop, autopilot, automation or cloud agent only when you ask, and stops a loop after 3 rounds. opencode has no workflow feature, so it has no such rule.
- **Context.** Claude auto-compacts in a 400K window and Grok at 80% of its 500K window, the same point. Claude's Haiku 5.5 compacts in a 100K window, because a Haiku prompt over 100K tokens costs 5 times more. Codex uses the selected model's native compaction defaults. Its parent maintains one native plan and recovers the accepted steps, checks and approvals after compaction or resume.
- **Subagents.** Every tool defines `planner`, `scout`, `verifier` and `worker`, each in its own format, and each prompt follows the style of Claude Code's built-in `general-purpose` prompt. `planner` runs only when you name it. `scout`, a read-only agent, maps what exists and the open decisions before Align. `verifier` tries to refute finished work, reads first, runs only what reading cannot settle, and reports each part of the request that is missing, extra or wrong. `worker` is an improved `general-purpose` for delegated work (research, code search, multi-step tasks and code changes): it finds the repo's coding rules before it writes code, runs a command that shows a bug's failure before it edits, works to a named finish line, and reports what it needs from the parent first. Each agent knows that a message without a tool call ends its turn, so it keeps working until its report is ready. Claude also has `clerk`, a Haiku 5.5 agent for one narrow task its brief spells out, such as a summary, a list, a count or a mechanical change; Claude's other four agents can start clerks, and a `PreToolUse` hook stops them from starting any other agent. Claude's agents skip every CLAUDE.md file (`omitClaudeMd`); all but `clerk` read the repo's `AGENTS.md` and `CLAUDE.md` themselves. Grok's skip AGENTS.md (`agentsMd: false`); its `scout` and `verifier` have no edit tools, and its `planner` is read-only. Every opencode agent denies nested agents and git or `gh` writes, and its `scout`, `verifier` and `planner` deny edits too. Codex, Cursor and opencode cannot keep their rules out of a subagent, so each agent's own instructions win over them; Codex and Cursor cannot block edits either, so their `verifier` reports each file it changed. Claude writes session-linked plan files to `~/.local/state/plans`, with a `SessionStart` hook that points at the session's plans and says to work the one you name, else the newest, and to reread it. The other tools' planners write nothing and return two to four evidence-backed steps for the parent's plan or to-do list; Codex's defaults to read-only and disables nested agents. Codex uses GPT-6.1 Sol at xhigh for the parent, high for ordinary subagents and medium for `scout`, and GPT-6 Astra at medium for `planner` and `verifier`, with at most three concurrent subagents; its `worker` replaces the built-in one. Otherwise each tool uses its built-in subagents. Every tool hands a subagent a read across many files or long logs, a large change split into independent parts on disjoint files, or the `verifier`'s fresh-context review of a long run before it reports, gives delegated work to `worker` rather than the built-in general agent, works directly when the reads and edits are few, and reviews every diff a subagent returns.
- **Safety.** Codex uses Full Access with `on-request` approvals: ordinary local work can run directly, while rules prompt for deletion, credential tools, direct package publishing and named recipes that write outside the repo. Explicitly requested unattended work can select `never`. Prefix rules are a backstop, not a complete command parser. No tool runs a git hook. Claude's deny list is the source: it refuses resets, branch switches, rebases, amends, stashes, worktrees, force and delete pushes, and the `wt` and `gh` commands that change a branch, also after a global option such as `git -C`. Grok, Cursor and opencode mirror it in their own syntax, and Codex's prefix rules refuse the forms that begin a command. Each tool's rules bind the rest and still need your request for `add`, `commit` and `push`. Claude also denies subagents with worktree isolation.
- **MCP.** context7 and [Paper](https://paper.design) Desktop. Export `CONTEXT7_API_KEY`. For Codex, add the key by hand as `[mcp_servers.context7.http_headers]` in `~/.codex/config.toml`.

The models, login method and themes are mine. Edit `claude/settings.json`, `codex/config.toml`, `grok/config.toml` and `opencode/opencode.jsonc` before you install.

## Skills

Mine, under the repo's MIT license:

- `bet`: plans test coverage as a Branching Expectation Tree.
- `context-doctor`: trims AGENTS.md, CLAUDE.md, rules and skills to what earns its tokens.
- `diagnose`: finds a bug's cause from a command that shows the failure, tests ranked hypotheses a run can disprove, and proves the fix with the same command.
- `handoff`: summarizes a conversation into a handoff document and a kickoff prompt that any model, harness or tool set can continue from.
- `intent`: writes intent trees people align on, from epics and user stories down to acceptance criteria, refining an outcome into finer trees, then audits, checks and verifies the code against them. Its `verify` mode uses `typesafe-ai`, and `verify static` judges from the code alone.
- `paper-use`: builds, mirrors and audits Paper design files.
- `rate`: scores work on every axis until each is 10.
- `retro`: turns a session's mistakes and corrections into the strongest fix (a check, a hook, a script, a skill edit or a rule) and asks before it edits.
- `ui-principles`: rules for clean, scannable UI layout.
- `wayfinder`: maps the open decisions of an idea too big for one session in a local file, and resolves one decision per session until nothing is left to decide.

Vendored. Each folder keeps its upstream `LICENSE`:

- `agent-browser` from [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), Apache-2.0.
- `grilling` from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
- `ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-review` from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT.
- `thermo-nuclear-code-quality-review` from [cursor/plugins](https://github.com/cursor/plugins), MIT.
- `typesafe-ai` from [typesafe-ai/skills](https://github.com/typesafe-ai/skills), MIT.

Changes from upstream: a shorter `description` and a `metadata` block in the `SKILL.md` frontmatter, plus an `agents/openai.yaml` with the Codex display name. `typesafe-ai` is unchanged.

## License

[MIT](LICENSE), except the vendored skills, which keep their own licenses.
