# ~/.local/src

This folder holds each git checkout on this Mac: each primary clone and each worktree. `install.sh` of the setup repo copies this file from `src/AGENTS.md`. Edit it there.

## Layout

```text
~/.local/src/
  AGENTS.md                  this file
  local-src.code-workspace   optional VS Code workspace, one folder per repo
  <owner>/                   GitHub user or org, as in the remote URL
    <repo>/                  repo name, as in the remote URL
      main/                  primary clone, always on the default branch
      feat-oauth-refresh/    worktree of the branch feat/oauth-refresh
```

- Each checkout is at `~/.local/src/<owner>/<repo>/<folder>`, three levels down. Put nothing else at these levels.
- The folder of a checkout is its branch name with each `/` changed to `-`. The name always tells which branch is checked out in it.
- The primary clone has the name of the default branch, usually `main`, and stays on that branch.
- Worktrunk (`wt`) makes the worktree paths from `worktree-path` in `~/.config/worktrunk/config.toml`.

## Branch names

- Use `<type>/<slug>`, with one `/` only. Worktrunk changes `/` to `-`, so `feat/a-b` and `feat-a/b` would get the same folder.
- `<type>` is a Conventional Commits type: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci` or `chore`. Use `exp` for work that you will not merge.
- `<slug>` is lowercase kebab-case (`a-z`, `0-9`, `-`), 2 to 5 words, at most 40 characters. Put the ticket key first when there is one: `fix/eng-142-token-refresh`.
- Keep the branch name of a pull request from another person.
- Do not use a branch name again after its merge. Start new work on a new branch.

## Commands

```sh
git clone https://github.com/<owner>/<repo>.git ~/.local/src/<owner>/<repo>/main   # add a repo
wt switch -c feat/oauth-refresh   # new branch and worktree, from the default branch
wt switch pr:123                  # worktree of the branch of pull request 123
wt switch ^                       # go to the primary clone
wt list                           # each worktree of this repo and its state
wt remove                         # remove this worktree, and its branch when merged
wt merge                          # squash into the local default branch, then remove the worktree
ls -d ~/.local/src/*/*/*/         # each checkout on this Mac
```

## Rules

- Never switch the branch in a checkout: its folder name then is wrong. Make a worktree for the other branch.
- Never delete or move a worktree folder by hand. Use `wt remove`. When a folder is already gone, run `git worktree prune` in the primary clone.
- Each repo has an `origin` remote before its first worktree. Worktrunk takes `<owner>` and `<repo>` from it.
- Untracked files, such as `.env` and `node_modules`, are separate in each worktree. Worktrunk copies them from the primary clone when it makes a worktree.
- Worktrees of one repo can run at the same time. Give each dev server its own port, for example with `{{ branch | hash_port }}` in the hooks of the repo's `.config/wt.toml`.
- Each week, run `wt list` in each repo you used and remove each merged worktree.
- When you use `local-src.code-workspace`, give it one folder per repo, `<owner>/<repo>`, named `<repo>`. VS Code shows each worktree in it and finds each checkout one level down as a Source Control repository. Add or remove a folder there only when you add or remove a repo.
- Remove a repo folder only when `wt list` shows no open work and `git log --branches --not --remotes` in the primary clone shows no commits.

## For agents

- You work in one checkout. Stay in it. A sibling folder is another branch of the same repo, and another agent can use it.
- Temp files go in the folder that `scratch <slug>` prints, `/tmp/agents/<owner>/<repo>/<slug>.XXXXXX`, with the same `<owner>/<repo>` as here.
- Make, move or remove a worktree, or switch the branch, only when the user asks. A switch makes the folder name wrong, so say so in your reply.
- To merge a pull request from a checkout, add `--repo <owner>/<repo>` to `gh pr merge`. Without it, `--delete-branch` switches the checkout to the default branch and deletes the local branch. With it, gh deletes only the remote branch. Remove the worktree later with `wt remove`.
- When the user asks for a new worktree, make it and give its work to a new session there. Do these steps, and do no work in the new worktree yourself:
  1. Use the branch name that the user gives, or make one by the rules above. Start from the default branch, unless the user names a base: add `--base <branch>`, or `--base @` for the branch of this checkout.
  2. Run `wt switch -c <branch> --no-cd --format json`, and take the path of the worktree from its output. In a repo folder `<owner>/<repo>/`, which is not a checkout, add `-C` with a checkout in it. Never add `-y`: the user approves the hooks of a repo.
  3. When this conversation has facts that the new session needs, such as the task, decisions or findings, write a handoff document as `~/.agents/skills/handoff/SKILL.md` tells.
  4. Give the user one command that starts a session in the new worktree, then the kickoff prompt from that skill in one fenced block. For Claude Code, keep the account of this session: `cd <path> && claude` when `CLAUDE_CONFIG_DIR` is not set, and `cd <path> && CLAUDE_CONFIG_DIR=<its value> claude` when it is set.
- Open as few pull requests as possible. Put all the work that the user gives you in this checkout on its branch, for one pull request: each item of a request, each follow-up, and each fix, feature, refactor, perf change or chore. Do not split work into more branches or pull requests by item, type, area or size, and do not suggest it.
- A branch can hold commits of different types. Its name takes the type of the main change.
- In the primary clone, give the user one branch name for all the work, with a name that follows the rules above. Suggest a second branch or pull request only when the user asks for it, or when the work is in another repo.
- For the code of a repo, its own `AGENTS.md` or `CLAUDE.md` comes before this file.
