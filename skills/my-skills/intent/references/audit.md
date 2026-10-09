# Audit

An audit finds every place the home disagrees with itself, with the authority, or with the repo it describes. `check` asks whether the software does what the trees say. The audit asks whether the trees can be trusted to say it. Audit first: a `check` over an inconsistent home verifies noise.

## Layers

Run the layers in order. A finding in one layer often explains findings in the next.

### 1. Structure

Run `scripts/trees audit <home>`. On a root index that splits homes, it audits each listed home in turn. It lints every unit, reports these codes, and ends with one summary line per area.

- `A200`: the home has no readable index.
- `A201`: the index lists an area or a home that has no folder.
- `A202`: a folder holds units the index does not list.
- `A203`: a unit on disk is missing from its card.
- `A204`: a card lists a unit that has no file.
- `A205`: a card marks a unit `(no tree)`, but the file exists.
- `A206`: a root does not start with its area, outside `code` zoom.
- `A207`: two trees share the same root.
- `A208`: a unit sits outside any area.
- `A213`: a `// REFINES:` line names a root no tree has, or an outcome its tree lacks.
- `A214`: a `// REFINES:` line matches more than one outcome. Add a label from the outcome's path.
- `A215`: a child zooms out: a `product` tree refines a `contract` or `code` outcome, or a `contract` tree a `code` one.
- `A210`, `A211`, `A212`: a unit, an area or the home holds more leaves than its budget. These are warnings; `--strict` fails on them. `references/zoom.md` says how to cut back.

### 2. Language

- Two names for one concept, or one name for two concepts, across trees. Check the glossary when the authority has one.
- Zoom leaks: code names in a `product` tree, interface copy in a `code` tree.
- The wording rules in `references/notation.md`: a vague verb, two outcomes in one leaf, an outcome no reader can observe.

### 3. Logic

- Contradictions: the same conditions lead to different outcomes, within a unit, across units or across areas.
- Places: a narrower tree contradicts the shared tree it refines.
- Order: a refusal after the happy path, or a smoke path that ends in a refusal.
- Unreachable: an earlier sibling always matches first, so a later one never runs.
- Coverage: at `full` or `exhaustive` depth, siblings leave a case out, or one place refuses what another place accepts.
- Duplicates: two units state the same behaviour, or one decision appears at two zooms. They will drift apart. A child that refines an outcome is no duplicate, unless it repeats the parent's conditions or outcome.
- Refinement: a child contradicts the outcome it refines, promises less or more than it, or refines an outcome that fails the test in `references/zoom.md`.

### 4. Authority

- A branch states a rule the authority lacks, or contradicts one it has.
- An authority rule has no branch.
- The authority now answers an `// OPEN:` line, or now covers an `// OUT OF SCOPE:` line.
- A card's Sources section points at an authority section that no longer exists.

### 5. Repo

- A place, entry point, source path, symbol or fixture no longer exists in the repo.
- A route, endpoint, command or screen exists in the repo and no area covers it.
- A test named after a leaf that no longer exists, or a leaf whose generated test is gone.

## Fan-out

For a large home, give each area its own subagent for layers 2 to 5, at most four at once. Each returns its findings and its `trees paths` output. Then run the cross-area part of layers 2 and 3 yourself over all the leaf sentences: contradictions, naming drift and children in another area than their parent hide between subagents.

## Findings

Every finding names both sides that disagree:

```text
<file>:<line> <layer> — <this says …>, but <that says …> — <proposed fix, or question>
```

## Report and fixes

1. Give the counts per layer, then the script's summary lines.
2. List the findings by layer, structure first.
3. Structure and language findings change no meaning. Offer to fix them in one pass, apply them once the user agrees, then run the audit again.
4. Logic, authority and repo findings change meaning. Each becomes a `[ ] ???` question for `align`. A new rule lands in the authority first.
5. End by offering `check` on the areas the audit found clean.
