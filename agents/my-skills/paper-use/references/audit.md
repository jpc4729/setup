# The audit

Read-only. It produces the table of contents the file should have had, and a numbered defect list where every entry names a check, a location and the exact call that fixes it. What cannot be decided from a tool result is a note, not a defect.

Twelve checks. The concern in each is tool-independent; only the detection and the fix below it are Paper's.

The audit never moves the user's view: every page-scoped read passes `pageId`, so the page they are looking at stays theirs. Tell the user one thing before starting: the audit makes no metered call, so the budget is wall-clock and the single open file rather than a quota.

## The walk

Pass `fileId` on every call that takes it.

1. `list_resources` — one file per project. Any second file whose name looks like the same project is C1, unless the Index declares it as a live token redesign file. The list is whole only when the result has no `truncated`: raise `limit` until then, and when `limit: 200` still truncates, say so in the report header.
2. `get_basic_info({ fileId })` — record `fileName`, `pages[]`, `fontFamilies`, `tokens.items`, and the `contentHash` from the result header.
3. Mirrored file — the Index declares owners, or the repo holds a manifest: read the Index's owner list and the manifest. No manifest at hand → the manifest clause of C4 is skipped, and the report header says so.
4. For each page: `get_basic_info({ fileId, pageId })` for that page's `artboards[]` and `rootNodeId`. On a page the user is not viewing, a position or size that depends on layout comes back null; record it as a note, not a C7 defect.
5. Per page: `get_tree_summary({ fileId, nodeId: rootNodeId, depth: 3 })` — loose root nodes, generic names (C8), wrapper chains, and names shared by two artboards or two siblings (C11). `?` marks an unmeasured size. Go deeper only into a subtree that already looks wrong.
6. Layout (C6): three file-wide `find_nodes` calls — `{ styleName: "margin*" }`, `{ styleName: "display", styleValue: "grid" }`, and `display` with `inline-flex`, then `inline`, as exact values.
7. Per token value of the C9 types — colour, spacing, radius, type: one file-wide `find_nodes({ fileId, filters: [{ styleValue: "<value>" }] })` for counts and existence. Results do not name the page, so when the report needs a location, repeat the call with that `pageId`. Hits reported as `var(--token)` are correct; hits reported as the literal are C9.
8. Token hygiene (C10): per token, one file-wide `find_nodes` on its name for the zero-hit test. Every `--font-*` value against `fontFamilies`; anything missing goes to `get_font_family_info` before it is called a defect. `get_tokens({ fileId, types })` narrows a large token set.
9. Clones (C12): per sheet cell, find its clones (`components.md`, Propagate, step 1) and compare their `get_computed_styles` with the cell's.
10. `list_comment_threads({ fileId, status: "open", sortField: "page" })` — open feedback, grouped by page. Add `list_comment_thread_authors({ fileId })` when the report needs to say who wrote what.
11. `get_screenshot` on one artboard per page, at most.
12. Write the report.

## Budget

Steps 1–6 are mandatory; they are the structure, and they are cheap. Steps 7–9 scale with the token set and the sheets, so scope them to the tokens and cells actually in use and **name what was skipped in the report header**. A silent partial audit reads as a clean bill of health, and that is the one outcome worse than not auditing.

## The checks

Severity: **blocker** breaks handoff, **defect** costs a reader time, **note** is advisory or needs a human hand.

