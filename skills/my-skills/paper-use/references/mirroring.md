# The mirror — keeping the design and the codebase identical

A mirrored file is a derived artifact. For every component the code exports and every screen state the code can reach, there is exactly one design node, authored from the code, named for its source, and recorded in the manifest. A difference between the node and the running UI is a defect in one of them, never a matter of taste.

Most teams have a handoff ritual — design to code — and no sync ritual for shipped code back to the design. Every sprint that ships without updating both sides widens the gap, and drift only accumulates. The three phases below are that missing ritual, and step 3 of Converge is the part people skip.

## One rule above the rest

Never hand-edit a mirrored node. It is generated output; editing it is editing generated code. The edit survives until the next re-authoring, which silently reverts it, and in the meantime the file says something the product does not do. Changes go into the code and come back through a re-authoring.

There is no exception. A design change is made on a fork, on a prototype page, and it comes back through the code (`prototypes.md`).

## Direction of truth, declared

Only one side can be right at a time, and which one must be stated per node, never assumed. Code is the source; the design is the representation.

- Mirror and re-mirror — code wins. The re-authoring overwrites. Any design-only change in its path is lost, correctly.
- Review — nothing wins. The canvas holds findings, not fixes. A finding is a comment thread a human wrote on the node, a proposal on a prototype page or the explorations page, or a line in the ledger, never an edit to the mirrored node.
- Converge — design wins on the prototype page only, until the code lands. Then the re-mirror runs and code wins again.

Two sides both believing they are right is how drift becomes permanent, and it always starts as a small helpful edit.

## The manifest

Without a record there is no way to answer "what drifted". Keep one file in the repo, next to the code — `design/paper-manifest.md` unless the project keeps design docs elsewhere — and link it from the Index. One row per mirrored node, one row per prototype fork (`prototypes.md`):

```markdown
# Paper manifest — <Project>

File: <Paper file URL> · Release shown: <tag or commit>

## Mirrored nodes

| Source                   | State | Platform | Page                | Node name             | Node id | Canonical        | Commit |
| ------------------------ | ----- | -------- | ------------------- | --------------------- | ------- | ---------------- | ------ |
| src/screens/Checkout.tsx | empty | web      | 10 · Web — Checkout | 03 · Checkout — empty |         | Button · primary |        |

## Prototype forks

| Initiative | Slug | Page | Source board | Copy node | Source commit |
| ---------- | ---- | ---- | ------------ | --------- | ------------- |
```

`Source` lists every file that shapes the board, comma-separated: the screen, its layout, its strings. A component's row points at its sheet. `Canonical` lists every sheet cell the board clones, comma-separated. Node ids live here and nowhere a human reads: the ledger and the reports name layers.

- The commit column is what makes drift computable: everything whose source changed since its mirrored commit is a candidate for re-authoring, and nothing else is.
- A row with no node id is unmirrored work, not a clean file.
- A node with no row is either someone's hand-built work or a leftover. Both are findings.
- Treat the manifest like code: versioned, reviewed in the same change as the code it tracks, never updated later.

## Drift detection

Cheap and mechanical, and it runs on a cadence rather than on a hunch: once per release by default, per merged change when the team wants the file current every day. Pick one the team will keep.

A screen depends on more than its own file: its components, the theme, its layout, its strings. So drift fans out from the changed files, cheapest first.

