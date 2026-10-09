---
name: paper-use
description: "Structures, builds, mirrors and audits Paper design files: pages with owners, tokens, prototypes on top of shipped code, and the designer loops."
disable-model-invocation: true
metadata:
  short-description: "Structure, mirror and audit Paper files"
---

# Paper Use

The scope here is structure: file identity, page purpose, canvas order, naming at five levels, token discipline, and the audit that proves the file is clean. Nothing here decides how a design looks.

## Scope, and what overrules this

- Visual direction, palette, mood, type scale, review checkpoints → the Paper MCP guide, `get_guide({ topic: "paper-mcp-instructions" })`. It wins on taste.
- Exporting a design to code → read the exact values with `get_jsx`, `get_computed_styles` and `get_fill_image`, never from a screenshot, and follow the conventions of the target codebase.
- An established convention in the file overrules the templates here: read the file first, and never restyle a file that has one.

## The core, whatever the project

Projects differ: one flow or fifty, one platform or three, a product that ships or none yet. Scale the file to the project (`references/page-taxonomy.md`), and keep these five everywhere.

1. One file per project, one purpose and one owner per page (L1, L2). A page per flow, not per screen and not one for everything.
2. What ships and what is proposed never share a page. Code-owned pages change only through a re-mirror from the code. A change is designed on a prototype page and reaches the code-owned page by shipping (`references/prototypes.md`).
3. Tokens before pixels, and tokens are shared by every page (L6). A prototype adds tokens; it never edits one.
4. Name, place and reuse at write time (L4, L5, L8). Nothing gets tidied later.
5. Verify every board by screenshot — against the running product when it mirrors one — and end clean (L11).

Read `references/mcp-facts.md` before the first tool call of a session.

## Using the Paper MCP

All work goes through the `paper` MCP server against the file open in the user's Paper app — no file on disk, no API, no browser. A mutation of the wrong node is undone only by another call.

The guide loaded in step 1 owns the design brief format, the `write_html` rules, the review checkpoints, typography units and image generation, and the tool descriptions repeat the hard limits. This section adds only what neither says.

### Session start — every session, in this order, no shortcuts

1. `get_guide({ topic: "paper-mcp-instructions" })` — once per session, before any other Paper tool. Again once the thread is long enough to drop it. Other topics on demand: `mobile-status-bar`, `image-generation`.
2. `get_basic_info({ fileId?, pageId? })` — pages, artboards, fonts and tokens of any page.
3. `get_selection` — what the user is pointing at; the selection is the brief when the request is vague.
4. `get_font_family_info` — before the first typographic style of the session, and before using any family not already in `fontFamilies`.

### Tools, by purpose

- Orient — `get_guide`, `list_resources`, `open_file`, `get_basic_info`, `get_selection`.
- Read structure — `get_tree_summary` first, then `get_children`, `get_node_info`; `get_tokens` for the token set; `get_jsx`, `get_computed_styles` and `get_fill_image` only when exact values are needed.
- Look — `get_screenshot`. Default scale 1; scale 2 only to read small text.
- Create — `create_file`, `create_page`, `create_artboard`, `write_html`, `create_tokens`.
- Change — `update_styles`, `set_text_content`, `rename_nodes`, `rename_pages`, `rename_resource`, `move_nodes`, `duplicate_nodes`, `set_tokens`, `delete_nodes`.
- Search — `find_nodes` by computed style, token or text; the only mechanical way to find a hardcoded value.
- Collaborate — `list_comment_threads`, `list_comment_thread_authors`, `get_comment_thread`, `set_comment_thread_status`.
- Deliver — `export` for image, video and PDF; `export_combined_pdf`.
- Close — `finish_working_on_nodes`. Mandatory in every session that wrote anything.

### On top of the guide

- The design brief goes out with the L10 structural plan, never instead of it.
- `get_screenshot` takes a `nodeId`: the artboard or the group, never "the page".
- `update_styles` returns the styles it dropped under `ignoredStyles`. Read that key after every call; a style listed there did not apply.

### Targeting

