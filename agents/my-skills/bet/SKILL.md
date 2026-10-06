---
name: bet
description: "Plans test coverage as a Branching Expectation Tree (.tree). Use for a test plan, coverage audit or edge cases. Use intent for specs that people align on."
argument-hint: "[path or feature]"
disable-model-invocation: true
metadata:
  short-description: "Branching Expectation Tree test plans"
---

# Branching Expectation Trees (BET)

Map every expected behavior of a unit into a `.tree` spec before writing tests. A behavior missing from the tree
either does not exist or has not been thought through. Never encode an unconfirmed assumption: the tree then looks
complete, passes review, and generates tests for the wrong behavior. Ask instead of assuming.

Works for anything with branching behavior: endpoints, components, pages, flows, CLI commands, state machines,
infrastructure, pipelines.

Read `references/tree-syntax.md` before writing any tree — notation, common mistakes, complete examples.

## Composability (optional)

This skill defines the process, not domain knowledge. A domain skill is any other installed skill that knows the
kind of unit being specified — a REST-API skill, a React-component skill, a data-pipeline skill. A domain skill
works without BET, and can extend it with a `bet/` subdirectory next to its own `SKILL.md`; each file is optional,
use whichever exist:

- `bet/categories.md` — requirement categories to check in Phase 1; one heading per category, bullets of what to probe
- `bet/tree-examples.md` — reference `.tree` specs for the domain; patterns for Phase 2
- `bet/framework-mapping.md` — tree-node → test-code mapping for the domain's framework; used in Phase 4

## Workflow

```text
BET Progress:
- [ ] Phase 0: Recognition (codebase + domain skill discovery)
- [ ] Phase 1: Requirements discovery (extract, classify, probe gaps, confirm)
- [ ] Phase 2: Write tree (from confirmed requirements only)
- [ ] Phase 3: Review tree with user
- [ ] Phase 4: Generate test skeleton (optional -- skip for requirements-only use)
```

## Phase 0: Recognition

1. Identify the unit: function, endpoint, component, stack, pipeline, flow.
2. Codebase context: check config files for stack and test framework; read 2-3 existing test files for conventions.
3. Tree placement: `.tree` sibling to the test file, mirroring its name. No test file yet → co-locate with where the
   test will live per project conventions, not next to the source file.
4. Domain skill discovery: scan the skills available in the session (the skill list in context, or skill roots such
   as `~/.claude/skills/`) for one matching the unit's domain; if it has a `bet/` subdirectory, note which of the
   three files exist (see Composability). Run the check even when categories feel obvious — a matching
   `categories.md` can list dimensions you would not derive yourself. No match — the common case: record "none";
   Phases 1, 2 and 4 derive everything from the codebase and the user.

Summarize before proceeding:

```text
Unit: {what is being specified}
Stack: {language + framework}
Tests: {test file pattern and style}
Tree: {where the .tree file goes}
Domain skill: {name, or "none -- deriving categories from unit"}
```

## Phase 1: Requirements Discovery

This phase gates everything: every branch must trace to a confirmed requirement.

### Step 1 — extract from available sources

- Source code: guard clauses → error requirements, validation → constraints, conditionals → behaviors,
  side effects → outcomes
- Existing tests: what is and is not covered
- Docs, contracts, docstrings: constraints, error conditions, expected behaviors
- User request only: extract explicit statements, flag everything implied
- Source shows what IS, not what SHOULD BE — ambiguity it reveals (silent failure path, undocumented side effect) →
  confirm with the user before encoding it as a branch

### Step 2 — classify into categories

Domain skill has `bet/categories.md` → load it and check every category, even ones the user did not mention;
missing categories are where missing branches hide. No domain skill → derive from these universal dimensions,
then add domain-specific axes:

- Preconditions: what states must exist before this unit runs?
- Inputs: what variations in input change behavior?
- Outputs / effects: what observable things does this unit produce or cause?
- Errors / failures: what can go wrong, and what happens when it does?
- Boundaries: what are the edges (limits, permissions, timeouts, empty sets)?

### Step 3 — probe for missing branches

- Two questions per category: can I write this branch (flags ambiguity); is this category represented at all
  (surfaces missing dimensions)?
- A category with zero requirements usually means nobody thought about it, not that it is irrelevant
- Non-obvious probes: who else might call this; if a side effect fails, does the operation partially succeed; exact
  boundary values; concurrent/repeated execution
- Flag all gaps as `[ ] ???`

### Step 4 — present checklist and ask

Mark confirmed `[x]`, gaps `[ ] ???`:

```text
## Requirements: {unit name}

### {Category A}
- [x] Known behavior from source code
- [ ] ??? Ambiguous: does X happen before or after Y?

### {Category B}
- [x] Confirmed by user
- [ ] ??? Not mentioned anywhere -- is this relevant?
```

Ask about every `???`. Items the user defers or declines become `// OUT OF SCOPE:` markers in the tree, never
silently dropped.

### Step 5 — confirm the final checklist before proceeding

Skip the confirmation round only when source code is unambiguous and every path is already clear — rare.

## Phase 2: Write Tree

Enter only with confirmed requirements. Read `references/tree-syntax.md` for notation; read the domain skill's
`bet/tree-examples.md`, if present, for domain patterns.

- Fail-fast ordering: guard conditions and error paths first, happy path last — mirrors guard-clause code
- Traceability: every branch traces to a confirmed requirement, every requirement appears as a branch. Cross-check
  after writing — a missing branch is a missing test, an orphan branch is an unconfirmed assumption
- Mark deliberate exclusions: `// OUT OF SCOPE: idempotency -- not yet defined`; distinguishes "decided not to
  cover" from "forgot about it"
- Lint: run `scripts/lint-tree <file>.tree` (in this skill's directory) and fix every diagnostic

## Phase 3: Review Tree

Review with user before generating code:

- `scripts/lint-tree` passes with zero diagnostics?
- Every confirmed requirement has a branch?
- Guard clauses come first?
- Happy path enumerates all side effects?
- Readable by non-engineers?
- Out-of-scope markers present for skipped items?

## Phase 4: Generate Test Skeleton (optional)

Domain skill has `bet/framework-mapping.md` → load it for stack conventions; otherwise derive from the codebase.
Universal mapping:

- Root → top-level test suite / class / module
- `given` / `when` → nested group (describe, context, inner class, mod)
- `it should` → individual test case
- Sub-assertions → comments inside the test body, not separate tests

Read 2-3 existing test files and mirror their nesting, naming, and setup exactly. Generate structure, names, and
setup comments only — never assertion bodies: the tree defines WHAT to test, not HOW to assert.

Skip this phase entirely when BET is used for requirements definition only.
