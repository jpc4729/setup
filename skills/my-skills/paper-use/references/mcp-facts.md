# What the Paper MCP can and cannot do

The tool descriptions are the reference for parameters, defaults and formats, and this file does not repeat them. It holds what they leave out: what no tool does, what was seen live, and where the guide and the tools disagree. Checked against the tool descriptions and the four guide topics on 2026-10-29; lines marked _exercised_ were run live in a scratch file on 2026-09-24, or read live on the date they carry. Every tool mechanism the laws in `SKILL.md` rely on traces to a line here or to a tool description; the owner and prototype rules are policy, not tool facts. A tool result that contradicts a line below wins; say so in the ledger. When a guide topic or a tool description changes, search every file of the skill for the rules it touches, not only this file: a rule about a tool can sit in any reference.

On 2026-10-29 the server listed 41 tools: `archive_resources`, `arrange_pages`, `create_artboard`, `create_file`, `create_folder`, `create_page`, `create_tokens`, `delete_nodes`, `duplicate_nodes`, `export`, `export_combined_pdf`, `find_nodes`, `finish_working_on_nodes`, `get_basic_info`, `get_children`, `get_comment_thread`, `get_computed_styles`, `get_fill_image`, `get_font_family_info`, `get_guide`, `get_jsx`, `get_node_info`, `get_screenshot`, `get_selection`, `get_tokens`, `get_tree_summary`, `list_comment_thread_authors`, `list_comment_threads`, `list_resources`, `move_nodes`, `move_resources`, `open_file`, `rename_nodes`, `rename_resource`, `set_comment_thread_status`, `set_text_content`, `set_tokens`, `unarchive_resources`, `update_pages`, `update_styles`, `write_html`. A tool the server lists that is not here, or a name here that it no longer lists, means this skill is behind: check the tool descriptions before relying on a line below.

- Every file-scoped tool requires `fileId`, except `get_basic_info` and `get_selection`, where it defaults to the file in view. Take it from the first `get_basic_info`. The file browser tools (`list_resources`, `create_file`, `create_folder`, `rename_resource`, `move_resources`, `archive_resources`, `unarchive_resources`) take resource ids instead, also from `list_resources`; a file id there is the same `fileId`.
- Every file-scoped result starts with a header, `{ file: { id, name }, contentHash: { tokens } }`. The token hash is the one that the guide tells you to compare. _Exercised_ on 2026-10-22.

## What no tool does

- Delete a page. `arrange_pages` reorders the page list and adds or removes dividers, but it never deletes a page.
- Change the page the user is viewing. `open_file` applies its `pageId` only when the file was not open yet.
- `open_file` on a file that is not open yet opens it and makes it the active file: the user's view moves there. _Exercised._
- Delete a file or a folder. `archive_resources` is the reversible step: the item leaves `list_resources` until `includeArchived`, and `unarchive_resources` restores it.
- Create a component, an instance or a detach. Reuse is a copy, and a copy does not track its source. Tokens are the only live propagation a file has.
- Write a comment thread or a reply. An agent reads threads and resolves them.
- Share tokens between files. Tokens are file-level, and a cloned file's tokens stop tracking the original.

## Files and folders

- The file browser has its own Archive. `archive_resources` archives whole files and folders, a folder with everything in it. The `90 · Archive` page of a file holds boards, moved there with `move_nodes`. Never mix the two up in a plan or a ledger.
- `create_file` does not open the new file. `open_file` does, and it moves the user's view there (below).
- No file browser tool was exercised; these lines come from the tool descriptions and the guide.

## Pages and measurement

- A page the user is not viewing is not measured: a size or position that layout decides reads as null in `get_basic_info`, `get_children` and `get_node_info`, and as `?` in `get_tree_summary`.
- `write_html` returns null positions for the nodes it creates, even on the viewed page. Read positions afterwards. _Exercised._
- `get_screenshot` renders on a page the user is not viewing, a `fit-content` board included. _Exercised._

## Across pages

- `move_nodes` with `parentId` set to another page's `rootNodeId` moves the node there, IDs kept. It keeps the world position too, so re-grid on the new page (L8). _Exercised._ `parentId: "root"` is the root of the page the node is on now, never another page.
- A move to a new parent can change the node's width and height intent, so that it does not collapse there. Read its sizing with `get_computed_styles` before a reparent, and restore it after.
- `duplicate_nodes` with that `parentId` puts the copy on the other page, in an empty spot beside its boards, and returns `descendantIdMap`. _Exercised._
- `<x-paper-clone node-id="…" />` reaches a node on another page, and a token-bound value stays `var(--token)` in the clone. _Exercised._
- A comment thread is pinned to a node, and `move_nodes` keeps node ids, so a thread should follow its node. Not exercised.