- Every mutation takes a node id from a read call, never a guessed one.
- Pass `fileId` on every call that takes it, and check the file header on every result as the guide says.
- Pass `pageId` explicitly to every page-scoped tool (L3).
- `open_file` on a file that is not open moves the user's view to it. Say so before calling it.
- Never put a node id in user-facing text or in a report; name the layer instead.

## The Laws

Eleven laws. The concern in each is tool-independent; only the mechanism below it is Paper's.

L1 — File boundary. One project, one file, named for the project. Paper tokens are file-level and never sync between files, so a second file forks the design system permanently — there is no library and no publishing that could heal it. Never `create_file` for a project that already has one. Split only when a separate product ships. One exception: a redesign of the token set itself gets a disposable clone, `<Project> — <Initiative>`, created only after a yes, declared in the main file's Index, and deleted by the user once the redesign ships (`references/prototypes.md`).

L2 — A page is one purpose and one owner. Paper gives one level of container above the artboard, so the page carries every separation the project needs. New content goes on the page whose purpose covers it, or on a new page created for a new purpose — never on whatever page happens to be open. Once a product is mirrored, each page is code-owned or design-owned, the Index says which, and an agent never hand-edits a code-owned page. Taxonomy: `references/page-taxonomy.md`.

L3 — The target page is a decision. Resolve the target `pageId` with `get_basic_info` before the first write, every session. Pass it explicitly to `create_artboard` and every other page-scoped call. Omitting it writes wherever the user happens to be looking, and that can change between calls. `move_nodes` can move a misplaced node to another page with its ids preserved, but that is a repair, not a workflow.

L4 — Nothing is nameless at write time. `create_artboard` takes `name`; `write_html` takes `layer-name` on every element a human would point at. A node named `Frame 12` tells a reader and a code generator nothing. `rename_nodes` is a repair tool, not a workflow step, and it truncates at 50 characters: treat 50 as the cap everywhere, and write labels, not sentences.

L5 — Reuse has one definition. Paper's MCP exposes no component or instance link, so every reuse is a copy (`<x-paper-clone node-id="…" />` or `duplicate_nodes`). Each repeated element has exactly one canonical copy — a cell of its component's sheet on the components page — and every other occurrence is cloned from it. Clones do not track their source, so a change to a cell is pushed to every clone by replacing it (`references/components.md`).

L6 — Tokens or nothing. Any value that appears twice is a token. Tokens are the only live propagation Paper offers: change one and every user updates. A raw literal where a token exists for that value is a defect; `find_nodes` finds it and the audit reports it. Namespace by Paper's eleven token types, semantic before palette. Tokens are file-wide, so an edit made for a prototype restyles every code-owned page: a prototype adds tokens carrying `proto-` and its initiative's slug (`--color-proto-checkout-accent`) and never edits an existing one. The one family added without `proto-` is `--color-annotation-*`: markers, captions, labels and spec notes, which are not product (`references/naming.md`).

L7 — Layout carries the intent. Flex, padding and gap, inside the limits `write_html` states; a layout that fights them will not survive its own content. The tool stores forbidden CSS without an error, so production CSS is translated before it is written, and every container says whether it fills, hugs or is fixed (`references/css-to-paper.md`). Repeated rows align by fixed-width slots, never by `gap` alone. Content that clips means `height: "fit-content"`, never a guessed pixel height.

L8 — Canvas placement carries meaning, so check it. `create_artboard` and `duplicate_nodes` place a board in the best empty spot they find, not where you choose. `export_combined_pdf` orders its pages by world position, top to bottom then left to right, so canvas position is part of the deliverable. When the order breaks, restore the grid with `update_styles({ top, left })`: x pitch = artboard width + 80, next row = tallest board of the previous row + 80. Never leave two boards closer than 80px. A re-grid needs measured sizes, and a `fit-content` board's height reads null on a page the user is not viewing: grid before boards switch to `fit-content`, or ask the user to open the page. On a page that holds a flow review, the band geometry of `references/review.md` replaces this grid.

