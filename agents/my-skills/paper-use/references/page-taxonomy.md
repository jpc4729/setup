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
00 · Index                 what the file is, the page map with each page's owner, the release shown, links out
01 · Foundations           token specimens — colour ramps, type scale, spacing, radii, elevation
02 · Components            one sheet per component; each cell is a canonical copy (L5)
10 · <Flow>                one page per flow; its artboards are that flow's screens and states
11 · <Flow>                …
50 · Proto — <Initiative>  one per live initiative — a review, a redesign — deleted by hand when it ships
80 · Explorations          dated, throwaway, referenced by nothing
90 · Archive               superseded work, dated
```

Create only the pages the project has. `00 · Index` earns its place from the moment a second page exists; `02 · Components` from the moment a second flow reuses anything; a `Proto` page from the moment an initiative — a flow review, a redesign, a change to a mirrored product — should not disturb the pages it judges (`review.md`, `prototypes.md`).

## One page per flow

A flow is the set of screens a user moves through for one job: sign-in, checkout, settings. It is the right unit for a page — not one screen, and not the whole product.

- Not one page per screen. No tool reorders or deletes a page, so every page an agent makes is permanent until someone removes it by hand. A hundred screen pages are a hundred manual cleanups.
- Not one page for everything. `get_basic_info` returns every artboard of the page on each call. Automatic placement fills one ever-larger canvas, and two purposes share one list.
- What a flow page buys through the MCP. `get_basic_info` stays small. `find_nodes`, `list_comment_threads`, `list_comment_thread_authors` and `export` all take a `pageId`, so "the raw colours in checkout" or "the open comments on sign-in" is one call. New and duplicated boards land in a small canvas. Agents can work one page each, in parallel, without meeting on the canvas.
- Split a page when it holds two flows, or when it passes about forty artboards. Split by sub-flow, never by state.

Screenshots work on a page the user is not viewing. What does not work there is measurement: a size or position that layout decides reads as null, so the grid check (L8) runs while the user views the page, or before boards switch to `fit-content`.

## Owners

In a file that mirrors a shipped product, every page but the Archive has exactly one owner (L2).

- Code-owned — Foundations, Components and every flow page once it is mirrored. Written only by a re-mirror from the running product (`mirroring.md`).
- Design-owned — `Proto` pages, Explorations and the Index. Edited freely; the re-mirror writes only the Index's release line, copied from the manifest.
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
- A new kind of content about the whole file — foundations, components, index.
- A lifecycle bucket the file lacks — explorations, archive.
- A live initiative — a flow review, a redesign, a change to a mirrored product (`review.md`, `prototypes.md`).

Not justified: a variant of a screen (that is an artboard), a screen (that is an artboard on its flow's page), a platform of the same layout (that is an ordinal band), a person, a sprint, a date, "v2", or "scratch".

## Numeric prefixes

Pages cannot be reordered through the MCP, so a numeric prefix is the only ordering an agent can impose. Use one when the file has more than five pages, or when the user already uses one. Once one page carries a prefix, every page carries one; `rename_pages` adds it to the existing pages in one batch, after a yes (L10). Leave gaps of ten between bands so a flow can be inserted without renumbering the file.

With five pages or fewer, plain purpose names are cleaner and are fully compliant.

## What a page must not hold

- Two purposes. Two flows on one page is the most common cause of a file nobody can navigate, and it is invisible from the page list.
- Loose nodes at the page root. Everything lives inside an artboard; a node parented to `root` is unreachable by every convention here and prints nowhere.
- An artboard whose flow has nothing to do with the page name. If it happened by accident, say so in the ledger; the repair is `move_nodes` to the right page's `rootNodeId`, once the user agrees (L3).

## The index page

One artboard, desktop width, holding: the project name, one line on what the file covers, the page list with one line and one owner each, the release the code-owned pages show, copied from the manifest's `Release shown`, any live token redesign file, the status legend used in artboard names, and the links out — repo, tracker, deployed URL. The release changes with every re-mirror and a page name is a purpose, so the release lives here, never in a page name.
