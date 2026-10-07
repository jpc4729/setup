# The chaos catalogue

Each entry: the symptom, the cause, the detection, the fix. Paper-specific entries are marked, and they are the dangerous ones: Paper's tool surface makes them either impossible to repair or invisible until handoff.

## File level

**The fork.** `Project v2`, `Project — handoff`, `Project copy`. Cause: someone needed a safe place to try something. Detection: `list_resources`, two names sharing a stem. Fix: none that is cheap — Paper tokens are file-level and a copy stops tracking the original, so the two files diverge from the moment they exist. **Paper-specific severity:** a permanent split, not a recoverable one. Prevent it with L1. The one sanctioned copy is a token redesign file: declared in the Index, disposable, never merged by hand (`prototypes.md`).

**The name that carries state.** `App-layout-v1-final-final`. Cause: file names used as version control. Detection: any version, date, or `final` in the file name. Fix: `rename_resource` after a yes (L10), and put the state where it can change — on the artboard.

**The god file.** One file for every project a team owns. Cause: nobody decided what a file is. Detection: page names that name unrelated products. Fix: one file per project; that is the split L1 does allow.

## Page level

**The status page.** `Ready for dev`, `In progress`. Cause: a convention carried over from another tool without checking. Detection: a page name that is a status. **Paper-specific:** `move_nodes` can carry a board to another page, but every status change then costs a move plus a re-grid on the new page, where a status in the artboard name costs one rename. The page fills faster than anyone drains it, and one surface's states end up split across pages. Fix: purpose pages, status in the artboard name.

**The open-page dump.** New work lands wherever the user happened to be looking. Cause: writing before reading. Detection: C4 — an artboard whose surface has nothing to do with its page. **Paper-specific:** repairable, not free. Once the user agrees, `move_nodes` to the right page's `rootNodeId`, IDs preserved; the world position is kept too, so re-grid on the new page. The move is a repair, not a workflow; L3 exists to prevent it.

**The unpinned write.** A page-scoped call made with no `pageId`, so the work lands on whatever page the user switched to between calls. Cause: treating the viewed page as the agent's; the user controls it, and it can change mid-session. Detection: C4, or a board missing from `get_basic_info({ fileId, pageId })` on the page you meant. **Paper-specific:** the agent cannot switch the user's page, and a call without `pageId` follows it. Fix: resolve the `pageId` with `get_basic_info` and pass it to every page-scoped call (L3); `move_nodes` repairs what already landed on the wrong page.

**The trash-can page.** `Archive` that is really `everything I did not want to think about`. Cause: archive with no dating and no rule. Detection: an archive page larger than the surface it archives. Fix: date every archived board; archive only what was superseded, and delete nothing a human made (L9).

**Page-per-variant.** A page for each state or screen of one flow, or for each width of one responsive layout. Cause: pages used where artboards belong. Detection: page names differing by one word. **Paper-specific:** no tool deletes or merges a page, so each one stays until a human removes it. Fix: one page for the flow, ordinal bands for states and widths; a page per platform only when the layouts differ (`page-taxonomy.md`).

**The one-page file.** Every flow, audit and proposal on one canvas. Cause: the file started small and nobody split it. Detection: one page holding several flows, or about forty artboards. **Paper-specific:** every `get_basic_info` returns every board, placement fills one ever-larger canvas, and no `pageId` can scope a search, a comment list or an export. Fix: one page per flow; with a yes, `move_nodes` each board to its page, then re-grid each page.

**No index.** The reader's first move is to click every page. Cause: the file grew. Detection: two or more pages and no index page. Fix: `00 · Index`, one artboard, page map plus links out.

## Canvas level

**Sprawl.** Artboards wherever the tool dropped them. Cause: `create_artboard` places the board itself and nobody corrected it. Detection: C7 — ordinals disagree with `worldY`/`worldX` order. Fix: re-grid per L8 with `update_styles({ top, left })`.

**Loose nodes at the page root.** A card floating outside every artboard. Cause: `write_html` targeted `rootNodeId`. Detection: C7. Fix: once the user agrees, `move_nodes` into its artboard.

**The orphan.** An artboard nothing references, from a flow that changed. Cause: explorations left in the production page. Detection: a board whose ordinal has no neighbours and whose state appears nowhere in the flow. Fix: report it; with an explicit ask, `move_nodes` to the archive page, dated (L9).

**Overlap.** Two boards touching, so a screenshot catches both. Cause: manual placement with no gutter. Detection: compare `worldX + width` against the next board's `worldX`. Fix: 80px minimum, everywhere.

## Node level

**`Frame 4823`.** The reason a developer has to guess which board is the checkout button. Cause: naming deferred to "later". Detection: C8. Fix: `layer-name` at write time (L4); `rename_nodes` only to repair.