L9 — Delete only what you made. Anything a human made is reported, never deleted. With an explicit ask, `move_nodes` to the archive page is the reversible alternative to deletion; there is no version history behind you. `delete_nodes` only on nodes this session created, never to restart your own work: a section that came out wrong gets targeted fixes. A node that looks misparented gets a `get_node_info` read of its parent before any delete; the tool asks for it. One exception: a stale clone may be regenerated from its sheet cell, with its texts and overrides restored — a code-owned clone under the re-mirror's ask, a human's clone only after a yes that names the boards (`references/components.md`).

L10 — Confirm the structure and the budget, then build. With the design brief, post the structural plan: file, page, artboard names with their ordinals, and which tokens are new — plus what the session will spend. Paper meters only image generation, which runs only when the user asks for it, so the budget is wall-clock and the single open file: one page at a time, and name what you did not reach. Six lines at most. Wait for a yes when a page will be created, because no tool can delete one, or when an existing name will change.

L11 — End clean. `finish_working_on_nodes` with the ids of the artboards you touched, then one ledger line per page touched: what was added, where, and what is still open. Before the ledger, leave no `Frame`-class name, no duplicate ordinal, and no raw literal that a token already covers.

## Route the work

- Writing anything new into Paper, or continuing a flow → Build, below.
- "Review / audit this flow or screen", "what is wrong with this screen", or a redesign pass over screens that exist → Review, `references/review.md`. Evidence first, numbered issues, notes, and each redesign under the screen it replaces.
- "Organize / clean / inventory / audit this file", or the file is unfamiliar → Audit, `references/audit.md`. A verdict of "not navigable", or "restructure this file" → Restructure, same file, after a yes.
- "Export the app / these components / this screen", mirroring a codebase, or moving a whole product into Paper → `references/code-to-design.md`, Kickoff. Reading a rendered screen and translating its CSS → `references/css-to-paper.md`.
- A component's sheet, its variants and states, its specs, or a change to push to its clones → `references/components.md`.
- A change on top of a product Paper already mirrors — a new feature, a redesign, an initiative → `references/prototypes.md`. Its design work follows Review when there are screens to judge, Explore when there are none.
- "Implement this design node", or reading a design back into code → `references/design-to-code.md`.
- Several directions, or "explore", for something with no screens to judge yet → Explore, `references/iterate.md`.
- "Address the comments", or feedback left on a page → Revise, `references/iterate.md`.
- The request points at the selection, or asks for variants of it → Tweak, `references/iterate.md`.
- "Export", "share", a deck, a PNG → Present, `references/iterate.md`.
- Keeping the two identical over time — what changed since the last release, a re-mirror, drift, the sync ritual, the review loop → `references/mirroring.md`.
- A single rename, one artboard, one token → do it, then run the checks its level could break: C3 for a page, C5 for an artboard, C8 and C11 for a layer, C10 for a token. In a mirrored file, only on a design-owned page, and never by editing an existing token.

## Build

Nine steps.

1. Preflight. `get_guide({ topic: "paper-mcp-instructions" })`. Paper Desktop must be running with a file open; a failed connection means telling the user to open it, not retrying. Only image generation is metered, and it runs only when the user asks for it, so the budget is wall-clock and the single open file.
2. Orient. `list_resources` → does a file for this project already exist (L1)? `get_basic_info` → pages, active page, artboards, fonts, tokens. Never write before reading.
3. Place the work. Pick the page by purpose and owner. A code-owned page is never the target of a design change: that work goes to a prototype page. An existing page → keep its `pageId`, and confirm with `get_basic_info({ pageId })` that its name is the one you chose (L3). A new page goes into the plan of step 4 and is created only after the yes.
4. Post the design brief and the structural plan before any mutation (L10). Wait only when a page will be created or a name changed. After the yes, `create_page({ fileId, name })`, keep the `pageId` it returns, and pass it to `create_artboard` and every other page-scoped call.
5. Foundations before pixels.
   - The file has tokens → use them by name, and add none that duplicates a value.
   - The file has none and the work is more than one artboard → `create_tokens` first: the minimal set that covers every namespace, opacity included, in the order the tool requires. Add a `description` where a token's role is not obvious from its name.
   - A tint is `color-mix(var(--color-primary) 40%, transparent)`, never a new colour token. A percentage used twice is an `--opacity-*` token: `color-mix(var(--color-primary) var(--opacity-muted), transparent)`.
   - Every `--font-*` value must be in `fontFamilies`. After the first text write, `get_computed_styles` on it must show the family first (`"Geist", system-ui, sans-serif`): Paper stores a family it did not apply as a bare `system-ui, sans-serif`, silently.