- **C1 · file boundary** — blocker. One file per project. Tokens are file-level and a copy stops tracking the original, so a second file is a permanent fork with no library that could heal it. Fix: none that is cheap — `rename_resource` after a yes that names the file (L10), and merge the fork by hand. A token redesign file declared in the Index is a note, not a blocker (L1).
- **C2 · file identity** — defect. The file name is the project name, with no version, date, state or owner. Fix: `rename_resource` after a yes that names the file (L10), and put the state where it can change — on the artboard.
- **C3 · page names and convention** — defect. Every page name is a purpose noun phrase, and one prefix convention runs across every page. `Page N`, `Untitled`, a status, a person or a bare date fails; mixed conventions fail. With five pages or fewer, plain purpose names are fully compliant. Fix: `rename_pages` in one batch, after a yes that names the pages (L10). In a mirrored file, update the manifest's Page column in the same change.
- **C4 · one purpose and one owner per page** — defect. Every artboard on a page belongs to that page's flow or purpose, and a page holding several flows or about forty artboards is due a split (`page-taxonomy.md`). In a mirrored file, a board on a code-owned page with no manifest row, or a prototype board on one, fails too. An outlier is reported by name. Fix, once the user agrees: `move_nodes` to the right page's `rootNodeId` from `get_basic_info({ fileId, pageId })`; IDs are preserved (L3), and the world position too, so re-grid after (C7).
- **C5 · artboard names** — blocker. Every artboard matches `NN · <Surface> — <state>`, ordinals unique, gapless within their band (`naming.md`), and under 50 characters. On a page that holds a flow review, the band ordinals and redesign codes of `naming.md` pass. On the archive and explorations pages, the state ends with a date (`naming.md`). Fix: `rename_nodes`.
- **C6 · layout** — defect. Flex, padding and gap only — no `margin`, no `display: grid`, no `display: inline`, no HTML tables. The tool stores these without an error, so search for them: `find_nodes` with `{ styleName: "margin*" }`, with `{ styleName: "display", styleValue: "grid" }`, and with `inline-flex` and `inline` as exact values. A wildcard `inline*` also matches the `inline-block` Paper puts on every text node, which is not a defect. No wrapper chain of single-child frames. Repeated rows align by fixed-width slots (`width` plus `flexShrink: 0`), never by `gap` alone. Fix: rewrite the group.
- **C7 · canvas placement** — defect. Sort `artboards[]` by `worldY` then `worldX` and compare with the ordinals; `export_combined_pdf` pages in world-position order, so a mismatch reaches handoff as a shuffled PDF. Flag any pair closer than 80px, and any child of `rootNodeId` that is not an artboard. A null position or size on a page the user is not viewing means the page was not measured; that is a note, not a defect. On a page that holds a flow review, order is by band, then row, then column (`review.md`), not by ordinal. Fix: re-grid per L8 with `update_styles({ top, left })`; `move_nodes` for a loose node.
- **C8 · layer names** — defect. No `Frame …`, `Group …`, `Rectangle …`, bare `Vector`, digits-only, or style-description names. Report a count per page plus the ten worst, with the role each should carry. Fix: `rename_nodes` in one batch.
- **C9 · hardcoded values** — blocker. No fill, stroke, spacing, radius or type property carrying a literal where a token holds that value. Annotation uses `--color-annotation-*` (`naming.md`); a literal colour in it is a C9 finding too. `find_nodes` on the token's value returns literal hits alongside `var()` hits. Fix: `update_styles` with the token on a design-owned page; on a code-owned page, report it for the re-mirror (L2).
- **C10 · token hygiene** — defect. Paper has eleven token types, each with its Tailwind namespace, `--opacity-*` for opacity included. A `--font-*` value absent from `fontFamilies`, a token outside its namespace (`--font-size-*` where `--text-*` belongs), two tokens with the same value under different names, or any token with zero hits in a file-wide `find_nodes` — except `--color-annotation-*`, kept for the next review. An alias — a token whose value is `var(--…)` — and the palette token it points to share a value by design, and a palette token counts as used when an alias of it has hits: neither is a finding. In a mirrored file, a token whose `description` does not start with `code: <path>#<name>` is a defect, because design-to-code cannot map it (`css-to-paper.md`). `--color-annotation-*` and `-proto-` tokens have no code identity and are exempt. A token defined for work not yet built is a note; say which it is. A prototype's token — its name carries `-proto-` — whose prototype page is gone is a leftover; `get_tokens({ fileId, namePattern: "*-proto-*" })` lists them all. When the header `contentHash` differs from the one recorded in step 2, re-read with `get_tokens` before judging any token. Fix: `set_tokens` with `newName`, an alias, or `delete: true`, only after a yes that names the tokens: a delete cannot be undone. In a mirrored file, the agent fixes only `-proto-` leftovers; every other token fix goes to the re-mirror (L6).
- **C11 · reuse** — blocker. Nothing repeated is hand-written twice. Each repeated element has exactly one canonical copy — a cell of its component's sheet (`components.md`) — and every other occurrence is cloned from it and carries the cell's name. Two artboards sharing a name in one page fail, and so do two sibling layers sharing a name unless that name is a sheet cell's: clones of one cell share it by design. Fix: keep the canonical one, `x-paper-clone` or `duplicate_nodes` for the rest, `rename_nodes` for the collision.
- **C12 · leftovers and readiness** — note. Unresolved comment threads, with page, node name and the first line; any node this session left mid-work; and every clone that differs from its sheet cell, which the propagate procedure fixes (`components.md`). The audit only reads threads; resolving one happens in the Revise route (`iterate.md`), and a finding goes in the report.

