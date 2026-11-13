# skills

Every skill in this setup. `./install.sh` copies each skill folder into `~/.agents/skills` and `~/.cursor/skills`, and links it into `~/.claude/skills`, so one copy serves every tool. This README stays in the repo.

## my-skills

Skills that I wrote, or that I adapted, changed or took ideas from another skill, vendored or public. They are under the repo's MIT license. When a skill comes from another one, its line names the source.

- `context-doctor`: trims agent context files to what earns its tokens.
- `emil-kowalski-ui-skills`: routes a motion or touch-feel request to the right file of [Emil Kowalski's skills](https://github.com/emilkowalski/skills), MIT. `install.sh` fetches a copy pinned to one commit into `~/.local/share/emil-kowalski-ui-skills/`, and the skill reads it there.
- `diagnose`: finds a bug's cause from a command that shows the failure. Inspired by [diagnosing-bugs](https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs) from Matt Pocock's skills, MIT.
- `handoff`: turns a conversation into a handoff document and a kickoff prompt. Adapted from [handoff](https://github.com/mattpocock/skills/tree/main/skills/productivity/handoff) from Matt Pocock's skills, MIT.
- `intent`: writes intent trees, then checks the code against them.
- `paper-use`: builds, mirrors and audits Paper design files.
- `retro`: turns a session's mistakes into a check, hook, script or rule. Adapted from [retro](https://github.com/mattpocock/skills/tree/main/skills/engineering/retro) from Matt Pocock's skills, MIT.
- `sharpen-prompt`: rewrites a rough prompt into a short, direct one. When you ask, it uses a Claude Code session as context, found by its ID or by a search.
- `skills-claude`: writes, reviews or fixes a skill to the standards of the native Claude Code skills.
- `ui-principles`: rules for clean, scannable UI layout.
- `verify-setup`: writes a repo's `.claude/skills/verify/SKILL.md`, the recipe that agents follow to prove a change in the real app. Inspired by `create-verification-skill` from poteto's [pstack](https://github.com/cursor/plugins/tree/main/pstack), MIT.
- `wayfinder`: settles the open decisions of a big idea, one per session. Adapted from [wayfinder](https://github.com/mattpocock/skills/tree/main/skills/engineering/wayfinder) from Matt Pocock's skills, MIT.

## vendored

Skills from upstream, pinned in [`../skills-lock.json`](../skills-lock.json), each with its upstream `LICENSE`:

- `agent-browser` from [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), Apache-2.0.
- `grilling` from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
- `ponytail`, `ponytail-audit`, `ponytail-debt` and `ponytail-review` from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT.
- `security-audit` from [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill), MIT.
- `thermo-nuclear-code-quality-review` from [cursor/plugins](https://github.com/cursor/plugins), MIT.
- Changes from upstream: a shorter `description`, a `metadata` block and a Codex `agents/openai.yaml`. `security-audit` is unchanged.

## Start rules

- Each skill in `my-skills` but `emil-kowalski-ui-skills`, `sharpen-prompt` and `ui-principles` starts only when you type its name: `disable-model-invocation: true` for Claude Code, Cursor and Grok, and `allow_implicit_invocation: false` for Codex. opencode ignores those flags.
- `grilling`, the four `ponytail` skills and `security-audit` start only when you type their name.
- `thermo-nuclear-code-quality-review` is off in every tool but Cursor, which has no switch for it.
