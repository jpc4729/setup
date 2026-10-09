# Prototypes — changing a product that Paper already mirrors

A mirrored file shows what ships. A prototype shows what is proposed. Both live in one file, and they never mix, because every page has exactly one owner (L2).

## The model

- Code-owned pages show the product as of one release. Only a re-mirror from the running product writes them (`mirroring.md`, `code-to-design.md`).
- Design-owned pages hold proposals. Agents and designers edit them freely.
- The code is the only bridge. A proposal reaches a code-owned page by shipping in the code and coming back through a re-mirror. Nothing is merged across by hand.

So a prototype can never make the code-owned pages wrong: it never writes them. They go stale only when the code changes, and the manifest's commit column lists exactly which boards that affects.

The Index artboard names each page's owner and the release the code-owned pages show. A file with no shipped product has no code-owned pages, and none of this applies: explore and consolidate in place (`iterate.md`).

## When a prototype page is worth it

- A change that spans several boards or flows, lives for more than one session, or goes to review → one page for the initiative, `NN · Proto — <Initiative>` (`naming.md`).
- A quick try at a few directions for one screen → the explorations page (`iterate.md`, Explore).
- A redesign of the token set itself — a new palette, a new type scale → a second file (L1, below).

No tool deletes a page, so create a prototype page only after a yes (L10).

## Lifecycle

1. Open. Post the brief and the structural plan: which boards it forks, which tokens it adds, and the page it needs. Wait for a yes (L10). Then `create_page({ fileId, name })`, keep the `pageId`, and confirm it with `get_basic_info({ fileId, pageId })`.
2. Fork, never draw from blank. `duplicate_nodes` each code-owned board the initiative changes, with `parentId` set to the prototype page's `rootNodeId`. The copy lands in an empty spot on that page, and `descendantIdMap` maps every source node to its copy. Record the fork in the manifest: initiative, slug, page, source board, copy, and the commit the source was mirrored from.
3. Fork the components too. A changed component's sheet is forked like a board. Its cells on the prototype page are the canonical copies for that initiative; clone from them there, and push later changes with the propagate procedure (`components.md`). The components page is code-owned and is never edited.
4. Design. A redesign of a flow follows the review layout: evidence, numbered issues and notes, with each redesign under the screen it replaces (`review.md`). Explore, Tweak and Revise all apply (`iterate.md`). Names, grid and review checkpoints apply as on any page.
5. Hand off. Implementation reads the prototype page (`design-to-code.md`). The ledger lists each board and the code it should become.
6. Close. The code lands, then the re-mirror runs. For each prototype board:
   - It matches the running UI — the implementation check band shows no differences (`review.md`) → promote it. First swap its prototype tokens for the ones the re-mirror created: `find_nodes({ fileId, nodeId, filters: [{ styleValue: "*-proto-<slug>-*" }] })` (_tested_), then `update_styles` to the real token. Re-point its clones: each clone of a forked cell is regenerated from the matching components-page cell (`components.md`, Propagate, scoped to the board), and the manifest's Canonical names those cells. Then `move_nodes` onto its code-owned page, IDs kept, and re-grid (L8), because a move keeps the world position. The mirrored board it replaces moves to the archive, dated.
   - It does not match → re-author from the code as usual, and move the prototype board to the archive, dated.
   - The user's ask for the re-mirror covers these moves, and the ledger lists each one. The manifest takes the new node ids and the shipping commit.
7. Retire. After a yes that names the boards, move what is left — losing directions, unshipped boards — to the archive, dated (L9). The page is then empty: tell the user to delete it in the app; no tool can.

## Tokens: the one trap

Tokens are file-wide and live. A prototype that edits `--color-primary` restyles every code-owned page at once, and the file then shows a product that does not exist.

- A prototype adds tokens and never edits one it did not create. The one family it adds without `proto-` is `--color-annotation-*`, for markers, captions and notes (`naming.md`).
- New tokens carry `proto-` and the initiative's slug after the namespace (`naming.md`): `--color-proto-checkout-accent`, `--spacing-proto-checkout-gutter`. A `description` names the initiative. `get_tokens({ fileId, namePattern: "*-proto-checkout-*" })` lists them, and nothing else matches.
- Where the prototype only renames a role, alias the existing token: `var(--color-primary)`.
- On close, the code defines the real tokens, the re-mirror creates them, and the prototype's tokens are deleted with `set_tokens({ delete: true })` once no node uses them (`find_nodes` on the token).

## The token redesign file

When the initiative changes the token set itself, prototype tokens would double every token in the file. That is the one case for a second file (L1).

- Only after a yes: no tool deletes a file. Then `create_file({ name: "<Project> — <Initiative>", cloneFileId })` and `open_file`, which moves the user's view to the new file; say so first. The clone starts identical, and there `set_tokens` edits freely.
- It is disposable. It is never merged back by hand: the redesign ships in the code, the main file is re-mirrored, tokens first, and the user deletes the redesign file.
- Declare it in the main file's Index while it lives. Anything else with the project's name is still a fork (C1).

## Stale prototypes

The code keeps shipping while a prototype is open. On each re-mirror, compare the changed sources with the recorded forks. A prototype board whose source changed is behind: report it in the ledger. The designer either re-forks that board or accepts the drift until handoff. Nothing updates on its own.