Report by name, never by node id — an id means nothing to the reader (`SKILL.md`, Targeting).

## Report

```text
# <File name> — file audit

Pages: 7 · Artboards: 34 · Nodes: 2,913 · Tokens: 68 · Open comments: 3
Skipped: C9 on spacing tokens (48 lookups) — say so or do not claim coverage

## Contents

00 · Index            1 artboard    clean
01 · Foundations      4 artboards   C10 ×2
10 · Checkout        28 artboards   C5 ×2, C7, C8 ×14
90 · Archive          1 artboard    C3

## Defects

1. C5 blocker · 10 · Checkout · "08 · Payment — declined" and "08 · Address"
   Duplicate ordinal 08. Fix: rename_nodes, renumbering from 08 so the sequence stays gapless.
2. C8 defect · 10 · Checkout · 14 layers named "Frame …"
   Fix: rename_nodes, one batch, roles listed below.
3. C7 defect · 10 · Checkout · board 07 sits right of 08
   Combined-PDF pages would come out in that order. Fix: update_styles top/left on both.

## Verdict

Handoff-ready: no. Two blockers, both mechanical, about 20 minutes.
Six clones of the changed row cell are stale; the propagate procedure in components.md fixes them.
```

Verdict is one of: handoff-ready; handoff-ready after the listed blockers; not navigable — restructure first. Name the number of blockers and an estimate in minutes, then the closing line, and nothing else.

## Restructure — after a failed audit

For a verdict of "not navigable — restructure first", or "restructure this file". The audit runs first; its contents table is the starting map.

1. **Plan and ask.** Post the target page map (`page-taxonomy.md`): each new page, each renamed page, and which boards go to it. Wait for a yes; no tool deletes a page.
2. **Pages.** `create_page` per new page, and keep each `pageId`.
3. **Move, one page at a time.** `move_nodes` each board to its page's `rootNodeId`; IDs are kept, so comments and the manifest still point at them. A move keeps the world position, so re-grid that page before the next (L8).
4. **Names.** `rename_pages` in one batch for every page that fails C3. Boards and layers on design-owned pages only in a mirrored file; C5 and C8 findings on code-owned pages go to the re-mirror. `rename_nodes` in one batch per page: artboards to the page's ordinals (C5), then generic layers to their roles (C8).
5. **Tokens.** In a design-led file only; in a mirrored file, the tokens come from the code (`code-to-design.md`), and C9 findings on code-owned pages go to the re-mirror. A file with no tokens gets them from the values in use (`iterate.md`, Consolidate steps 1–3). Literals then swap to tokens (C9).
6. **Close.** Write the Index, then re-run the audit. Its verdict is the proof. A page emptied by the moves is named in the ledger; the user deletes it in the app.

Everything a human made is moved, never deleted (L9). A board that fits no flow goes to the archive, dated. In a mirrored file, moves and renames keep node ids but change the manifest's Page and Node name columns: update the manifest in the same change, and leave board content to the re-mirror.
