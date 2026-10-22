# Page taxonomy

One file per project (L1), so the pages carry every separation of concerns the project needs. The page list is the file's table of contents.

## Scale the set to the project

No project needs every page below. Start from the smallest shape that fits, and grow when a rule here says so.

- One flow, a handful of boards → one page, named for the flow. No index, no prefixes.
- Two to five purposes → plain purpose names, one page each.
- Several flows, a design system, or both → the full set, with numeric prefixes.
- A shipped product mirrored in Paper → the full set, and every page has an owner (below).

## The canonical set

```text
page                       icon       holds
00 · Index                 info       what the file is, the page map with each page's owner, the release shown, links out
00 · Agent instructions    padlock    the project facts and the file's rules, read by every agent first (agent-instructions.md)
01 · Foundations           swatches   token specimens — colour ramps, type scale, spacing, radii, elevation
02 · Components            design     one sheet per component; each cell is a canonical copy (L5)
── divider
10 · <Flow>                           one page per flow; its artboards are that flow's screens and states
11 · <Flow>                           …
── divider
50 · Proto — <Initiative>  blueprint  one per live initiative — a review, a redesign — deleted by hand when it ships
── divider
80 · Explorations                     dated, throwaway, referenced by nothing
90 · Archive               paper      superseded work, dated
```

The icons and dividers are part of the set: `Dividers and icons`, below.

Create only the pages the project has. `00 · Index` earns its place from the moment a second page exists, and `00 · Agent instructions` comes with it, in the same plan; `02 · Components` from the moment a second flow reuses anything; a `Proto` page from the moment an initiative — a flow review, a redesign, a change to a mirrored product — should not disturb the pages it judges (`review.md`, `prototypes.md`).

## One page per flow

A flow is the set of screens a user moves through for one job: sign-in, checkout, settings. It is the right unit for a page — not one screen, and not the whole product.

- Not one page per screen. No tool deletes a page, so every page an agent makes is permanent until someone removes it by hand. A hundred screen pages are a hundred manual cleanups.
- Not one page for everything. `get_basic_info` returns every artboard of the page on each call. Automatic placement fills one ever-larger canvas, and two purposes share one list.
- What a flow page buys through the MCP. `get_basic_info` stays small. `find_nodes`, `list_comment_threads`, `list_comment_thread_authors` and `export` all take a `pageId`, so "the raw colours in checkout" or "the open comments on sign-in" is one call. New and duplicated boards land in a small canvas. Agents can work one page each, in parallel, without meeting on the canvas.
- Split a page when it holds two flows, or when it passes about forty artboards. Split by sub-flow, never by state.

Screenshots work on a page the user is not viewing. What does not work there is measurement: a size or position that layout decides reads as null, so the grid check (L8) runs while the user views the page, or before boards switch to `fit-content`.

## Owners

In a file that mirrors a shipped product, every page but the Archive has exactly one owner (L2).

- Code-owned — Foundations, Components and every flow page once it is mirrored. Written only by a re-mirror from the running product (`mirroring.md`).
- Design-owned — `Proto` pages, Explorations, the Index and the agent instructions page. Edited freely, except that a rule on the instructions page changes only on the user's ask; the re-mirror writes only the Index's release line, copied from the manifest.
- Nobody — Archive. Things arrive; nothing is edited.

The Index says which is which. A new flow in a mirrored file is designed on its `Proto` page like any other change; its flow page is created by the re-mirror that promotes it. A file with no shipped product has no owners: every page is design-led.

## Platforms

- One platform → no platform word anywhere.
- Several platforms whose layouts differ — a native app and a desktop web app → a band of flow pages per platform, `10 · Web — Checkout` and `30 · Mobile — Checkout`, and a components page per platform when their components differ. Foundations stay one page: the tokens are one set (`naming.md`).
- One responsive product → one page per flow, with each breakpoint as an ordinal band of artboards on it (`naming.md`).

## Purpose, not status

Do not make status pages — `Ready for dev`, `In progress`, `Backlog`. Under that scheme a status change is a move to another page. `move_nodes` can make that move (`mcp-facts.md`), but each one also needs a re-grid on the new page (L8), while a status in the artboard name is one rename. A status page also splits one surface's states across pages.

