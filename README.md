# setup

My agent setup for Claude Code, Codex, Cursor, Grok and opencode. It holds one set of rules, a git guard hook and 15 skills.

## Install

Needs bash, rsync, [jq](https://jqlang.org) and [yq](https://github.com/mikefarah/yq). The git hooks need only bash and awk.

```sh
git clone https://github.com/josechifflet/setup.git
cd setup
./install.sh -n   # list what would change
./install.sh
```

1. Each tool folder is copied into its home. A replaced file stays beside it as `<name>.bak`.
2. Five settings files are merged, not copied, because the apps rewrite them: `claude/settings.json`, `codex/config.toml`, `grok/config.toml`, `cursor/mcp.json` and `cursor/cli-config.json`. Keys here win; keys the app wrote stay.
3. Skills are copied into `~/.agents/skills` and `~/.cursor/skills`, and each is linked into `~/.claude/skills`. A skill folder with the same name is replaced; other skills are left alone.
4. `bin/quiet` is copied into `~/.local/bin`. Put that folder on your PATH: every tool runs its checks through `quiet`.
5. Codex's `requirements.toml` expands home paths. On macOS, it is also installed as the managed `com.openai.codex` preference so the required git hook runs. Other hosts use the hook in `config.toml`, after Codex's hook trust review.

Copies, not symlinks: every agent writes state into its home, and a symlink would carry it back into the repo. Re-run `install.sh` after you pull. It never deletes, so remove a file the repo dropped by hand: an older install leaves obsolete files in `~/.claude/agents`, `~/.codex/agents`, `~/.cursor/agents`, `~/.grok/agents` and `~/.config/opencode/agents` (keep `planner`, `scout`, `verifier` and `worker` in each), the old `~/.config/opencode/agent` folder, and `~/.agents/AGENTS.md`, which no tool reads. The `behaviour` skill is now `intent`, so delete `behaviour` from `~/.agents/skills`, `~/.cursor/skills` and `~/.claude/skills`. The settings merge keeps keys the repo dropped, so delete `disableArtifact`, `env.ENABLE_CLAUDEAI_MCP_SERVERS` and `skillOverrides.ponytail` from `~/.claude/settings.json`.

## Layout

```text
agents/my-skills/  → ~/.agents/skills      skills I wrote
agents/skills/     → ~/.agents/skills      vendored skills, pinned in skills-lock.json
bin/quiet          → ~/.local/bin/quiet    one line on a pass, full output on a failure
claude/            → ~/.claude             CLAUDE.md, settings, planner, scout, verifier, worker, hooks, status line; see claude/README.md
codex/             → ~/.codex              AGENTS.md, config, planner, scout, verifier, worker, managed policy, hook, command rules
cursor/            → ~/.cursor             rule, planner, scout, verifier, worker, MCP, permissions
grok/              → ~/.grok               AGENTS.md, config, planner, scout, verifier, worker, hook
opencode/          → ~/.config/opencode    AGENTS.md, config, planner, scout, verifier, worker
```

## How it works

- **Rules.** Each tool gets the same core, which keeps scope and quality apart: scope is exactly the request, including the tests, error handling and files it needs, and quality is what a strict senior reviewer would approve, never traded for speed or a smaller diff. Agents fix causes, iterate until the narrowest check passes and run the gate when all the work is done, review their work before they report and stop, keep going unless blocked or about to delete data or change something outside the repo, write to you in ASD-STE100 Simplified Technical English, and list only findings they can back with evidence. Each tool also sizes each piece of work: Fast by default, Verify with its `verifier` subagent when a mistake is costly or hard to see, and Align, 10 lines at most with a pick, when the request reads two ways or the choice is yours. Each checks code by reading first, runs checks through `quiet`, and never weakens a test to make it pass. Git reads run freely, and `add`, `commit` and `push` run once you ask. Every other git write goes to you as the exact command, and no agent or subagent leaves the branch or checkout its session started in. Two more rules cover what each tool can start on its own, and every tool but Claude works directly with the fewest subagents needed. Claude and Grok start a workflow only when your message contains `ultracode` and stop its retry loops after 3 rounds. Codex creates a goal, a scheduled task or a cloud task only when you ask, and marks a goal blocked after 3 turns on the same blocker. Cursor starts a loop, autopilot, automation or cloud agent only when you ask, and stops a loop after 3 rounds. opencode has no workflow feature, so it only keeps file search out of subagents but `scout`.
- **Context.** Claude auto-compacts at 400K tokens and Grok at 80% of its 500K window, the same point. Codex uses the selected model's native compaction defaults. Its parent maintains one native plan and recovers the accepted steps, checks and approvals after compaction or resume.
- **Subagents.** Every tool defines `planner`, `scout`, `verifier` and `worker`, each in its own format, and each prompt follows the style of Claude Code's built-in `general-purpose` prompt. `planner` runs only when you name it. `scout`, a read-only agent, maps what exists and the open decisions before Align. `verifier` tries to refute finished work, reads first, and runs only what reading cannot settle. `worker` is an improved `general-purpose` for delegated work (research, code search, multi-step tasks and code changes): it finds the repo's coding rules before it writes code, works to a named finish line, and reports what it needs from the parent first. Claude's four agents skip every CLAUDE.md file (`omitClaudeMd`) and read the repo's `AGENTS.md` and `CLAUDE.md` themselves. Grok's skip AGENTS.md (`agentsMd: false`); its `scout` and `verifier` have no edit tools, and its `planner` is read-only. Every opencode agent denies nested agents and git or `gh` writes, and its `scout`, `verifier` and `planner` deny edits too. Codex, Cursor and opencode cannot keep their rules out of a subagent, so each agent's own instructions win over them; Codex and Cursor cannot block edits either, so their `verifier` reports each file it changed. Claude writes session-linked plan files to `~/.local/state/plans`, with a `SessionStart` hook that points at the session's plans and says to work the one you name, else the newest, and to reread it. The other tools' planners write nothing and return two to four evidence-backed steps for the parent's plan or to-do list; Codex's defaults to read-only and disables nested agents. Codex uses GPT-6.1 Sol/max for the parent and planner, and GPT-6.1 Sol/xhigh for ordinary subagents, with at most three concurrent subagents; its `worker` replaces the built-in one. Otherwise each tool uses its built-in subagents. Claude hands a subagent a read across many files or long logs, a large change split into independent parts on disjoint files, or the `verifier`'s fresh-context review of a long run before it reports, gives delegated work to `worker` rather than `general-purpose`, works directly when the reads and edits are few, and reviews every diff a subagent returns. In the other tools, work stays in the parent unless you ask for or approve delegation, or the sizing calls for `scout` or `verifier`; a split change goes to `worker`.
- **Safety.** Codex uses Full Access with `on-request` approvals: ordinary local work can run directly, while rules prompt for deletion, credential tools, direct package publishing and named recipes that write outside the repo. Explicitly requested unattended work can select `never`. Prefix rules are a backstop, not a complete command parser. A `PreToolUse` Bash hook in Claude, Codex and Grok allows known git reads, `add`, `commit` and a plain `push`, and refuses `wt` and the `gh` commands that change a branch; the instructions still require your authorization for the allowed writes. Each refusal explains why. A second Claude hook refuses subagents and workflows that ask for a worktree. Claude's deny list repeats branch-change blocks because a failed hook can let a call run. Cursor and opencode deny branch changes and destructive git in config.
- **MCP.** context7 and [Paper](https://paper.design) Desktop. Export `CONTEXT7_API_KEY`. For Codex, add the key by hand as `[mcp_servers.context7.http_headers]` in `~/.codex/config.toml`.

The models, login method and themes are mine. Edit `claude/settings.json`, `codex/config.toml`, `grok/config.toml` and `opencode/opencode.jsonc` before you install.

## Skills

Mine, under the repo's MIT license:

- `bet`: plans test coverage as a Branching Expectation Tree.
- `context-doctor`: trims AGENTS.md, CLAUDE.md, rules and skills to what earns its tokens.
- `handoff`: summarizes a conversation into a handoff document and a kickoff prompt that any model, harness or tool set can continue from.
- `intent`: writes intent trees people align on, from epics and user stories down to acceptance criteria, refining an outcome into finer trees, then audits, checks and verifies the code against them. Its `verify` mode uses `typesafe-ai`, and `verify static` judges from the code alone.
- `paper-use`: builds, mirrors and audits Paper design files.
- `rate`: scores work on every axis until each is 10.
- `ui-principles`: rules for clean, scannable UI layout.

Vendored. Each folder keeps its upstream `LICENSE`:

- `agent-browser` from [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), Apache-2.0.
- `grilling` from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
- `ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-review` from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT.
- `thermo-nuclear-code-quality-review` from [cursor/plugins](https://github.com/cursor/plugins), MIT.
- `typesafe-ai` from [typesafe-ai/skills](https://github.com/typesafe-ai/skills), MIT.

Changes from upstream: a shorter `description` and a `metadata` block in the `SKILL.md` frontmatter, plus an `agents/openai.yaml` with the Codex display name. `typesafe-ai` is unchanged.

## License

[MIT](LICENSE), except the vendored skills, which keep their own licenses.
