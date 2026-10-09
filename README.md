# setup

My agent setup for Claude Code, Codex, Cursor, Grok and opencode: one set of rules, git deny lists, the same subagents and 19 skills.

```text
           CLAUDE CODE SUBAGENTS · OPUS 5.5 + SONNET 5.5 + HAIKU 5.5

                               Opus 5.5 · xhigh
                                 main session
                                       |         Fast    closest example,
                                       |                 cheapest check
                                       |         Verify  verifier checks
                                       |                 before the report
                                       |         Align   options and a pick,
                                       |                 acts unless costly
                                       |         advisor Opus 5.5
                                       |
                             delegate to subagents
                                       |
         +-------------------+---------+---------+-------------------+
         |                   |                   |                   |
       scout              worker               clerk              planner
         |                   |                   |                   |
 Sonnet 5.5 · high   Opus 5.5 · xhigh   Haiku 5.5 · medium   Opus 5.5 · xhigh
         |                   |                   |                   |
 maps what exists     edits + checks      summary, list,       one plan file
   before Align      research, search       count or a       multi-stage work
     read-only       multi-step tasks    spelled-out edit     only when named
         |                   |                   |                   |
         +-------------------+---------+---------+-------------------+
                                       |
                         back to main session · xhigh
                      reviews each diff, runs the checks
                                       |
                   +-------------------+-------------------+
                   |                                       |
             Fast or Align                              Verify
                   |                                       |
                   |                                   verifier
                   |                               Opus 5.5 · xhigh
                   |                                 fresh context
                   |                                claim by claim
                   |                                   read-only
                   |                                3 runs at most
                   |                                       |
                   +-------------------+-------------------+
                                       |
                                    report

  scout, worker, verifier and planner can start a clerk, and no other agent.
         Map with Sonnet. Read with Haiku. Write and judge with Opus.
```

## Install