Pages are purposes. Status lives where it can be changed — in the artboard name, or as a label inside the artboard, both editable with one call. `Explorations` and `Archive` are the exception, and they are lifecycle rather than status: work that has left the current design, not work waiting on someone. A `Proto` page is a purpose too: one initiative, from its review to its ship (`review.md`).

## When a new page is justified

A new page needs one of these, and nothing else does.

- A new flow of the project.
- A new kind of content about the whole file — foundations, components, index, agent instructions.
- A lifecycle bucket the file lacks — explorations, archive.
- A live initiative — a flow review, a redesign, a change to a mirrored product (`review.md`, `prototypes.md`).

Not justified: a variant of a screen (that is an artboard), a screen (that is an artboard on its flow's page), a platform of the same layout (that is an ordinal band), a person, a sprint, a date, "v2", or "scratch".

The guide invites a page for each distinct body of work. Here, a body of work gets a page only when it is one of the four above.

## Numeric prefixes

A numeric prefix gives each page its place in the list and in every reference to it. Each page has its own prefix, except the two pages about the file itself: `00 · Index`, then `00 · Agent instructions`. Use one when the file has more than five pages, or when the user already uses one. Once one page carries a prefix, every page carries one; `update_pages` adds it to the existing pages in one batch, after a yes (L10). Leave gaps of ten between bands so a flow can be inserted without renumbering the file.

The page list runs in the order of the canonical set, which the prefixes spell out. `create_page` adds a page after the one the user is viewing, so `arrange_pages` then moves it to its place in the list. A page this session created moves freely; a move of any other page waits for the same yes as a rename (L10).

With five pages or fewer, plain purpose names are cleaner and are fully compliant.

## Dividers and icons

Both decorate the page list; neither changes what a page holds, and neither carries owner or status. The Index says the owner, and the artboard name says the status.

Dividers:

- Only in a file with prefixes. A smaller file has no bands to separate.
- One divider at each band boundary of the canonical set: after the file-wide pages, after the flows, and after the `Proto` pages. Never one at the top or bottom of the list, next to another divider, or around a band with no page.
- A divider takes no name: the prefixes on each side name the band. Read its id from `get_basic_info.pages[]`; that id is not a `pageId`.
- Set dividers in the `arrange_pages` call that sets the order: `{ "type": "divider" }` in `order` where a new one goes, and the id of each one to drop in `removeDividerIds`, never also in `order`. `order` lists every other page and divider id exactly once, so read `pages[]` with `get_basic_info` right before the call.
- A missing, unknown or repeated id rejects the whole call with no change, and so does a page added or removed since the read: read `pages[]` again and send the call once more. The result is the new page list with the ids of the new dividers; use it, not a second read.
- A band that gets its first page, such as the first `Proto` page, gets its divider in the call that moves that page into place. A band that loses its last page loses its divider in the next `arrange_pages` call.

Icons:

- Set the icon when the page is created, as with its name (L4): `create_page({ fileId, name, icon })`. `update_pages` changes it later, and `icon: null` restores the default.
- The map is in the canonical set above: an icon marks each page that is not a flow and not an exploration, so the flows stay plain and the icons stay few, as the guide asks. A page outside the set takes no icon.
- A file that already uses icons keeps its own map: follow it. Giving the map to the existing pages of a file changes pages a human made, so it waits for a yes (L10).

## What a page must not hold

- Two purposes. Two flows on one page is the most common cause of a file nobody can navigate, and it is invisible from the page list.
- Loose nodes at the page root. Everything lives inside an artboard; a node parented to `root` is unreachable by every convention here and prints nowhere.
- An artboard whose flow has nothing to do with the page name. If it happened by accident, say so in the ledger; the repair is `move_nodes` to the right page's `rootNodeId`, once the user agrees (L3).

## The index page

One artboard, desktop width, holding: the project name, one line on what the file covers, the page list with one line and one owner each, the release the code-owned pages show, copied from the manifest's `Release shown`, any live token redesign file, the status legend used in artboard names, a pointer to the agent instructions page, and the links out — repo, tracker, deployed URL. The release changes with every re-mirror and a page name is a purpose, so the release lives here, never in a page name.