**Wrapper chains.** Four nested frames to hold one text node. Cause: HTML written as if for a browser DOM. Detection: `get_tree_summary` — a chain of single-child frames. Fix: rewrite the group with flex, padding and gap.

**Duplicate-and-tweak.** The same row written twice, then edited in one place. Cause: no component tool, so reuse was done by hand. **Paper-specific:** the MCP exposes no component or instance link, so nothing detaches and nothing propagates — the two copies simply diverge. Detection: C11, plus `find_nodes` on the row's text. Fix: one canonical copy on the components page, `x-paper-clone` or `duplicate_nodes` for the rest (L5).

**The 72-board button.** Every variant, size and state of one component as its own artboard. Cause: Paper has no variants, so each state became a board. Detection: several boards on the components page named for one component. Fix: one sheet per component, variants as rows and states as columns, each cell a canonical copy (`components.md`).

**The stale clone.** A cell changed, and its clones on the screens still show the old version. Cause: clones do not track their source. Detection: a screen's clone differs from its sheet cell in `get_computed_styles`. Fix: the propagate procedure — replace each clone, restore its texts (`components.md`).

**The silent margin.** A board full of `margin` and `display: grid` pasted from production CSS. Cause: `write_html` stores forbidden CSS without an error. Detection: C6's `find_nodes` searches. Fix: translate before writing (`css-to-paper.md`).

**Names that describe style.** `Blue box`, `16px text`. Cause: naming from the property panel. Detection: C8. Fix: name the role; the style is the token's job.

**Names that copy their own text.** `"Add photo"` as the layer name of the button labelled Add photo. Cause: it felt free. Detection: layer name equals its text content. Fix: name the role — copy changes, roles do not.

## Token level

**The raw literal.** `#B83700` written inline where `--color-primary` holds the same value. Cause: HTML pasted from somewhere. Detection: C9 — `find_nodes` on the token's value returns literal hits alongside `var()` hits. Fix: `update_styles` with the token.

**The second accent.** Two tokens, two hexes, one job. Cause: a new design without reading the existing set. Detection: C10 — two tokens with equal or near-equal values. Fix: alias one to the other with `var(--…)`, then migrate usages.

**The unloaded font.** A `--font-*` token naming a family absent from `fontFamilies`. Cause: a token written from a brief instead of from the file. Detection: C10, confirmed with `get_font_family_info`. Fix: load the family or change the token.

**Palette-only tokens.** `--color-red-600` used directly in designs, with no semantic layer. Cause: tokens generated from a palette. Detection: designs referencing value-named tokens. Fix: add semantic tokens aliasing the palette, and migrate usages to them.

**The prototype token edit.** An existing token re-valued for a prototype. Cause: tokens look local and are file-wide. Detection: a code-owned token that differs from the code's theme (`code-to-design.md`, Verifying fidelity). **Paper-specific:** every code-owned page restyles at once, and the file shows a product that does not exist. Fix: `set_tokens` back to the code's value, and add a token named for the initiative instead (L6).

**The silent font fallback.** Text stored as `system-ui, sans-serif` although a family was named. Cause: Paper did not apply the family and raised no error. Detection: `get_computed_styles` on a text node; `fontFamilies` listing only `System Sans-Serif`. Fix: stop authoring, tell the user, and fix the font in the app before the next text write.

**The stale token read.** A design written against a token name or value that no longer holds. Cause: the `contentHash` in the result header changed — someone edited tokens outside the session — and nobody re-read the tokens. Detection: compare the header `contentHash` of each file-scoped result with the one from the last token read. **Paper-specific:** the header is the only signal; nothing else says the tokens changed. Fix: re-read with `get_tokens` before relying on any token name or value, then `update_styles` on whatever the old read produced.

## Process level

**Retro-hygiene.** "I will name and align it at the end." Every rule here is cheap at write time and expensive after, and the end is when handoff starts. Fix: L4, L8 and L10 are all the same rule in three places.

**The silent partial audit.** A report that covered eight pages of eleven and says nothing about it. Fix: name what was skipped and why, in the report header, always.

**The hand-merged prototype.** A prototype board moved onto a code-owned page, or a code-owned board edited to match a proposal, before the code ships. Cause: wanting the file to look current. Detection: C4 — a code-owned board with no manifest row, or one that differs from the running UI. Fix: a moved prototype board goes back to its prototype page; a code-owned board edited in place is re-authored from the code, after forking the edit into a `Proto` page if it is worth keeping. A code-owned page changes only through a re-mirror (`prototypes.md`).

**Cleaning by deleting.** Tidying a file by removing what looks unused. **Paper-specific:** there is no undo through the MCP, and a deleted node is gone. A move between pages is the reversible repair: with an explicit ask, `move_nodes` to the archive page. Fix: L9 — report human work, move it only when asked, delete only what this session made.
