# Code to design — the export direction

The goal of this direction is a Paper file that is a **derived artifact of the codebase**, accurate enough that a difference between the artboard and the running UI is a bug in one of them. Nothing here is a drawing exercise.

## Paper authors; it does not capture

Paper has no tool that captures a running UI into design layers. Every node is authored through `write_html` from the code's tokens, styles and components as context — a second implementation of the UI, not a recording of it.

Two consequences set the shape of everything below.

1. **Fidelity is a discipline, not a guarantee.** The screenshot check after every artboard is mandatory. In a capture-based tool it confirms the capture; here it is the only thing between the file and a plausible fiction.
2. **Drift is faster.** A captured frame is wrong only when the code changes. An authored artboard is wrong the moment anyone mis-reads a value.

What Paper gives back for that cost: no quota on any call this direction makes, and a DOM-like canvas whose `get_jsx` output is already close to a web codebase's own idiom.

## Order decides fidelity

1. **Tokens first, before the first artboard.** Read the project's stylesheets, token files and theme modules, then `create_tokens` — semantic colours first, then every other type smallest value first. In a mirrored file, each token's `description` starts with its code identity, `code: <path>#<name>`: it is the map between Paper's names and the code's (`css-to-paper.md`). A design authored before the tokens exist is a design full of literals, and at scale no hand pass repairs it.
2. **Fonts second.** Every `--font-*` value must appear in `get_basic_info.fontFamilies`, or the text renders as something other than what the code ships. `get_font_family_info` confirms the family exists; it does not confirm Paper applied it. After the first text write, read `get_computed_styles` on that node: an applied family comes first (`"Geist", system-ui, sans-serif`); a family Paper did not apply comes back as a bare `system-ui, sans-serif`, with no error. A fallback stops the batch until the user fixes the font.
3. **Then author** from the rendered UI, translated to what Paper accepts (`css-to-paper.md`); then name, then clone from the canonical copy, then place on the grid, then screenshot-verify.

## Choosing the source of truth for each node

- **Native apps → the theme code for values and the platform inspector for frames** (`css-to-paper.md`, Native).
- **Components → the component's stories, rendered, onto one sheet per component** (`components.md`). One story is one component in one known state: deterministic, no auth, no network, no fixture drift. Read the geometry from the rendered story in a browser, never from the source file alone — the source says what the author intended, the browser says what ships. No stories → a dev route that renders the component alone, or the screen that shows it; the manifest's Source column says which.
- **Screens → the running app on seeded data.** Real or seeded data, never lorem, never a name from another product. One artboard per state the code can actually reach: loading, empty, error, populated, offline.
- **Never author a state you cannot reach twice.** A state you cannot reproduce cannot be re-authored when the code changes, and at that moment the mirror is permanently broken for that node.

## What authoring must add

- **Names.** Every artboard and every layer, at write time (L4). The name is the only index the file has and the only link back to the source path.
- **Reuse.** One canonical copy of every repeated element on the components page, everything else cloned from it with `<x-paper-clone node-id="…" />` or `duplicate_nodes` (L5). Clones do not track their source, so record which canonical node each came from — that record is what makes the next code change survivable.
- **Assets.** Bring the repo's images in with absolute `paper-asset:///Users/...` paths in `<img>`, never a placeholder. Write a code sample as `<pre>`.
- **Structure.** Pages, ordinals, the index page, the grid. Nothing places itself correctly.
- **States as separate artboards.** Paper has no variant set, so each state is its own board with its state in the name.
- **Themes.** Mirror the default theme first. A second theme gets its own semantic tokens and its own ordinal band on the flow's page (`naming.md`), and only for the boards where it changes something.

## Kickoff — the whole product, in waves

A real product is hundreds of boards and never one session. The manifest (`mirroring.md`) is the plan, the work queue and the progress bar.

1. **Inventory from the code, before any Paper call.** Components from their exports or stories. Screens from the router or navigation config, one row per state each screen can actually reach, per platform. Each row: source path, state, platform, target page, artboard name, the canonical copies its clones descend from, an empty node-id column, and the commit it is mirrored from.
2. **Shape the file.** Derive the pages from the inventory (`page-taxonomy.md`): one per flow, and one per platform only where the layouts differ. Post the page list with the structural plan (L10); every new page needs a yes.
3. **Wave 1, one agent: foundations and components.** Tokens, then fonts, then the canonical components. Everything after depends on this wave, so it runs alone and first.
4. **Wave 2, one agent per flow page.** In parallel where the harness can run agents, one page after another where it cannot. Each agent owns one `pageId` and that page's rows. It never creates a token or edits a component: a missing one is reported, not improvised. Clones reach the components page from any page, and screenshots work on pages the user is not viewing, so each agent verifies its own boards.
5. **Close each batch.** A batch is done when every row has a node id and a screenshot check, not when the authoring stops. Record the release in the manifest's `Release shown`, and copy it to the Index.

Within a page:

- Author the richest state of a screen once. Derive loading, empty and error with `duplicate_nodes`, then `set_text_content` and `update_styles` through the returned `descendantIdMap`. That is cheaper than a fresh `write_html` per state, and the states cannot drift apart.
- Batch size. The guide's one-visual-group rule serves a user watching the canvas. A wave 2 agent writes on a page nobody is viewing: one section per `write_html` call — a header, a list, a dock — up to about 60 lines of HTML. On a page the user is viewing, the guide's rule holds.
- A new page, after the yes of step 2 → `create_page`, keep the returned `pageId`, pass it to `create_artboard`, and confirm with `get_basic_info({ pageId })` before the first write of every batch (L3).

These pages are code-owned from here on. A change on top of them is a prototype (`prototypes.md`).

## Verifying fidelity

- `get_screenshot` on the artboard, and a screenshot of the same story or route at the same viewport — a browser for the web, a simulator for a native app. Compare them directly, or with an image diff: capture at device scale factor 2 — the default export is @2x — `export` the board, then `compare -metric AE board.png route.png diff.png` (ImageMagick).
- Diff `get_tokens({ fileId, format: "css" | "tailwind" })` against the project's theme. A token that differs is drift in one of them.
- Look for the failures authoring actually produces: a value read from the wrong breakpoint, a font that was never loaded, a state assembled from a source file rather than a render, a row aligned by `gap` instead of fixed slots.
- A difference is not licence to make the artboard prettier. An artboard that disagrees with the code is either an authoring defect — re-author — or a code defect, and deciding which is the review phase, not this one.
