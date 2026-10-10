# skills

Every skill in this setup. `./install.sh` copies each skill folder into `~/.agents/skills` and `~/.cursor/skills`, and links it into `~/.claude/skills`, so one copy serves every tool. This README stays in the repo.

## my-skills

Skills that I wrote, or that I adapted, changed or took ideas from another skill, vendored or public. They are under the repo's MIT license. When a skill comes from another one, its line names the source.

- `adhd-human`: makes each reply ultra concise for a reader with ADHD, with the answer first and at most 20 short lines.
- `bet`: plans test coverage as a Branching Expectation Tree.
- `context-doctor`: trims agent context files to what earns its tokens.
- `diagnose`: finds a bug's cause from a command that shows the failure. Inspired by [diagnosing-bugs](https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs) from Matt Pocock's skills, MIT.
- `handoff`: turns a conversation into a handoff document and a kickoff prompt. Adapted from [handoff](https://github.com/mattpocock/skills/tree/main/skills/productivity/handoff) from Matt Pocock's skills, MIT.
- `intent`: writes intent trees, then checks the code against them.
- `paper-use`: builds, mirrors and audits Paper design files.
- `rate`: scores work on every axis until each is 10.
- `read-only`: keeps the agent to reading and analysis. It changes nothing and puts any change it proposes in its reply.
- `retro`: turns a session's mistakes into a check, hook, script or rule. Adapted from [retro](https://github.com/mattpocock/skills/tree/main/skills/engineering/retro) from Matt Pocock's skills, MIT.
- `skills-claude`: writes, reviews or fixes a skill to the standards of the native Claude Code skills.
- `ui-principles`: rules for clean, scannable UI layout.
- `wayfinder`: settles the open decisions of a big idea, one per session. Adapted from [wayfinder](https://github.com/mattpocock/skills/tree/main/skills/engineering/wayfinder) from Matt Pocock's skills, MIT.

## vendored

Skills from upstream, pinned in [`../skills-lock.json`](../skills-lock.json), each with its upstream `LICENSE`:

- `agent-browser` from [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser), Apache-2.0.
- `grilling` from [mattpocock/skills](https://github.com/mattpocock/skills), MIT.
- `ponytail`, `ponytail-audit`, `ponytail-debt` and `ponytail-review` from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT.
- `thermo-nuclear-code-quality-review` from [cursor/plugins](https://github.com/cursor/plugins), MIT.
- `typesafe-ai` from [typesafe-ai/skills](https://github.com/typesafe-ai/skills), MIT.
- Changes from upstream: a shorter `description`, a `metadata` block and a Codex `agents/openai.yaml`. `typesafe-ai` is unchanged.

## Start rules

- Each skill in `my-skills` but `ui-principles` starts only when you type its name: `disable-model-invocation: true` for Claude Code, Cursor and Grok, and `allow_implicit_invocation: false` for Codex. opencode ignores those flags, so there only `read-only` and `adhd-human` are held back, by `deny` entries in `opencode/opencode.jsonc`.
- `grilling` and the four `ponytail` skills start only when you type their name.
- `bet` and `thermo-nuclear-code-quality-review` are off in every tool but Cursor, which has no switch for them.
