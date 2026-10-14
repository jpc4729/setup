# setup

My agent setup, Claude Code first. I build and tune it in Claude Code. Codex, Cursor, Grok and opencode get the same rules, git deny lists, subagents and 21 skills, each in its own syntax and on its analogous models.

```text
              CLAUDE CODE SUBAGENTS · OPUS 5.5 + SONNET 5.5 + HAIKU 5.5

                        Opus 5.5 · xhigh · main session
                                      |
        one flow for every task: understand, plan, build, check, review once,
                    report. A small task skips the plan.
                                      |
          +-------------------+-------+-----------+-------------------+
          |                   |                   |                   |
        scout              planner              worker             verifier
          |                   |                   |                   |
  Sonnet 5.5 · high    Opus 5.5 · high     Opus 5.5 · high     Opus 5.5 · high
          |                   |                   |                   |
   facts before a       1-5 tickets for     builds a ticket     one reviews the
  question to you      work with 2+ parts    or a task          whole diff once,
     read-only                                                     read-only
          |                   |                   |                   |
          +-------------------+-------+-----------+-------------------+
                                      |
                 main session runs the checks, one fix round,
                         a report, and never a score

  by kind of work: researcher (Sonnet 5.5 · high) for the web, reviewer (Opus 5.5 ·
         high) for defects, browser (Sonnet 5.5 · high) for a real browser

  scout, planner and reviewer can start a Haiku 5.5 clerk, and worker and verifier
          a clerk or a browser. No subagent can start any other agent.
          Map with Sonnet. Read with Haiku. Write and judge with Opus.
```

## Claude Code first

- `claude/` is the reference. A change starts there, and each other tool copies it in its own syntax.
- Claude's deny list is the source of the git deny lists in the other tools.
- Only Claude Code has the `clerk` subagent. The other tools have `scout`, `worker`, `verifier`, `planner`, `researcher`, `reviewer` and `browser`, and run the same flow. In them, no subagent starts another agent.
- Each tool gives each role its analogous model:

```text
role       Claude Code          Codex                  Cursor       Grok               opencode
main       Opus 5.5 · xhigh     GPT-6.1 Sol · xhigh    your pick    grok-4.6 · high    glm-5.3-flash · high
scout      Sonnet 5.5 · high    GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
worker     Opus 5.5 · high      GPT-6.1 Sol · high     Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
verifier   Opus 5.5 · high      GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
planner    Opus 5.5 · high      GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
clerk      Haiku 5.5 · high     none                   none         none               none
researcher Sonnet 5.5 · high    GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
reviewer   Opus 5.5 · high      GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
browser    Sonnet 5.5 · high    GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
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
claude/            → ~/.claude             the reference: rules, settings, eight agents, hooks, status line
codex/             → ~/.codex              rules, config, seven agents, policy, command rules
cursor/            → ~/.cursor             rules, seven agents, MCP, permissions
grok/              → ~/.grok               rules, config, seven agents
opencode/          → ~/.config/opencode    rules, config, seven agents
skills/my-skills/  → ~/.agents/skills      skills I wrote or adapted
skills/vendored/   → ~/.agents/skills      vendored skills, pinned in skills-lock.json
bin/quiet          → ~/.local/bin/quiet    one line on a pass, full output on a failure
```

## Rules

Every tool gets the same short core:

- Do exactly what you ask, at the quality a strict senior reviewer would approve.
- Check the smallest thing while working, then run the repo's checks on the changed files only.
- Follow the repo's test rule. When it has none, decide if a test is worth it, from similar code and the repo's standards, through the public interface by default, with no dummy tests.
- Do each step, also outside the repo, and stop only at a critical step: data that nothing can bring back, money, a production or shared system, something sent as you, credentials or access, or what only you have.
- Reply in ASD-STE100 Simplified Technical English, with evidence and no bold.
- Run one flow for every task: understand, plan, build, check, review once, report. A small task skips the plan.
- Start a workflow, loop or cloud task only when you ask, with 3 retry rounds at most.

Git:

- Reads are free. `add`, `commit`, `push` and a pull request wait for your ask.
- Any other git write comes to you as the exact command.
- No agent changes the branch in the session's folder.
- Agents and subagents work in the session's folder and branch. Only you make a worktree, and an agent tells you when work needs its own branch. Claude also denies worktree isolation.

## Subagents

- `scout`: finds the facts before a question to you. Read-only.
- `worker`: does delegated work: research, search, multi-step tasks and code changes.
- `verifier`: checks finished work claim by claim, with no bias to find problems. One line per claim, then a verdict. One `verifier` reviews the whole diff of a plan. Without a plan, one starts only when a mistake is costly: a schema or stored data, money, login or permissions, concurrency, or an API that others use.
- `planner`: writes 1 to 5 tickets when the work has two or more parts, and a fresh `worker` builds each one. Where the planner is read-only, as in Codex, Grok and opencode, it returns the plan and the main session saves it.
- `clerk`: Claude only. One narrow task on Haiku 5.5, such as a summary, a list or a count.
- `researcher`: answers one question from the web and current docs, and gives each fact with its URL and the date of the source. Read-only.
- `reviewer`: finds the defects in a diff or an area of code, most severe first, each with its evidence. It does not fix. Unlike `verifier`, it starts from no list of claims.
- `browser`: checks a web page or app in a real browser with the `agent-browser` CLI, and gives PASS or FAIL for each expected result. It changes no code.
- In Claude Code, `scout`, `planner` and `reviewer` can start a `clerk`, and `worker` and `verifier` a `clerk` or a `browser`. The `nested-agents.sh` hook refuses any other agent type and any `model` override. A `clerk`, `researcher` or `browser` starts nothing.
- The parent gives subagents wide reads, big split changes and reviews, and checks each diff they return. The final review reads the diffs of plan tickets.
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
- Agents work in your folder and branch, so you see each change where you work. You decide when work gets its own worktree.
- Hard limits are deny rules, not text or hooks. In Claude and Grok, a deny rule holds even when the tool approves commands on its own. A Claude hook that times out, crashes or is missing lets the command run.
- Commits, pushes and pull requests wait for your ask, so you decide what leaves your machine.

Short text:

- Less text means better adherence, and each rule line costs context in every request.
- STE and no bold: one meaning per word, and easy to scan.
- `quiet` keeps a long passing log out of the context.
- In Claude Code, the `bash-reads.sh` hook refuses a Bash command that prints a file through `cat`, `sed`, `head`, `tail` or `nl`, and tells the agent to use Read with a line range. The rule as text alone did not hold. A pipe, a redirect, a heredoc, `sed -i`, a file under a temp folder and a command such as `git diff` still pass.
- One review round and one fix round, never a score: loops of review cost the most time.

Subagents:

- A subagent keeps the main context small: it does the wide read or the long run, and only its result comes back.
- `scout`, `verifier`, `reviewer`, `researcher` and `browser` do not edit: a map does not change what it maps, a judge does not fix what it judges, and a check does not change what it checks.
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
