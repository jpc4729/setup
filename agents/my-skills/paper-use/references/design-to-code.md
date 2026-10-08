# Design to code — the implement direction

Read the design out of Paper, then write the target project's code. Never paste what Paper returns.

## The call order

1. `list_comment_threads({ fileId, nodeId })` for open feedback on the node before implementing it.
2. `get_tree_summary` on the artboard to see its shape before spending anything larger.
3. `get_jsx` on the node you actually need, with the `format` the project uses: `tailwind` for a Tailwind project, `inline-styles` for anything else. Its output has no node ids and no layer names; take those from the `get_tree_summary` of step 2, matched by order and text. Paper's canvas is DOM-like, so the output is closer to a web codebase's own idiom than a translation layer would be — but it is still a reference, not the file you ship.
4. `get_computed_styles` for exact values, batched over the node ids you care about. This is the only correct source for a colour, a size or a radius.
5. `get_fill_image` for any image fill you must reproduce.
6. `get_screenshot` to check your result against the design — never as the input to it. Capture the implementation at the board's viewport and put both side by side on the initiative's prototype page — or the explorations page when there is none, never a new page for one check — with numbered differences (`review.md`, Checking an implementation).

Never read a value off a screenshot. A screenshot verifies; it does not measure.

## The output is a reference

What comes back describes the design, not your codebase. Adapt it to the project's framework, styling system, component library and conventions, and match the code around it.

Before writing anything new, look for what the project already has: a component with that shape, a layout primitive with that behaviour, a token with that value. Reuse beats generation every time, and it is the only way the result still matches the design system a month later.

## Hint priority

Earlier sources override later ones.

1. A token reference. `find_nodes` on a value reports token-bound usages as `var(--token)`. In a mirrored file, `get_tokens({ fileId, format: "json" })` returns each token's description, and its `code: <path>#<name>` line names the project's own token; use that name. Without the line, match by value.
2. The layer name. Names in this file are roles in domain words (L4), so `Total row` names the component you should be reaching for, not a div to invent. A clone carries its sheet cell's name, so `Button · primary · lg` is `<Button variant="primary" size="lg">` (`components.md`).
3. The canonical copy on the components page — or, on a `Proto` page, that initiative's forked copy. If the node is a clone, the canonical one is the definition — read that, and implement it once.
4. Computed styles. Exact values, for everything the three above did not settle.
5. Raw literals. A literal where the file has a token for that value is a defect in the design (audit C9), not a licence to hardcode. Fix it on a design-owned page; on a code-owned page, record it for the re-mirror.

## Sizing intent

The board says whether each container fills, hugs or is fixed (`css-to-paper.md`). Map fill to the project's stretch or flex-grow primitive, hug to its default sizing, and a fixed px only where the board fixed it. Carry `min-width` and `max-width` over as they are. A layout that came back all fixed px was authored without intent: report it, do not ship it.

## Assets

- `get_fill_image` returns a resized JPEG for AI. Ship the original from the URL in its metadata, never the resized JPEG, and never author a substitute.
- Icons in this file are SVG, never emoji. Take the SVG with `get_jsx`, do not redraw it; `get_fill_image` returns only a message for an SVG.
- A generated image may still be rendering. Poll `get_node_info` until `imageGeneration.status` is `ready` before reading it; `error` means there is no image.
- Anything generated with `paper-gen://` is a placeholder by definition. It never ships to a codebase.
- Size explicitly: both dimensions on the container, the leaf image filling it. Never `auto`.

## The link back

Paper stores no link between a design node and the code component it stands for. The link is carried by two things and no others:

- Names. The layer and artboard names are the only in-file evidence of what a node is. This is why L4 is not a tidiness rule.
- The manifest. Source path to node id, kept in the repo. Without it, the second person to open the file cannot tell which component produced which board.

Treat both as load-bearing. In Paper they are the whole mapping layer.

## When this direction is allowed to lead

In a mirrored file the artboards are derived output and the code is the source. Reading one back into code is a round trip that should change nothing — and if it does, something drifted.

A design change leads only from a `Proto` page. Implement from the prototype board, never from a code-owned one. The change closes when the re-mirror promotes that board, not when the implementation lands (`prototypes.md`, Close).
