# Minimal replacements

Open this file only when a necessary instruction needs rewriting or a new home. The deletion sequence and acceptance criteria are in `references/triage.md`. An omitted file is preferable to an empty template.

## Retained rule

Keep a rule whose obvious alternative causes a specific failure:

```markdown
1. Never edit `src/schema/generated/`; run `just codegen`.
```

Keep a command exception when the task runner alone does not reveal the trap:

```markdown
1. Run tests through `just test <path>`; bare `pytest` skips fixture setup.
```

These illustrate shape, not facts to copy. Fill names from the repository. Add an install command, stack summary, Git policy, or definition of done only when it survives the deletion sequence.

## Smallest new file

Copy `assets/AGENTS.md.template` only when the user requests scaffolding or necessary rules have no existing home. Replace the single placeholder with proven instructions. Add a heading only when it improves the surviving text. Delete unused placeholders; if nothing survives, create nothing.

A nested file holds only necessary differences for its task scope. Do not create one per directory or link every nested file from the root.

## Loader adapters

Prefer `AGENTS.md`. Do not create a `CLAUDE.md`. Delete a leftover pointer or fold unique rules into `AGENTS.md`. Do not create bridges for unused tools.

Use `assets/claude-rule.template.md` or `assets/cursor-rule.template.mdc` only when an existing native rule scope is needed. Fill the real glob and the same surviving rule body. Create both only if both loaders need them; do not grow a second rules tree by default.

When changing load behavior, verify the active tool's current documentation or local configuration through the relevant section of `references/tool-matrix.md`. A generic prose pointer is not a substitute for a required loader import.

## Checkup invocation

Use `/context-doctor checkup`. Do not install repository-local Markdown wrappers for this invocation.

## Scaffold from intake

1. Identify a concrete repository hazard or explicit rule that code and configuration do not already communicate.
2. Prefer an existing loaded file. Otherwise fill the minimal asset with only those instructions.
3. Add only the entry points required by tools actually in use. No hazard means no new file.
4. Verify commands, paths, scope, and strict helper findings. Describe any necessary increase in context.

In a dotfiles source repository, work through the existing sources and apply workflow; do not scaffold new live tool-home files.
