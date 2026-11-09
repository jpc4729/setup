# setup

My agent setup, Claude Code first. I build and tune it in Claude Code. Codex, Cursor, Grok and opencode get the same rules, git approval rules, subagents and 21 skills, each in its own syntax and on its analogous models.

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
  Sonnet 5.5 · medium  Opus 5.5 · high     Opus 5.5 · medium   Opus 5.5 · high
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
- Claude's ask list is the source of the git approval rules in the other tools.
- Only Claude Code has the `clerk` subagent. The other tools have `scout`, `worker`, `verifier`, `planner`, `researcher`, `reviewer` and `browser`, and run the same flow. In them, no subagent starts another agent.
- Each tool gives each role its analogous model:

```text
role       Claude Code          Codex                  Cursor       Grok               opencode
main       Opus 5.5 · xhigh     GPT-6.1 Sol · xhigh    your pick    grok-4.6 · high    glm-5.3-flash · high
scout      Sonnet 5.5 · medium  GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
worker     Opus 5.5 · medium    GPT-6.1 Sol · high     Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
verifier   Opus 5.5 · high      GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
planner    Opus 5.5 · high      GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
clerk      Haiku 5.5 · high     none                   none         none               none
researcher Sonnet 5.5 · high    GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
reviewer   Opus 5.5 · high      GPT-6 Astra · medium   Opus 5.5     grok-4.6 · xhigh   glm-5.3 · high
browser    Sonnet 5.5 · high    GPT-6.1 Sol · medium   Sonnet 5.5   grok-4.6 · high    glm-5.3-flash · high
```

- Cursor uses the main model you pick in the app. Grok's subagents use its default model and set only the effort.

## Install

