# What the Paper MCP can and cannot do

The tool descriptions are the reference for parameters, defaults and formats, and this file does not repeat them. It holds what they leave out: what no tool does, what was seen live, and where the guide and the tools disagree. Checked against the tool descriptions and the guide on 2026-10-07; lines marked _exercised_ were run live in a scratch file on 2026-09-24. Every tool mechanism the laws in `SKILL.md` rely on traces to a line here or to a tool description; the owner and prototype rules are policy, not tool facts. A tool result that contradicts a line below wins; say so in the ledger.

## What no tool does

- Reorder or delete a page. Page order is the user's; a numeric prefix is the only order an agent controls.
- Change the page the user is viewing. `open_file` applies its `pageId` only when the file was not open yet.
- `open_file` on a file that is not open yet opens it and makes it the active file: the user's view moves there. _Exercised._
- Delete a file.
- Create a component, an instance or a detach. Reuse is a copy, and a copy does not track its source. Tokens are the only live propagation a file has.
- Write a comment thread or a reply. An agent reads threads and resolves them.
- Share tokens between files. Tokens are file-level, and a cloned file's tokens stop tracking the original.

## Pages and measurement

- A page the user is not viewing is not measured: a size or position that layout decides reads as null in `get_basic_info`, `get_children` and `get_node_info`, and as `?` in `get_tree_summary`.
- `write_html` returns null positions for the nodes it creates, even on the viewed page. Read positions afterwards. _Exercised._
- `get_screenshot` renders on a page the user is not viewing, a `fit-content` board included. _Exercised._

## Across pages

- `move_nodes` with `parentId` set to another page's `rootNodeId` moves the node there, IDs kept. It keeps the world position too, so re-grid on the new page (L8). _Exercised._
- `duplicate_nodes` with that `parentId` puts the copy on the other page, in an empty spot beside its boards, and returns `descendantIdMap`. _Exercised._
- `<x-paper-clone node-id="…" />` reaches a node on another page, and a token-bound value stays `var(--token)` in the clone. _Exercised._
- A comment thread is pinned to a node, and `move_nodes` keeps node ids, so a thread should follow its node. Not exercised.

## Writing

- A `font-family` Paper does not apply is stored as `system-ui, sans-serif`, with no error, even when `get_font_family_info` reports the family available. _Exercised:_ Inter and Geist, bare and quoted, through `write_html` and `update_styles`, in a new file. A `--font-*` token kept its `var()` binding, but `fontFamilies` still listed only `System Sans-Serif`. Cause unknown. Read `get_computed_styles` after the first text write.
- `var(--token)` works in `write_html` and `update_styles` for the file's own tokens. _Exercised._
- Mobile boards: the tool's default is 390x844, while the guide's text says 375. Keep 390x844.

## CSS that write_html accepts

- `write_html` stores `margin`, `display: grid` and `display: inline-flex` without an error, although the tool forbids them, and it drops or converts other production CSS silently. The tested list, with each translation, is in `css-to-paper.md`. _Exercised._

## Replacing a clone

- `write_html` in `replace` mode with `<x-paper-clone node-id="…" style="…" />` puts a fresh clone where the target was, with the placement from `style`, and returns its new node ids. _Exercised._
- A clone keeps its source's layer name. _Exercised._
- Once, while the file was also open in the app, a replace left its new node at the page root and something else in the old slot; it did not happen again in isolation. Check `parentId` with `get_node_info` after each replace.

## Export and images

- `export` with default settings writes a PNG at 2x to `~/Downloads`, named `<layer name>@2x.png`, and returns its `filePath`. _Exercised._
- `<img src="paper-asset:///…">` with that path — spaces included — embeds the PNG. Paper uploads it into the file (`https://app.paper.design/file-assets/<fileId>/…`), so the board keeps it after the local file is gone. _Exercised._
- `<x-paper-clone>` of a whole artboard into a frame of another board works: the clone is a live, editable copy. _Exercised._

## Reading

- `get_jsx` output carries neither node ids nor layer names, although the guide says each element has an id. Read names and ids from `get_tree_summary`, and match its elements by order and text. _Exercised._
- A family Paper applied is stored first in the stack: `"Geist", system-ui, sans-serif`. A bare `system-ui, sans-serif` means it fell back. _Exercised._

## Search

- `find_nodes` results do not name the page. Use one file-wide call for counts and existence, and a `pageId`-scoped call when a report needs locations.
- A wildcard token query finds every node bound to a token family: `styleValue: "*-proto-<slug>-*"` returns only the nodes using that prototype's tokens, and `get_tokens({ namePattern: "*-proto-<slug>-*" })` lists the tokens. _Exercised._