## Writing

- A `font-family` Paper does not apply is stored as `system-ui, sans-serif`, with no error, even when `get_font_family_info` reports the family available. _Exercised:_ Inter and Geist, bare and quoted, through `write_html` and `update_styles`, in a new file. A `--font-*` token kept its `var()` binding, but `fontFamilies` still listed only `System Sans-Serif`. Cause unknown. Read `get_computed_styles` after the first text write.
- `var(--token)` works in `write_html` and `update_styles` for the file's own tokens. _Exercised._
- The guide says to consider a page for each distinct body of work, and that an agent may organize the pages it creates. On structure this skill is stricter: a new page waits for a yes (L10), because no tool deletes one.
- Mobile boards: the tool's default is 390x844, while the guide's text says 375. Keep 390x844.
- The `mobile-status-bar` guide gives fixed markup with a literal `white` and `font-family: system-ui`, and allows a change to the colour only, `black` on a light background. Keep the markup as it is, and bind the text `color` and the SVG `fill` to a colour token of the file, such as `var(--color-on-surface)`: the guide says SVG `fill` takes a token. Its `system-ui` is the guide's choice and needs no `--font-*` token.
- `create_tokens` accepts a name that already exists and makes a second token with it. Read `get_tokens({ fileId, namePattern })` before you create one; to change an existing token, use `set_tokens`.
- The `figma-import` guide says to resolve every `var(--…)` to a literal. That rule is for the Figma MCP's variables, which the Paper file does not have. The file's own tokens work as `var()`. After an import, bind the literals to the file's tokens (`iterate.md`, Consolidate, step 3).

## CSS that write_html accepts

- `write_html` stores `margin`, `display: grid` and `display: inline-flex` without an error, although the tool forbids the first two, and it drops or converts other production CSS silently. The tested list, with each translation, is in `css-to-paper.md`. _Exercised._

## Replacing a clone

- `write_html` in `replace` mode with `<x-paper-clone node-id="…" style="…" />` puts a fresh clone where the target was, with the placement from `style`, and returns its new node ids. _Exercised._
- A clone keeps its source's layer name. _Exercised._
- Once, while the file was also open in the app, a replace left its new node at the page root and something else in the old slot; it did not happen again in isolation. Check `parentId` with `get_node_info` after each replace.

## Export and images

- `export` with default settings writes a PNG at 2x to `~/Downloads`, named `<layer name>@2x.png`, and returns its `filePath`. _Exercised._ On Paper's remote MCP server it returns a download link that works for 24 hours instead, and a PDF export needs Paper Desktop. The embed below needs a local `filePath`, so it works only with Paper Desktop. Not exercised.
- `<img src="paper-asset:///…">` with that path — spaces included — embeds the PNG. Paper uploads it into the file (`https://app.paper.design/file-assets/<fileId>/…`), so the board keeps it after the local file is gone. _Exercised._
- `<x-paper-clone>` of a whole artboard into a frame of another board works: the clone is a live, editable copy. _Exercised._

## Reading

- `get_jsx` output carries no layer names. It carries node ids by default (`includeNodeIds`), and code for a codebase needs `includeNodeIds: false`. Read names from `get_tree_summary`, and match its elements by order and text. _Exercised_ on 2026-10-22. `get_jsx` also removes the root's canvas position unless `includeRootPositioning: true`; read coordinates with `get_node_info`.
- `get_tree_summary` cuts each text content at 60 characters. Read a full text with `get_jsx` or `get_node_info`. _Exercised_ on 2026-10-22.
- A family Paper applied is stored first in the stack: `"Geist", system-ui, sans-serif`. A bare `system-ui, sans-serif` means it fell back. _Exercised._

## Search

- A literal colour query also returns the nodes bound to a token of that colour, reported as `var(--token)`. _Exercised_ on 2026-10-22. The tool promises this only for colours; for a size, count only the literal hits. In a gradient or a border, `styleValue` is the matched fragment, not the whole value.
- `find_nodes` results do not name the page. Use one file-wide call for counts and existence, and a `pageId`-scoped call when a report needs locations.
- A wildcard token query finds every node bound to a token family: `styleValue: "*-proto-<slug>-*"` returns only the nodes using that prototype's tokens, and `get_tokens({ fileId, namePattern: "*-proto-<slug>-*" })` lists the tokens. _Exercised._
