# Review — audit a flow, then fix it underneath

A flow review judges how a flow or a screen works for the person using it. It shows the evidence, numbers each issue, explains each change, and puts every redesign directly under the screen it replaces. Nothing is overwritten, so the progress and the iteration stay on the canvas.

Terms here: the audit board is the evidence board of a flow review; the file-hygiene audit is `audit.md`. A redesign is a board that proposes a new version of a screen; it lives on a prototype page.

Review or Explore: a review starts from screens that exist and judges them. Explore (`iterate.md`) starts from a question with no screens to judge.

## Where it lives

- On the initiative's prototype page, `NN · Proto — <Initiative>` (`page-taxonomy.md`). In a mirrored file that page is design-owned (L2), so the review never touches a code-owned page. In a design-led file with no prototype page, the explorations page holds the review until the user says yes to one.
- A new page only after a yes (L10).

## The layout: one band per flow, one column per screen

```text
00 · Principles and decisions      beside the first band, read first

11 · Audit — Checkout              the screens as they ship, with numbered issues
12 · Notes — Checkout              what changes and why, one column per screen
C1   C2   C3   C4                  the redesigns, each under the column it replaces
          C3b                      a second state stacks under its first
13 · Notes — Checkout v2           the next version: what changed since v1
C1 v2     C3 v2                    version 2, under the same columns
```

- Columns. One per screen, in flow order. The audit board, the notes boards and every redesign row share the same column x positions, so each redesign lines up under its screen.
- Geometry. Column pitch = screen width + 80px, so neighbouring redesigns keep the 80px of L8. Board padding is 64px. Four 390px screens make a board 64 + 4 × 390 + 3 × 80 + 64 = 1928px wide. The redesign in column i, counted from 0, sits at the board's x + 64 + i × pitch.
- Rows. Each row starts 80px below the lowest board above it. A second state of a screen stacks under its first, in the same column.
- Versions. Iteration on the same screens adds a notes board for the new version and a redesign row below the band's lowest board. Earlier versions stay where they are.
- Flows. A second flow gets its own band, 80px to the right or below, with its own ordinals and its own letter.
- Placing boards. `create_artboard` and `duplicate_nodes` choose their own spot, so move each board to its column with `update_styles({ top, left })`. Heights of `fit-content` boards read null on a page the user is not viewing: place the boards while the user views the page, or keep fixed heights until they are placed (L8).
- Export. `export_combined_pdf` pages row by row across the whole page. Export one band at a time to keep each PDF in reading order.

## Evidence: where the screenshots come from

In order of preference:

1. The production boards in Paper. `export({ fileId, nodes: { <boardId>: [] }, pageId })` with default settings writes `<board name>@2x.png` to `~/Downloads` and returns its `filePath`. Embed it right away, before another export can overwrite it: `<img src="paper-asset://<filePath>">` with `width` and `height` set to the screen's size. Paper uploads it into the file, so the board keeps it after the local file is gone. Components come from the components page the same way.
2. The running product, when Paper has no production board yet. Capture the route in a browser at the boards' width, and embed the PNG the same way.
3. Never a live clone as evidence. `<x-paper-clone>` of a production board works, but the clone is editable, heavy, and moves under the markers after the next re-mirror. An audit records what was judged, so its evidence is a frozen image.

The redesigns start from the production boards too: `duplicate_nodes` into the prototype page (`prototypes.md`, Fork), then change them. Same tokens, same fonts, same viewport; what changes is the design.

## The audit board

- Header. A provenance line in small caps: source, viewport, theme, release and date (`Audit · Web 390 · light · from 10 · Web — Checkout @ v2.3.0 · 2026-09-24`). Then the verdict as the title (`Checkout: the worst issues`). Then one paragraph that names the pattern behind the issues, not a list of them.
- Column label. The route and the state id in mono (`/checkout/payment · 04-payment-failed`), then the screen's name. The route is what lets an engineer reproduce the state.
- Shot. A frame named `Shot`, with `position: relative`, `overflow: clip` and the screen's size. The image fills it. Numbered markers, named `Marker 1` onward — 26px circles, `position: absolute` — sit on the element each issue is about.
- Issues. A numbered list under the shot, one row per marker, named `Issue 1` onward. Each is one or two sentences: an observable fact and what it costs the user, measured where possible ("The total sits below the fold, under three rows of shipping options."). No fix goes in an issue. At most six per screen: the worst ones.

## The notes boards

- Header. `Redesign · v1 · for iteration · <date>`, then `<Flow>, redesigned`, then the one rule that holds across every redesign ("Each redesign sits under the screen it replaces. Same tokens, same fonts, same viewport.").
- Columns. One per screen, aligned over its column. The heading is the redesign's code and name (`C2 · Payment`). Below it, one line per decision, in the present tense, each starting with an em dash. A stacked second state is listed under its screen's heading.
- A version's notes board (`13 · Notes — Checkout v2`) says only what changed since the version above it, and why.

## The redesign boards

- Named with a code instead of an ordinal (`naming.md`): the flow's letter and the screen's number, the same code the notes use (`C1 · Cart — redesign`). A second state takes the next letter (`C3b`). A new version adds ` v2` (`C1 v2 · Cart — redesign`).
- Forked from production, at the same viewport, with tokens only (L6).

## The principles and decisions board

`00 · Principles and decisions`, beside the first band, marked "read me first".

- Rules behind every redesign. Numbered, one line each ("One primary action per screen.").
- Decisions, by round. Each is `settled`, `recommended` or `to settle`, and cites the spec, doc or code line it changes (`docs/checkout.md:91 says … C1 changes it`). This is where design meets the codebase. Only the user settles a decision; the agent writes `recommended`.
- Coverage. One line: which screens have an audit and a redesign, the letter of each flow, and what is still open.

## Review chrome is not product

- Markers, captions, rules and notes are annotation: they use the `--color-annotation-*` family (`naming.md`), kept for every later review. It is the one family a prototype page adds without `proto-` (L6).
- A literal colour in annotation is a C9 finding, as anywhere else. Audit C5 and C7 read review pages by band and code (`audit.md`).

## Rounds: progress stays visible

- A round adds; it never overwrites. A version row and its notes board go below the last one, and the round's decisions go on the principles board under a new heading.
- Superseded versions stay in place until the user settles the decision that replaced them. They move to the archive only after an explicit ask (L9).

## Closing a review

1. `get_screenshot` on each board of the band, judged against the guide's checkpoints.
2. `finish_working_on_nodes` with the boards you touched.
3. Ledger: the issue count per screen, the decisions recommended and settled, and the redesign codes.
4. Handoff goes through `prototypes.md`: the redesigns ship in the code, then the re-mirror promotes them.

## Checking an implementation the same way

After code lands, use the same shot pattern for the implementation. Add a band on the prototype page: the redesign board, a screenshot of the implementation at the same viewport and date-stamped, then numbered differences. A band with no differences is the proof that the prototype can close (`prototypes.md`, Close).
