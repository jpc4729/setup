---
name: context-doctor
description: "Minimizes agent-context Markdown in the target repository: AGENTS.md, CLAUDE.md, rules, skills, and the docs they load."
argument-hint: "[checkup | treat | scaffold]"
disable-model-invocation: true
metadata:
  short-description: "Minimize the target repository’s agent-context Markdown"
---

# context-doctor

Reduce the agent context of the target repository, the one where this skill runs, to the smallest set of instructions that keeps necessary behavior. Keep an instruction only when its absence would cause a specific wrong action. Delete files, then sections, then lines; shorten sentences last. Adding no file is the default, even when a scanner asks for one. A line cap is a ceiling, never a target.

## Modes

- `checkup`: run Inventory and report the largest safe reductions. Edit nothing.
- `treat`: run Inventory, Reduce, and Verify.
- `scaffold`: run Inventory, then add instructions only for an observed hazard that no loaded file covers. Follow `Scaffold from intake` in `references/prescriptions.md`.
- No argument: run `treat` when the request asks to minimize, trim, or fix; otherwise run `checkup`.

## Workflow

### 1. Inventory

List the agent tools in use, their launch directories, and every Markdown file they load or request: context files, nested rules, agent definitions, skills, workflows, and linked docs.

Run the scanners once. `$SKILL` is this skill's directory and `$REPO` is the target repository root.

```sh
bash "$SKILL/scripts/intake.sh" "$REPO"
python3 "$SKILL/scripts/vitals.py" --json "$REPO"
```

Scanner findings are leads, not proof of completeness or necessity. Close the inventory and choose the baseline tasks with `references/triage.md`. When a finding depends on how a tool loads files, read only that tool's section of `references/tool-matrix.md`.

### 2. Reduce

Record the decisions each baseline task must still receive. Run the `Deletion sequence` in `references/triage.md`, largest token cost first. Use `examples/reductions.md` when necessity, scope, or an exception is ambiguous.

### 3. Verify

Rerun both scanner commands with `--strict` as the first argument; `intake.sh` rejects a flag after the path. Check each strict finding against the tools actually in use, and report what remains. Confirm that surviving commands and paths exist. Do not run the build to prove a prose reduction.

Finish only when every `Acceptance` item in `references/triage.md` holds. Its last item defines the report.

## Boundaries

- Edit owned agent-context sources only. Leave human documentation, generated or installed copies, and vendored content untouched. In a chezmoi repository, edit the `dot_*` sources and use its apply workflow.
- Keep unrelated working changes intact.
- Keep every explicit user constraint; its wording may change, its effect may not. Configuration can confirm a command but cannot revoke a user constraint. Ask the user when conflicting instructions have no evidence-backed winner.
- Write plain sentences on unwrapped lines. Avoid jargon, cryptic abbreviations, and hidden comments.
- Open `references/prescriptions.md` and the `assets/` templates only when a necessary instruction needs rewriting or a new home.
- Run `scripts/self-test.sh` after editing this skill, never while auditing a target repository.
