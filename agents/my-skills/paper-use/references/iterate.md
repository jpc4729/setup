# Iterate — the designer's loops

Four routes for work that is not a first build. Consolidate, here, turns a picked direction into tokens and clones; promote, in `prototypes.md`, moves a shipped board onto a code-owned page. Each keeps the laws that protect the file — L3 target page, L4 names, L8 grid, L9 deletion, L11 end clean — and says which ones it pauses.

A file is mirrored when the repo holds its manifest (`mirroring.md`). In a mirrored file, a code-owned page is generated output: these routes never edit it. They work on design-owned pages, and a change reaches a code-owned page only through the code (`prototypes.md`).

## Explore — several directions, then consolidate one

For "try three directions", "explore", or a redesign that is not decided yet.

1. Work on the explorations page, or on the initiative's prototype page when one exists (`page-taxonomy.md`). Neither exists yet → create one only after a yes (L10), because no tool deletes a page.
2. One brief per direction, posted before its first mutation. The guide requires directions that differ in point of view, not in one colour.
3. One row of artboards per direction, named `NN · <Surface> — <direction>`, 80px apart (L8). When a direction changes the look but not the content, start from `duplicate_nodes` of the existing board, not from blank HTML.
4. L5 and L6 pause here: literals and one-off elements are allowed while nothing is decided. L4, L8 and L9 do not pause.
5. Screenshot each direction and send them together, with a one-line verdict each. The user picks.

Consolidate the pick, in this order. In a mirrored file, the initiative and its slug come first: ask for its name if there is none (`naming.md`).

1. Inventory its values with `get_jsx({ fileId, nodeId, format: "inline-styles" })` on each winning board. A value that appears twice becomes a token (L6); a value an existing token already holds uses that token.
2. `create_tokens` for the new ones, in the order the tool requires. In a mirrored file they carry the initiative's slug (L6).
3. Per literal: `find_nodes({ fileId, nodeId, filters: [{ styleValue: "<literal>" }] })` scoped to the board, then `update_styles` to `var(--token)` on the raw hits. A hit already reported as `var(--…)` is done.
4. Every repeated element gets one canonical copy, a cell of its component's sheet, and the board re-clones it (L5, `components.md`). The sheet lives on the components page, or on the prototype page in a mirrored file, where the components page is code-owned.
5. Design-led file → `move_nodes` onto the flow page's `rootNodeId`, rename to that page's ordinals, re-grid (L8). Mirrored file → the pick stays on, or moves to, the initiative's prototype page, never a code-owned one. It ships through the code and is promoted when the prototype closes (`prototypes.md`).

The directions that lost stay where they were made, dated. They are the record of what was tried, and they move to the archive only after a yes (L9).

## Revise — from comment threads

For "address the comments", or feedback left on a page.

1. `list_comment_threads({ fileId, pageId, status: "open" })`. For one person's comments, resolve the name with `list_comment_thread_authors`, then filter with `threadAuthorUserId` or `participantUserId`; the signed-in user is `"current-user"`.
2. `get_comment_thread` per thread. The pinned node is the target. A thread that asks a question, or where two people disagree, is reported, not acted on.
3. One targeted fix per thread, then a screenshot of the pinned node's artboard, judged against the guide's checkpoints.
4. `set_comment_thread_status` to `resolved` only when the feedback is fully addressed.
5. No tool replies to a thread, so the ledger is the reply: one line per thread with the layer name, what changed, and resolved or left open with the reason.

In a mirrored file, a thread on a code-owned page is a finding for the code, not an edit. Fork the board into a prototype page — an existing one, or a new one only after a yes (L10) — and fix it there, or record it for Converge (`mirroring.md`).

## Tweak — the selection

For "make this tighter", "try three versions of this card", or any request that points at the canvas.

1. `get_selection` is the target. Nothing is selected and the request names nothing → ask.
2. A tweak edits in place with `update_styles` or `set_text_content`, then takes a screenshot. A node on a code-owned page is not edited in place: its variants go to a prototype or explorations page, through `duplicate_nodes` with that page's `rootNodeId`.
3. Variants: `duplicate_nodes` the selection's artboard, not the node, so each variant is judged in context and the source layout is untouched. Retarget the edit through the returned `descendantIdMap`; no lookup call is needed.
4. Name each copy `NN · <Surface> — variant A`, `B`, `C`, and put the row beside the original (L8). The original is never edited.
5. Screenshot the original and every variant, one line each. The user picks; the losers may be deleted after a yes, because this session made them (L9).

## Present — deliver

For "export", "share", a deck, a PNG.

1. Check the board order against the ordinals first (L8): `export_combined_pdf` orders its pages by canvas position, not by name.
2. A review deck → `export_combined_pdf({ fileId, nodeIds })` with the artboards in scope.
3. Single images → `export` with `[]` per node for the default settings. Override format or scale only when asked. Motion → `type: "video"`: mp4 is opaque, webm is transparent.
4. The designer already set export settings → `nodes: "nodes-with-exports-only"` with an explicit `pageId`, so their choices win.
5. Report what the tool returned. Say which boards were left out and why.
