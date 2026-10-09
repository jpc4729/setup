# Check

## Methods

A child's leaves hold on its parent's path to the outcome it refines, named by the `^ refines` line under each. Treat that path as the first conditions, and reach them before the child's own. Check each level at its own zoom: a parent's verdict stands on its own evidence, and a child's `FAIL` is reported beside the outcome it refines.

### trace: read the code

Treat a leaf's `given` lines as preconditions and its `when` lines as inputs. Assume every earlier sibling on the path fails, because the first match wins. Follow the code along that path to the outcome.

- `PASS`: cite the `file:line` where the outcome happens and the guard that routes there.
- `FAIL`: the code does something else. Cite it and say what it does.
- `GAP`: the code branches where no tree does.

`trace` works at every zoom and fits `code` zoom best. It proves the code says so, not that it runs.

### tests: run the suite

1. Map each leaf to tests by name first. Tests from the `tests` mode carry the leaf labels. Then map by reading test bodies.
2. Run only the mapped tests.
3. `PASS`: a mapped test asserts the leaf and passes. `FAIL`: it fails; quote the failure. `SKIP` with the reason `no test`: nothing asserts the leaf. That leaf is untested, not passing.

### run: drive the software

Start the software the way the index says. Reach each `given` through the software's own surfaces, or with a fixture the area card names. Make every earlier sibling on the path fail.

- Stamp every record the check creates: `R` and the local time as `MMDDHHmm`, for example `R09281430`. Put the stamp in names, references and reasons, so a run never collides with seeded data or another run.
- Drive browser surfaces with a browser automation tool when one is installed. Call APIs and CLIs directly and keep the transcript.
- A `given` you cannot reach is `BLOCKED`, with the reason.
- Before you stop, cancel or delete what you created and left open. Never touch seeded records. Never reset data unless the user asks.

## Kinds

- `smoke`: `trees paths --aligned --smoke`. Check the smoke leaf of each tree and its effects, on every place its root names.
- `full`: `trees paths --aligned`. Check every leaf.
- `explore`: walk the smoke path once, then leave the trees on purpose. Try boundary values, steps out of order, double submits, back and reload mid-step, a second session, the wrong role, offline, and a narrow and a wide viewport. At `contract` zoom, try malformed input, retries and concurrent calls. What contradicts a leaf is a `FAIL` on that leaf. What no leaf covers is a `GAP`.

## Verdict lines

```text
<file>:<line> PASS|FAIL|BLOCKED|SKIP <place> — <what you observed> [— <evidence>]
GAP <area> — given … when … it should …? — <what you saw>
OPEN <file>:<line> — <what the software does>
```

Every `FAIL` cites evidence: a `file:line`, a quoted test failure, a response body, a screenshot or a measured value. `// OPEN:` and `// OUT OF SCOPE:` lines are not leaves and get no verdict.

## Fan-out

When the tool can spawn subagents, give each area its own, at most four at once. Otherwise check areas in order. Brief each subagent with this text, filled in:

```text
Check <kind> by <method>, stamp <stamp>, area <home>/<area>/.
Read <home>/README.md, then the area card, then every unit in card order. For a child, read the tree it refines first.
Leaves to check:
<trees paths output for this area>
<How to reach the software: URLs, viewports, commands, sign-in, test command.>
Reach each given as the method says. Use only this area's fixtures. Edit no repo file.
Before you stop, cancel or delete what you created and left open, with the reason "<stamp> cleanup".
Return one verdict line per leaf, then one GAP line per gap, then one OPEN line per open question the software answered.
```

## Report

Report in chat unless the index names a reports folder.

1. One line per area with its `PASS`, `FAIL`, `BLOCKED` and `SKIP` counts.
2. Every `FAIL` with its leaf, place, observation and evidence.
3. Every `BLOCKED` with its reason.
4. Every `GAP` as a `[ ] ???` question for the user.
5. Every answered `OPEN` line with what the software does.

A `GAP` or an answered `OPEN` line becomes a branch only after the user confirms it through `align`.