1. Preflight and list the changes. The explorations and archive pages exist, or ask once, up front, to create them (L10). Then, per mirrored row, `git diff --name-only <row Commit>..HEAD -- <row Source>`; for tokens and sheets, one `git diff --name-only <oldest Commit in the manifest>..HEAD`.
2. Tokens. A changed file that a token's `code:` description names → diff `get_tokens({ fileId, format: "css" })`, a `:root {}` block (_tested_), against the code's values, and `set_tokens` the differences. Every board bound to those tokens updates at once; this step alone absorbs most theme changes. A variable that is new in the code gets `create_tokens`, with its `code:` description.
3. Components. A changed file in a component sheet's Source → re-author the changed cells, then push them to their clones (`components.md`).
4. Screens. A changed file in a row's Source → that row is a candidate.
5. What no file maps to. Data, feature flags, strings and global CSS change screens without touching their files. On the same cadence, capture each mirrored route at its board's width and at device scale factor 2 — the default export is @2x — `export` the board, and compare the two: `compare -metric AE board.png route.png diff.png` (ImageMagick), or side by side (`review.md`). With `-fuzz 5%`, `compare` ignores anti-aliasing and prints the differing pixels, then their fraction in parentheses (_tested_); a fraction above 0.005 makes the row a candidate. Tune both numbers once per project and write them in the manifest's header.
6. Re-author each candidate whose images differ (step 5's compare, which is cheaper, runs first) onto the explorations page, dated, never over the mirrored node. A new page per run would be permanent: no tool deletes one.
7. Compare the new node with the mirrored one — a screenshot of both, and a structural read when the difference is structural rather than visual.
8. Decide per node:
   - No difference → advance the commit column, and delete the re-authored copy in this same session, right after the compare; this session made it (L9). A copy left by an earlier session is reported, not deleted.
   - Intended difference → promote the copy onto the mirrored page with `move_nodes`. IDs are kept, so the manifest takes the copy's id; the world position is kept too, so re-grid (L8). Move the old node to the archive, dated; the user's ask for the re-mirror covers that move.
   - Unintended difference → record it as a finding.
9. Prototypes. A fork is behind when the mirrored row of its Source board has a Source file that changed since the fork's Source commit. List those prototype boards (`prototypes.md`).
10. Close. Update `Release shown` in the manifest, the release's one source, and copy it to the Index; then report what was skipped. Drift detection makes no metered call, so the limit is wall-clock and the single open file — say which pages you did not reach.

## The three phases

### 1 · Mirror

Export everything, in the order fidelity requires: tokens, then fonts, then the nodes, then names, then reuse, then pages and placement. Procedure: `code-to-design.md`. The phase ends when the manifest is complete and every row has passed a screenshot check — not when the authoring stops.

### 2 · Review

This is the payoff, and it is the part that cannot be done in an editor. The deliverable is a review band per flow on a prototype page: the production boards exported as evidence, numbered issues, notes, and redesigns under each screen (`review.md`). Look for what only shows up in aggregate:

- The same concept rendered four ways — four empty states, six button heights, three date formats.
- Spacing that is consistent inside a screen and inconsistent across the flow.
- A step whose purpose disappears once you see the step before it.
- States that exist in the code and are unreachable in the product, and states the product needs that the code has no node for.
- Contrast, tap-target size and focus visibility, judged against the real palette rather than a swatch.
- Copy read as a sequence rather than as a string table.

No tool creates a comment thread or posts a reply. Nothing in this phase edits a mirrored node, and nothing in this phase touches the code.

### 3 · Converge

Every accepted finding lands in both sides, in this order, one finding at a time:

1. Decide where the fix belongs — a token, a shared definition, or one screen. A fix applied at the screen that belonged in the shared definition will reappear on the next screen.
2. Change the code. Run the project's own checks on the files you changed.
3. Re-author the affected nodes, or promote the prototype board that matches the running UI (`prototypes.md`, Close). This step closes the finding; the merge does not. Re-clone every clone the manifest lists against the node you changed; nothing propagates on its own.
4. Verify the new node against the proposal, and against the running UI.
5. Update the manifest — node id and commit — and retire the proposal. Resolve the human-written thread with `set_comment_thread_status` once the finding is addressed.

A fix that lands in the design alone has not been made. A fix that lands in code alone has broken the mirror until step 3.

## What breaks a mirror, in order of how often

- A hand edit to a mirrored node, made in good faith, five minutes before a review.
- Authoring before the tokens exist, so every value is a literal and no token change ever reaches it.
- A state produced from data nobody can reproduce, so it can never be re-authored.
- An element written twice instead of cloned from one canonical copy, so the two diverge silently.
- A manifest that stopped being updated, after which every question about drift becomes an opinion.
- Authoring from the source file instead of the rendered UI, which produces a design of what someone meant to ship.
