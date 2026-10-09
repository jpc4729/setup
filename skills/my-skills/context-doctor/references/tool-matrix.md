# Tool matrix

Loading reference. Read only the section for an active tool when changing its load path. Verify version-sensitive claims against the installed tool or its current documentation; this file is not proof of the loaded set.

A home surface is named only where it changes what a project file must carry, and it never counts toward a project byte total. A tool ships a behaviour change more often than this file is read, so treat `Re-check before resting a finding on it` as an open list.

## Portable files

- `AGENTS.md` — the canonical always-on handbook. Claude Code, Codex, Cursor, Grok, OpenCode and Windsurf read it.
- `AGENTS.override.md` — in Codex it replaces `AGENTS.md` for that one directory. Rare, and easy to miss. Claude Code never reads it.
- `CLAUDE.md` — leftover Claude Code file. Prefer `AGENTS.md`. Delete a pointer or fold a unique body into `AGENTS.md`. A `CLAUDE.md` on the project path hides `AGENTS.md`.

## Claude Code

Docs: https://code.claude.com/docs/en/memory

- From v2.1.277, reads `AGENTS.md` and `.claude/AGENTS.md` when there is no `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in the working directory or above it. `~/.claude/CLAUDE.md` and managed policy do not count. Default Project instructions is `claude-md-or-agents-md`.
- A `CLAUDE.md` or `CLAUDE.local.md` on that path hides `AGENTS.md`. Claude then reads `CLAUDE.md` files only, unless Project instructions is `claude-md-and-agents-md`.
- A one-line `@AGENTS.md` in `CLAUDE.md` still works and is never a double load. Delete it anyway. Prefer `AGENTS.md`. Bedrock, Vertex, Foundry, telemetry off, and versions before 2.1.277 still cannot load `AGENTS.md`; that is a host gap, not a reason to keep a bridge.
- Session start also reads `.claude/AGENTS.md` at the same scopes as `AGENTS.md`.
- A nested `AGENTS.md` loads when Claude reads a file in that subtree and that directory has none of the three `CLAUDE.md` files of its own.
- Does not read `AGENTS.local.md`, `AGENTS.override.md`, or anything under `.agents/`.
- A directly loaded `AGENTS.md` does not appear in `/memory` or `/context`; look for the `AGENTS.md loaded` line. `InstructionsLoaded` hooks do not fire for it.
- Loads `./CLAUDE.md` and `./.claude/CLAUDE.md` — both, where both exist — plus `CLAUDE.local.md`, from the working directory and every directory above it, concatenated root-first. The file nearest the cwd is read last.
- A file below the cwd is not loaded at launch. It loads when Claude reads a file in that subtree, so a nested `CLAUDE.md` is a lazy load and never a guarantee.
- `.claude/rules/**/*.md`, recursive under the project root and under each ancestor that carries the directory. Without `paths` a rule loads every session; with `paths` it loads when a matching file is read.
- `@path` imports expand at launch, relative to the importing file, and recurse at most four hops. An import inside a code span or a fence is skipped, deliberately, so a path can be named without being loaded.
- An import costs the same context as the text inlined. It removes duplication, not bytes.
- A `CLAUDE.md` over 4 MiB is skipped. HTML comments are stripped before injection here, and only here.
- Auto-memory is `MEMORY.md` under the tool home (first 200 lines or 25 KiB). Machine-local, never committed.
- Enforcement is hooks plus `.claude/settings.json` permissions. Prose is not enforcement.
- Proof: `/context` lists the loaded memory files and `/memory` opens them, but both are user-run UI commands. The scriptable proof is the `InstructionsLoaded` hook, whose payload names each file and why it loaded.

## Codex CLI

Docs: https://agents.md and https://developers.openai.com/codex/config-reference

- Reads `AGENTS.md`. It reads `CLAUDE.md` only if that name is added to `project_doc_fallback_filenames`.
- Walks the global file, then each directory from the repo root down to the cwd, taking at most one file per directory: `AGENTS.override.md`, else `AGENTS.md`, else a configured fallback.
- Concatenates root-first, so the nearest file wins a conflict.
- Stops at the cwd. A sibling directory is never read, a file below the cwd is never read, and there is no lazy subdirectory load. The launch directory decides the whole body.
- Never reads `.claude/rules/` or `.cursor/rules/`. Anything Codex needs lives in an `AGENTS.md`.
- Hard cap `project_doc_max_bytes`, 32 KiB by default, on the merged chain and not on one file. Once the running total reaches the cap Codex stops adding, with no warning, so a fat root is what drops the nested files.
- Proof: `codex debug prompt-input` renders the model-visible prompt as JSON. Grep it for a marker string taken from each `AGENTS.md` in the chain; a marker that is absent was dropped or never loaded.

## Cursor

Docs: https://cursor.com/docs/rules

- Reads the project-root `AGENTS.md`, and a nested `AGENTS.md` for that directory and below.
- Reads `.cursor/rules/*.mdc`, which may nest in subdirectories. A plain `.md` there is ignored — the most common silent failure in this tree, and worse than it looks, because Grok does read that `.md`.
- Rule frontmatter is `description`, `globs` and `alwaysApply`, giving four modes: always on, auto-attached on a glob match, agent-requested from the description, and manual by `@`-mention.
- Never reads `.claude/rules/`. A repo that keeps its real rules there hands Cursor a strictly smaller body unless an `AGENTS.md` names the directory in prose.
- Legacy `.cursorrules` still loads. Never add new unique content to it.

## Grok

Docs: https://docs.x.ai/build/features/project-rules

- The widest reader here, and therefore the tool that exposes every duplicate a repo has.
- Per directory, from the repo root down to the cwd, it reads every matching name: `Agents.md`, `Claude.md`, `CLAUDE.md`, `CLAUDE.local.md`, `AGENT.md`, `AGENTS.md`, plus `.claude/CLAUDE.md` and `.claude/CLAUDE.local.md`, and every `*.md` under `.grok/rules/`, `.claude/rules/` and `.cursor/rules/`.
- It does not expand `@` imports. A one-line `@AGENTS.md` is inert text; a symlink `CLAUDE.md` → `AGENTS.md` is a real file whose body is the handbook, loaded beside `AGENTS.md`.
- The compatibility scan is `*.md` only, so an `.mdc` Cursor rule is invisible here and a `.md`/`.mdc` pair loads once.
- What does load twice here is one body written as `*.md` in two rules trees, or two recognized handbook names in one directory.
- Deeper files win a conflict. Files load in full. There is no size cap. A file matched by `.gitignore` is skipped, which is what makes `CLAUDE.local.md` a personal override.
- Proof: `grok inspect` prints every rules file found, with its path and an approximate token count.

## OpenCode

Docs: https://opencode.ai/docs/rules/

- Walks up from the current directory for `AGENTS.md`, and falls back to `CLAUDE.md` only where no `AGENTS.md` exists. Both present means only `AGENTS.md` is read, so a body in `CLAUDE.md` is a fork this tool never sees rather than a double load.
- Global fallback order is `~/.config/opencode/AGENTS.md`, then `~/.claude/CLAUDE.md`.
- `opencode.json` or `opencode.jsonc` carries an `instructions` array of paths, globs and remote URLs, combined with whatever discovery found. It is the only supported way to load an arbitrary-path doc into every session, and listing `AGENTS.md` or `CLAUDE.md` there loads that file a second time.
- The Claude Code compatibility layer also picks up `~/.claude/skills/`.
- Treat the `CLAUDE.md` fallback as version-dependent and never as the mechanism a repo relies on.

## GitHub Copilot

Docs: https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions

- Reads `.github/copilot-instructions.md`, plus path-scoped `.github/instructions/*.instructions.md` with `applyTo` frontmatter. A dead `applyTo` glob is the same silent miss as a dead `paths` entry.
- Agent surfaces also read `AGENTS.md` (nearest first) and, on some of them, root `CLAUDE.md` or `GEMINI.md`. Where both `AGENTS.md` and `.github/copilot-instructions.md` exist, both are used.
- Prefer omitting `.github/copilot-instructions.md` when `AGENTS.md` already loads; a one-line pointer only where that surface will not read `AGENTS.md`.

## Windsurf and Cascade

Docs: https://docs.windsurf.com/windsurf/cascade/agents-md

- Reads `AGENTS.md` in any directory. Root is always-on; a nested file auto-globs to that subtree.
- Native rules live under `.windsurf/rules/` or `.devin/rules/`, capped at 12000 characters per workspace rule file. The 6000-character cap belongs to the single global rules file, which is a home file. There is no documented cap on the tree.
- Never maintain a unique Windsurf essay. Keep the scoped files tiny or omit them.

## Gemini CLI and Jules

Docs: https://geminicli.com/docs/cli/gemini-md

- Defaults to `GEMINI.md` and supports project-relative `@./path` imports.
- `context.fileName` in settings can be `AGENTS.md`, or a list of names. Configure that rather than forking a second handbook.

## Skills across tools

Docs: https://code.claude.com/docs/en/skills, https://learn.chatgpt.com/docs/build-skills, https://cursor.com/docs/skills, and `~/.grok/docs/user-guide/08-skills.md` in a Grok install.

A skill is a directory holding `SKILL.md`, and all four tools agree on that much and on requiring `name` and `description`. Everything below that line is forked, and the forks are silent.

- `.agents/skills/` is the one tree every tool reads. Codex reads it and `$HOME/.agents/skills` and nothing else — never `~/.claude/skills` — so a library that lives only under a vendor directory is invisible to Codex.
- Cursor reads `.agents/skills/` and `.cursor/skills/`, their `~` twins, and `.claude/skills/` and `.codex/skills/` for compatibility. It scans recursively, so grouping skills in category subdirectories costs nothing.
- Grok reads `.grok/`, `.agents/`, `.claude/` and `.cursor/` skill directories at the local, repo and user tier, deduplicating by name so the highest tier wins. Vendor scanning is switched off per vendor under `[compat.claude]` or `[compat.cursor]` in `~/.grok/config.toml`.
- Claude Code reads `.claude/skills/` and `~/.claude/skills/` plus plugin and bundled skills. A symlink farm from `.claude/skills/` into `.agents/skills/` is how one body reaches it and Codex at once.
- `name` must be lowercase letters, digits and hyphens, 2 to 64 characters, and equal to the directory name. Cursor requires the match; Grok silently rewrites spaces and underscores to hyphens, so a name that disagrees answers to neither.
- The trigger key is forked: Claude Code reads `when_to_use`, Grok reads `when-to-use`. Carrying one reaches one host. Carry both, or neither and put the triggers in `description`.
- Claude Code concatenates `description` and the trigger key and truncates the pair at 1,536 characters with no marker, so a long trigger list eats the end of the description rather than erroring.
- Listing budgets differ: Claude Code spends 1% of the context window and drops descriptions least-used-first on overflow; Codex spends 2%, or 8,000 characters when the window is unknown.
- `disable-model-invocation: true` is honoured by Claude Code, Cursor and Grok. Codex expresses the same thing as `policy.allow_implicit_invocation: false` in `agents/openai.yaml`. Setting one without the other is a skill that auto-activates in three tools and hides in the fourth.
- Display strings are per-tool: Grok promotes `metadata.short-description`, Codex reads `interface.display_name` and `interface.short_description` from `agents/openai.yaml`. Neither falls back to the other.
- Everything else is a two-tool field at best — `paths` is Claude Code and Cursor, `argument-hint`, `allowed-tools`, `model`, `effort`, `license` and `compatibility` are Claude Code and Grok, `icon` and `color` are Cursor alone. An unrecognised key is ignored, never an error, which is why a typo here is invisible.

Proof: `grok inspect --json` lists every skill Grok resolved with its source path and `userInvocable`. Claude Code shows the post-budget listing size in `/context` and estimates it in `/doctor`.

## Scan these paths

From the repo root, and again under every directory that carries a rules tree:

```text
AGENTS.md  AGENTS.override.md  AGENT.md  Agents.md
CLAUDE.md  CLAUDE.local.md  Claude.md  GEMINI.md  CONTEXT.md  MEMORY.md
.cursorrules  .windsurfrules
.github/copilot-instructions.md  .github/instructions/
opencode.json  opencode.jsonc  .opencode/opencode.json
.claude/  .cursor/  .codex/  .grok/  .opencode/  .agents/  .windsurf/  .devin/  .gemini/
```

User-global, never committed, never counted in a project total:

```text
~/.claude/CLAUDE.md  ~/.claude/rules/  ~/.codex/AGENTS.md
~/.config/opencode/AGENTS.md  ~/.agents/AGENTS.md
```

## Re-check before resting a finding on it

- Whether Cursor's nested `AGENTS.md` support has a depth or size limit.
- Whether an OpenCode `instructions` glob resolves from the project root or the config file.
- Whether Copilot reads `AGENTS.md` on every surface this repo's contributors actually use.
- Whether Grok ever reads `.mdc` (documented as `*.md` only).
- Whether Claude Code still concatenates `./CLAUDE.md` and `./.claude/CLAUDE.md` when both are one-line pointers.
- Whether a nested `.claude/AGENTS.md` loads on demand the same way a nested `AGENTS.md` does.
