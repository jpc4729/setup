# Components — sheets, names, specs and propagation

Paper has no component, variant or instance (`mcp-facts.md`). This file is how a design system survives that: one sheet per component, cell names that carry the code's identity, specs the code can read, and a procedure that pushes a change out to every clone.

## One sheet per component

- The components page holds one artboard per component, `NN · <Component> — sheet`. It lays out every variant and state the code has as a matrix: one row per variant and size, one column per state.
- Each cell is a canonical copy (L5). Every other use of the component is cloned from its cell, never from a screen.
- Only what the code has. A button with four variants, three sizes and six states is one sheet of twelve rows and six columns, not 72 boards.
- Row and column labels and the spec strip are annotation, in `--color-annotation-*` (`naming.md`), not product.

## Cell names carry the code identity

- `<Component> · <value> · <value> · <state>`: the component's name exactly as the code writes it, then its prop values in the order its type or prop definition lists them — alphabetical when that order is unclear — then the state. Defaults are left out, `default` included. The state word always comes last and comes from the state columns below; a prop value never uses a state word. A boolean prop appears by its name. `Button · primary`, `Button · primary · lg · hover`, `IconButton · ghost · pressed`, `TextField · error`. Under 50 characters (L4).
- A clone keeps its cell's name. _Tested._ So a screen's layers read as component usage, and implementation maps `Button · primary · lg` straight to `<Button variant="primary" size="lg">` (`design-to-code.md`).
- `get_jsx` drops layer names; `get_tree_summary` keeps them. Read names there.

## Interaction states and specs

- State columns, in this order, where the code has them: `default`, `hover`, `pressed`, `focus-visible`, `disabled`, `loading`, `error`. Draw the focus ring: `outline` with `outline-offset` works. _Tested._
- A spec strip under the matrix, in annotation text, read from the code:
  - Motion — property, duration and easing, from the code's transitions or motion tokens: for example `background-color · 150ms · ease-out · motion.fast`, where the last part is the code's own token name. Paper has no duration token type, so the code's token name goes in the text.
  - Accessibility — role, where the accessible name comes from, keyboard behaviour, minimum target size: `button · label text · Enter and Space · 44×44`.
- A screen's own behaviour — focus order, a transition between two states — goes on a spec board in the review pattern (`review.md`): the board exported as a frozen image, numbered markers for the focus order, one line per marker.

## Propagate a change to its clones

Clones do not track their source (L5). After a cell changes, each clone is regenerated. Replacing deletes the old clone, so this runs on clones this session made, on code-owned pages under the re-mirror's ask, and on a human's clones only after a yes that names the boards — the one exception to L9. Otherwise, report the stale clones.

1. Find the clones. `find_nodes` does not search names, but it returns them. Search for a token the cell's own frame is bound to — not a child's — and the change did not touch, `filters: [{ styleValue: "--color-primary" }]`, and keep the results whose name is the cell's exact name. _Tested._ Scope the search to the pages the cell reaches: a components-page cell in a mirrored file → each code-owned page, one `pageId`-scoped call each, because design-owned pages are behind by design (`prototypes.md`, Stale prototypes); a forked cell → its prototype page only; a design-led file → the whole file. Drop the cell itself and every result on the components page. A cell with no token binding: `get_tree_summary({ fileId, nodeId, depth: 10 })` on every board in scope instead.
2. Record what the screen changed. Before replacing a clone: its parent (`get_node_info`, `parentId`) and its next sibling (`get_children` of the parent); its texts (`get_tree_summary` shows them); its placement from `get_computed_styles` — `alignSelf`, `flexGrow`, `width`, `position`, `top`, `left`; and any other style that differs from the cell's, which is an override. `list_comment_threads({ fileId, nodeId })` on the clone: a thread pinned to it goes when it goes, so name it in the ledger.
3. Replace. `write_html({ fileId, targetNodeId: <clone>, mode: "replace", html: '<x-paper-clone node-id="<cell>" style="<placement>" />' })`. The new clone lands in the old one's place. _Tested._
4. Check the parent. `get_node_info` on the new clone: its `parentId` must be the recorded parent. If it is not, `move_nodes` it with `{ nodeId, before: <recorded next sibling> }`, or `{ nodeId, parentId, index }` when it was the last child. Then delete a duplicate left in the slot only if this session made it, and report it otherwise.
5. Restore the texts with `set_text_content`, on the text ids `write_html` returned, _tested_, and the overrides with `update_styles`.
6. Verify. `get_screenshot` on each board touched, and update any node id the manifest tracks.

In a mirrored file, propagation is part of the re-mirror, because the components page is code-owned. On a prototype page, it follows a change to the forked component.
