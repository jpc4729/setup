# setup

My agent setup, Claude Code first. I build and tune it in Claude Code. Codex, Cursor, Grok and opencode get the same rules, git deny lists, subagents and 21 skills, each in its own syntax and on its analogous models.

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

## Claude Code first

- `claude/` is the reference. A change starts there, and each other tool copies it in its own syntax.
- Claude's deny list is the source of the git deny lists in the other tools.
- Only Claude Code has the `clerk` subagent and the advisor. The other tools have `scout`, `worker`, `verifier` and `planner`.
- Each tool gives each role its analogous model:

```text
role       Claude Code          Codex                  Cursor       Grok               opencode
main       Opus 5.5 · xhigh     GPT-6.1 Sol · xhigh    your pick    grok-4.6 · high    glm-5.3-flash · high
scout      Sonnet 5.5 · high    GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
worker     Opus 5.5 · xhigh     GPT-6.1 Sol · high     Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
verifier   Opus 5.5 · xhigh     GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
planner    Opus 5.5 · xhigh     GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
clerk      Haiku 5.5 · medium   none                   none         none               none
advisor    Opus 5.5             none                   none         none               none
```

- Cursor uses the main model you pick in the app. Grok's subagents use its default model and set only the effort.

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
claude/            → ~/.claude             the reference: rules, settings, five agents, hooks, status line
codex/             → ~/.codex              rules, config, four agents, policy, command rules
cursor/            → ~/.cursor             rules, four agents, MCP, permissions
grok/              → ~/.grok               rules, config, four agents
opencode/          → ~/.config/opencode    rules, config, four agents
skills/my-skills/  → ~/.agents/skills      skills I wrote or adapted
skills/vendored/   → ~/.agents/skills      vendored skills, pinned in skills-lock.json
bin/quiet          → ~/.local/bin/quiet    one line on a pass, full output on a failure
```

## Rules

Every tool gets the same short core:

- Do exactly what you ask, at the quality a strict senior reviewer would approve.
- Check the smallest thing while working, then run the repo's checks on the changed files only.
- Follow the repo's test rule. When it has none, decide if a test is worth it, from similar code and the repo's standards, with no dummy tests.
- Do each step, also outside the repo, and stop only at a critical step: data that nothing can bring back, money, a production or shared system, something sent as you, credentials or access, or what only you have.
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

The 21 skills are in [skills/](skills/README.md), one copy for every tool:

- `skills/my-skills/`: 13 skills that I wrote, or adapted from other skills, such as `wayfinder` and `handoff` from Matt Pocock's skills.
- `skills/vendored/`: 8 skills from upstream, each with its upstream `LICENSE`.

## License

[MIT](LICENSE), except the vendored skills, which keep their own licenses. [skills/README.md](skills/README.md) names the source of each adapted skill.