You need bash, rsync, [jq](https://jqlang.org) and [yq](https://github.com/mikefarah/yq).

```sh
git clone https://github.com/josechifflet/setup.git
cd setup
./install.sh -n   # list what would change
./install.sh
```

- First, edit the models, login and themes in `claude/settings.json`, `codex/config.toml`, `grok/config.toml` and `opencode/opencode.jsonc`. They are mine.
- Put `~/.local/bin` on your PATH. Every tool runs its checks through `quiet`.
- Add `.claude/worktrees/` to your global gitignore, so git and search tools skip the worktrees.
- Export `CONTEXT7_API_KEY`. For Codex, also add it as `[mcp_servers.context7.http_headers]` in `~/.codex/config.toml`.
- Run `./install.sh` again after you pull.

## What install.sh does

- Copies each tool folder into its home. A replaced file stays beside it as `<name>.bak`.
- Merges the five settings files that the apps rewrite. Repo keys win, and the app's own keys stay.
- Copies the skills into `~/.agents/skills` and `~/.cursor/skills`, and links them into `~/.claude/skills`.
- Copies `bin/quiet` into `~/.local/bin`.
- On macOS, installs Codex's `requirements.toml` as a managed preference.
- Never links and never deletes. A link would carry agent state back into the repo.

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

Every tool gets the same short core:

- Do exactly what you ask, at the quality a strict senior reviewer would approve.
- Check the smallest thing while working, then run the repo's checks on the changed files only.
- Keep going until blocked, or until data or something outside the repo is at stake.
- Reply in ASD-STE100 Simplified Technical English, with evidence and no bold.
- Pick a path: Fast by default, Verify when a mistake is costly, Align when the choice is yours.
- Start a workflow, loop or cloud task only when you ask, with 3 retry rounds at most.

Git:

- Reads are free. `add`, `commit`, `push` and a pull request wait for your ask.
- Any other git write comes to you as the exact command.
- No agent changes the branch in the session's folder.
- Work that needs its own branch goes in a worktree. In Claude, a subagent with worktree isolation does it. In the other tools, only you make one.

## Subagents

- `scout`: maps what exists before Align. Read-only.
- `worker`: does delegated work: research, search, multi-step tasks and code changes.
- `verifier`: checks finished work claim by claim, with no bias to find problems. One line per claim, then a verdict.
- `planner`: writes a plan, only when you name it.
- `clerk`: Claude only. One narrow task on Haiku 5.5, such as a summary, a list or a count.
- The parent gives subagents wide reads, big split changes and reviews, and checks each diff they return.
- Details for Claude are in [claude/README.md](claude/README.md).

## Safety

- Claude's deny list is the source. Grok, Cursor and opencode copy it in their own syntax.
- Among others, it refuses resets, branch switches, rebases, amends, stashes, history rewrites, force and delete pushes, and branch, repo and release deletes.
- Codex's prefix rules catch only the start of a command. Its rules text covers the rest.
- No tool runs a git hook.

## Why

Git and branches:

- One folder has one branch, one index and one set of files. A branch change by one agent changes the files under every other agent there.
- A worktree has its own index, so its commits and its pull request hold only its own changes.
- In Claude, only worktree isolation makes a worktree, because Claude Code then keeps that agent out of your folder.
- Hard limits are deny rules, not text or hooks. In Claude and Grok, a deny rule holds even when the tool approves commands on its own. A Claude hook that times out, crashes or is missing lets the command run.
- Commits, pushes and pull requests wait for your ask, so you decide what leaves your machine.

Short text:

- Less text means better adherence, and each rule line costs context in every request.
- STE and no bold: one meaning per word, and easy to scan.
- `quiet` keeps a long passing log out of the context.
- Fast is the default. Heavy checks run only when a mistake costs much.

Subagents:

- A subagent keeps the main context small: it does the wide read or the long run, and only its result comes back.
- `scout` and `verifier` do not edit: a map does not change what it maps, and a judge does not fix what it judges.
- `verifier` starts with a fresh context and has no quota of problems, because invented findings cost extra rounds.
- Subagents do not follow the main session's rules, because "ask me" or "run the checks" would fight their jobs.
- `clerk` costs at least 20 times less than Opus 5.5 for a prompt up to 100K tokens. It is weaker at judgment, so the parent checks each result.
- The parent reviews each diff a subagent returns, because a report is a claim, not proof.

## Skills

Mine, under the repo's MIT license:

- `bet`: plans test coverage as a Branching Expectation Tree.
- `context-doctor`: trims agent context files to what earns its tokens.
- `diagnose`: finds a bug's cause from a command that shows the failure.
- `handoff`: turns a conversation into a handoff document and a kickoff prompt.
- `intent`: writes intent trees, then checks the code against them.
- `paper-use`: builds, mirrors and audits Paper design files.
- `rate`: scores work on every axis until each is 10.
- `retro`: turns a session's mistakes into a check, hook, script or rule.
- `slim-context`: proposes three restructurings of agent context files, and you pick one.
- `ui-principles`: rules for clean, scannable UI layout.
- `wayfinder`: settles the open decisions of a big idea, one per session.

Vendored, each with its upstream `LICENSE`:

- `agent-browser` from [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), Apache-2.0.
- `grilling` from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
- `ponytail`, `ponytail-audit`, `ponytail-debt` and `ponytail-review` from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT.
- `thermo-nuclear-code-quality-review` from [cursor/plugins](https://github.com/cursor/plugins), MIT.
- `typesafe-ai` from [typesafe-ai/skills](https://github.com/typesafe-ai/skills), MIT.
- Changes from upstream: a shorter `description`, a `metadata` block and a Codex `agents/openai.yaml`. `typesafe-ai` is unchanged.

Start rules:

- `grilling` and the four `ponytail` skills start only when you type their name.
- `bet` and `thermo-nuclear-code-quality-review` are off in every tool but Cursor, which has no switch for them.

## License

[MIT](LICENSE), except the vendored skills, which keep their own licenses.