6. Definitions before screens. Every repeated element gets its one canonical copy first: a cell of its component's sheet (L5) — on the components page, or on the prototype page in a mirrored file, where the components page is code-owned (L2). Everything later is a clone of it, never a second writing of the same HTML.
7. Screens from definitions. `create_artboard` with its final name and ordinal; mobile boards get the status bar from the guide. `write_html` one visual group per call, `layer-name` on every element. Check where the board landed and restore the grid only if the order broke (L8).
8. Validate each step. `get_screenshot` on the artboard at the end of each section, `get_tree_summary` for what the eye cannot check, critique against the guide's six checkpoints, and fix before the next section. End each section with a one-line verdict.
9. End clean. `finish_working_on_nodes` with the ids of the artboards you touched, then the ledger (L11). Name every clone of a cell you changed that has not been pushed yet (`references/components.md`, Propagate).

## Audit

- Read-only; ends with a table of contents plus a numbered defect list.
- It never moves the user's view. Walk each page with `get_basic_info({ pageId })`.
- Full procedure, the twelve checks and the report template: `references/audit.md`.

## Naming, in one screen

- File — `<Project>`. Nothing else.
- Page — `[NN · ]<Purpose>`. A noun phrase for a purpose or a flow. Not a status, not a person, not a date. A platform word only when platforms diverge: `10 · Web — Checkout`. A prototype: `50 · Proto — <Initiative>`.
- Artboard — `NN · <Surface> — <state>`. Zero-padded ordinal, unique within the page, under 50 characters.
- Layer — the role in domain words: `Header`, `Total row`, `Empty state`. Never `Frame 12`, never the style (`Blue box`), never a copy of its own text.
- Token — the Tailwind v4 namespace for its Paper type, semantic before palette: `--color-surface`, `--color-on-surface`, `--text-title-md`, `--spacing-lg`. A `fontSize` token is `--text-*`, never `--font-size-*`. A prototype's token carries `proto-` and its initiative's slug after the namespace: `--color-proto-checkout-accent`. A second theme's token carries the theme: `--color-dark-surface`.

Grammar, separators, ordinals and worked examples: `references/naming.md`.

## Files

- `references/mcp-facts.md` — what the tool descriptions leave out: what no tool does, live-tested behaviour, guide-versus-tool conflicts. Read first.
- `references/page-taxonomy.md` — the page set scaled to the project, one page per flow, owners, platforms, and when a page is justified.
- `references/naming.md` — the naming grammar at every level, with examples.
- `references/audit.md` — the twelve checks, their calls, the report template, and the restructure that follows a failed audit.
- `references/anti-patterns.md` — the chaos catalogue: symptom, cause, detection, fix.
- `references/code-to-design.md` — the export direction: how a design is produced from the code.
- `references/css-to-paper.md` — reading a rendered UI (web snippet, native inspectors), translating CSS to what Paper accepts, fill/hug/fixed, the token map.
- `references/components.md` — component sheets, cell names that carry the code identity, interaction and spec strips, propagating a change to clones.
- `references/design-to-code.md` — the implement direction: reading a design back into a codebase.
- `references/mirroring.md` — the mirror invariant, the manifest, drift detection, and the three-phase loop.
- `references/review.md` — the flow review: audit board with screenshots and numbered issues, notes, redesigns stacked under each screen, the decisions board, rounds.
- `references/iterate.md` — the designer's loops: explore and consolidate, revise from comments, tweak the selection, present.
- `references/prototypes.md` — code-owned and design-owned pages, the prototype lifecycle, the token trap, the redesign file.
