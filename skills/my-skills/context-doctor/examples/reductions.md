# Target-codebase reduction cases

Use these cases to check the decisions an audit makes. The snippets are illustrative; verify the equivalent facts in the target repository. They are not boilerplate to install or evidence of agent performance.

## Derivable facts beside a real hazard

Evidence: the manifest and normal setup expose the runtime and ordinary commands. The task wrapper performs fixture setup that a direct runner omits. The generated client has a documented generator.

Before:

```markdown
# Agent instructions

This repository uses Python 3.12. Sources live in src and tests live in tests.
Use readable names and follow best practices. Keep the code clean.
Run tests with just test. Run the formatter before finishing.
Never edit the generated client directly.
Regenerate src/client/ with just client; never patch it manually.
Run tests through just test <path>; bare pytest skips fixture setup.
```

Expected reduction:

```markdown
1. Regenerate `src/client/` with `just client`; never patch it manually.
2. Run tests through `just test <path>`; bare `pytest` skips fixture setup.
```

Delete the tour, exposed version, generic advice, and redundant command. Delete the formatter reminder only after verifying that the relevant formatting obligation is already satisfied elsewhere. Retain both non-obvious contracts. Stopping because the original file was below 60 lines fails this case.

## Similar words with different obligations

Before:

```markdown
Do not modify production fixtures. Local fixtures can be rebuilt with just fixtures.
Ask before changing a public response shape.
Review generated API changes before publishing.
```

These are three distinct contracts. Removing “production,” deleting the local exception, converting “ask before” into “test before,” or treating regeneration as review fails. Shorten wording only if those decisions survive. A present linter configuration does not establish that any of them is enforced.

## Duplicate rules across scopes

Root says to use pnpm. The website handbook repeats that instruction and adds a screenshot command needed only for visual changes. Another tool adapter repeats the whole root.

Delete the repeated package-manager instruction only if the root reaches website tasks. Keep the screenshot exception in its narrower scope. Remove the adapter's duplicate body only after verifying the tool still receives the root through an existing load mechanism. Prefer `AGENTS.md`. Delete a leftover `CLAUDE.md`. Do not add adapters for unused tools.

Probe a website visual change and an unrelated backend edit. The first must receive the screenshot command; the second must gain no unconditional screenshot guidance. A nested npm instruction is a possible exception or conflict, not a paraphrase of pnpm.

## A short root with expensive destinations

Root imports a long agent-only handbook and tells the agent to read a human design document before every change. A README also links to the human document.

Audit the handbook recursively. Delete its redundant content and unnecessary callers. Replace the broad human-document read with a concrete trigger only if a task needs it; leave the human document and README link intact. Removing an unnecessary pointer to a listed skill must preserve the skill and its discovery link.

Count the handbook, new destinations, and triggered reads in both snapshots. Moving unchanged text to a new file, replacing paragraphs with an import, or deleting a skill to lower the report fails. A short root alone is no evidence of reduced context.

## Controls and evaluation

A file containing only the evidenced fixture and approval contracts may already be minimal. An empty repository with no uncovered hazard needs no new context file. Both should remain unchanged.

For a real evaluation, run the skill on a copy of a target codebase and review the produced diff. Check inventory coverage, every known redundant block, preserved contracts, unchanged unrelated files, and task reach. Execute representative tasks when available; label paper reasoning separately. Lower token cost is required but insufficient. Use temporary outputs; do not add an audit framework to the target codebase.