You need bash, rsync, [jq](https://jqlang.org) and [yq](https://github.com/mikefarah/yq). The worktree layout also needs [Worktrunk](https://worktrunk.dev). The herdr config also needs [herdr](https://herdr.dev). `cs` also needs zsh, git, [fzf](https://github.com/junegunn/fzf) 0.66 or later and [ripgrep](https://github.com/BurntSushi/ripgrep).

```sh
git clone https://github.com/jpc4729/setup.git
cd setup
./install.sh -n   # list what would change
./install.sh
```

- First, edit the models, login and themes in `claude/settings.json`, `codex/config.toml`, `grok/config.toml` and `opencode/opencode.jsonc`. They are mine.
- Put `~/.local/bin` on your PATH. Every tool runs its checks through `quiet`.
- If your `~/.zshrc` aliases `rm`, `cp` or `mv` to `-i`, set those aliases only in a terminal, such as inside `if [[ -t 0 && -z ${CLAUDECODE-}${AI_AGENT-} ]]; then ... fi`. Agents load your aliases, and an agent's `rm <file>` then waits at `remove <file>?` until it times out.
- Export `CONTEXT7_API_KEY`. For Codex, also add it as `[mcp_servers.context7.http_headers]` in `~/.codex/config.toml`.
- Run `./install.sh` again after you pull.

## What install.sh does

- Copies each tool folder into its home. A replaced file stays beside it as `<name>.bak`.
- Merges the five settings files that the apps rewrite. Repo keys win, and the app's own keys stay.
- Copies the skills into `~/.agents/skills` and `~/.cursor/skills`, and links them into `~/.claude/skills`.
- Copies `bin/quiet`, `bin/scratch`, `bin/agent-stats` and `bin/cs` into `~/.local/bin`.
- Copies `src/AGENTS.md` into `~/.local/src`, and merges `worktrunk/config.toml` into `~/.config/worktrunk/config.toml`.
- Merges `herdr/config.toml` into `~/.config/herdr/config.toml`, and copies `herdr/status.sh` beside it. Run `herdr server reload-config` to load it in a running herdr. Copies the `repo-label` plugin into `~/.config/herdr/plugins` and links it: each workspace in `~/.local/src/<owner>/<repo>/<folder>` gets the label `<repo>`, not herdr's `main` or branch folder. When the workspace leaves `~/.local/src`, it gets herdr's label for its folder again. A name you give a workspace stays. `herdr plugin disable local.repo-label` turns it off.
- On macOS, installs Codex's `requirements.toml` as a managed preference.
- Never links and never deletes. A link would carry agent state back into the repo.

## Layout

```text
claude/            → ~/.claude             the reference: rules, settings, eight agents, hooks, status line, worklog mod (off)
codex/             → ~/.codex              rules, config, seven agents, policy, command rules
cursor/            → ~/.cursor             rules, seven agents, MCP, permissions
grok/              → ~/.grok               rules, config, seven agents
opencode/          → ~/.config/opencode    rules, config, seven agents
skills/my-skills/  → ~/.agents/skills      skills I wrote or adapted
skills/vendored/   → ~/.agents/skills      vendored skills, pinned in skills-lock.json
bin/quiet          → ~/.local/bin/quiet    one line on a pass, full output on a failure
bin/scratch        → ~/.local/bin/         a new task folder in /tmp/agents/<owner>/<repo>/ for an agent's temp files
bin/agent-stats    → ~/.local/bin/         Claude Code agent runs, minutes, efforts and quality guards
bin/cs             → ~/.local/bin/         start, go to or resume a Claude Code session in ~/.local/src
src/AGENTS.md      → ~/.local/src/         layout, branch names and cleanup for each clone and worktree
worktrunk/         → ~/.config/worktrunk   the worktree path for that layout, merged
herdr/             → ~/.config/herdr       theme, tab bar, host vitals and repo labels for herdr, config merged
docs/                                      the cs demo and the VHS tape that makes it
AGENTS.md                                  rules for an agent that edits this repo
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

- Reads are free. A git write or a pull request waits for your ask. One ask to commit or push covers a run of work, and each other write needs its own ask.
- An agent changes the branch in the session's folder or makes a worktree only when you ask.
- Agents and subagents work in the session's folder and branch, and an agent tells you when work needs its own branch. Claude also denies worktree isolation.

## Worktrees

- Each clone and worktree is in `~/.local/src/<owner>/<repo>/<branch>`. The primary clone is the folder of the default branch, such as `main`, and stays on it.
- Worktrunk makes each worktree there: `wt switch -c feat/oauth-refresh` makes `feat-oauth-refresh/`.
- Branch names are `<type>/<slug>`: a Conventional Commits type, then 2 to 5 lowercase words in kebab-case.
- An agent opens as few pull requests as possible. It puts all the work you give it in a checkout, of any type or area, on that branch for one pull request. It suggests a second branch or pull request only when you ask, or when the work is in another repo.
- When you ask an agent in a checkout or a repo folder for a new worktree, it makes the worktree with `wt switch -c` and does no work in it. It gives you one command that starts a session there with the same Claude Code account, then a kickoff prompt, with a handoff document when the conversation has context that the new session needs.
- `cs`, from any folder, opens a picker, a table that shows only your repos: first the repos with a session that waits for you (blocked or done), then the one with your latest Claude Code session. The right arrow opens a repo to its checkouts and a checkout to its sessions, the left arrow closes, and a closed row still shows a blocked or done session under it. The table fits the rows that show and the window: a column with no value is gone, a narrow window gives up the path, then the owner, the account and the status word, and a resize redraws it. A checkout shows its branch and changes: enter starts `claude` there with the selected profile. Enter on a repo row starts `claude` in the repo folder. The top of the preview shows each Claude Code profile that is logged in, `~/.claude` as `default` and each `~/.claude-<name>`, with its session and week limits and when the fuller one resets. The hint `tab profile` means that tab and shift-tab change the profile that is selected: `cs` starts on the one with the most room, marks it in that block and shows it with its used percent in the prompt. While `cs` shows, it refreshes the limits in the background, at most once per 5 minutes per home, with `claude -p "/usage"`, which is not a documented use and sends no model request. The refresh needs a logged-in Claude Code and no extra setup. Under each checkout come its sessions open in herdr (enter goes to its pane) and its sessions among the 10 latest that do not run (enter resumes one in its folder with the account that owns it). Typing searches every row, by exact text, so a search for a repo or branch also keeps its sessions. The args go to `claude`, such as `cs -c`, except, in any place, `--<name>` for the account `~/.claude-<name>`, such as `cs --work`, or `--config <path>` for any config home, such as `cs --config ~/work/claude-home`: a new session then starts with that account, which the prompt shows and tab can still change, and a resume keeps the account that owns the session. The sessions in a `--config` home also show. A `--config` folder must exist. ctrl-t on any row opens a new shell in its folder, with no claude: a script cannot move the shell that started it, and `exit` goes back. An account `<name>` is the config home `~/.claude-<name>`.

  ![cs with example repos: the picker lists the repos, with the Claude Code profiles and their limits at the top of the preview and the selected profile in the prompt. Tab moves the selection to the next profile. The picker then opens a repo to its checkouts and a checkout to its sessions, with a preview of the selected row. A search for login keeps a checkout and its session, and ctrl-t opens a shell in that checkout.](docs/cs.gif)

  Two settings change what `cs` shows. Export them in `~/.zshrc`, or set them before the command, such as `CS_LAYOUT=flat cs`: `cs` is a script, so a variable that is not exported does not reach it.
  - `CS_LAYOUT=flat` shows the checkouts, then the sessions open in herdr, then the recent ones, in place of the tree.
  - `CS_BRANCH_INFO` adds branch data, none by default: `base` for the commits ahead and behind the default branch `origin/HEAD`, such as `main +4 -1`, `merged` for a pushed branch with no commit that the default branch lacks, or `gone` when its upstream is gone, and `pr` for its pull request in the preview under the profiles, from [gh](https://cli.github.com). For example, `export CS_BRANCH_INFO='base merged'`.

  To make the demo again after a change to `cs`, run `vhs docs/cs.tape` from the repo root. It needs [VHS](https://github.com/charmbracelet/vhs), and `docs/cs-demo.sh` builds the example repos, sessions and profiles in `/tmp/cs-demo`.

- To open `cs` in each new herdr pane, tab or workspace that has the focus, add these lines to `~/.zshrc`. Esc gives the prompt. A pane opened with `--no-focus`, as scripts and agents do before `herdr pane run` or `herdr agent start`, gets a plain prompt. `CS_AUTO_PANE` holds the pane ID, so a later shell in the pane, such as the one ctrl-t opens, does not open `cs` again.

  ```zsh
  if [[ -n ${HERDR_PANE_ID-} && ${CS_AUTO_PANE-} != "$HERDR_PANE_ID" ]] && (( $+commands[cs] )); then
    export CS_AUTO_PANE=$HERDR_PANE_ID
    autoload -Uz add-zsh-hook
    _cs_first_prompt() {
      add-zsh-hook -d precmd _cs_first_prompt
      herdr pane get "$HERDR_PANE_ID" 2> /dev/null | jq -e .result.pane.focused > /dev/null && cs
    }
    precmd_functions=(_cs_first_prompt $precmd_functions)
  fi
  ```

- `~/.local/src/AGENTS.md` has the full rules. Claude Code reads it in each session under `~/.local/src`, because `claude/settings.json` loads `AGENTS.md` together with `CLAUDE.md`.

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

- Claude's ask list is the source. Codex, Grok and opencode copy it in their own syntax, and each risky git write asks you first.
- Among others, it covers resets, branch switches, rebases, amends, stashes, history rewrites, force and delete pushes, and branch, repo and release deletes.
- Codex's prefix rules catch only the start of a command. Its rules text covers the rest.
- The Cursor CLI has no ask list, so these commands prompt like every other command. With `--force`, they run with no prompt.
- No tool runs a git hook.

## Why

Git and branches:

- One folder has one branch, one index and one set of files. A branch change by one agent changes the files under every other agent there.
- A worktree has its own index, so its commits and its pull request hold only its own changes.
- Agents work in your folder and branch, so you see each change where you work. You decide when work gets its own worktree.
- Hard limits are permission rules, not text or hooks. In Claude, an ask rule prompts even when the tool approves commands on its own. A Claude hook that times out, crashes or is missing lets the command run.
- Git writes and pull requests wait for your ask, so you decide what changes your work and what leaves your machine.

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

The 22 skills are in [skills/](skills/README.md), one copy for every tool:

- `skills/my-skills/`: 11 skills that I wrote, or adapted from other skills, such as `wayfinder` and `handoff` from Matt Pocock's skills.
- `skills/vendored/`: 8 skills from upstream, each with its upstream `LICENSE`.

## License

[MIT](LICENSE), except the vendored skills, which keep their own licenses. [skills/README.md](skills/README.md) names the source of each adapted skill.
