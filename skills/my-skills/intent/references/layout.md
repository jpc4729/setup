# Layout

```text
.intent/
├── README.md          the index
└── <area>/
   ├── README.md       the area card
   └── <unit>.tree     one unit: one or more trees
```

A repo with several audiences or packages may split into homes. Each home has its own index, decisions and areas, and a root index lists them under `## Homes`:

```text
.intent/
├── README.md          the root index: why the split, and the homes
├── frontend/          a home
└── backend/           a home
```

Name units in kebab-case. At `product` zoom a unit name is a verb phrase, `cancel-order.tree`, or a user story, `operator-changes-a-price.tree`. At `contract` zoom it is the endpoint, command or handler: `post-orders-cancel.tree`. At `code` zoom it is the type or module: `order-service.tree`. A child is named for what it decides: `refund-shown-on-cancel.tree`.

## Index

Fill in every `{…}`. Write the real path of this skill's `scripts/trees` into the Format section, so a reader without the skill can still lint. Use the shared install every tool reads, such as `~/.agents/skills/intent`, not one tool's or one profile's copy. A small home may skip area cards and list its units under Areas as `` `{area}/{unit}.tree` `` items; `check diff` then has no paths to match, so name the scope instead. `scripts/trees audit` reads the `## Homes`, `## Areas` and `## Units` lists and the `Zoom:` and `Budget:` lines, so keep those names. A root index that only splits homes needs the first line, Decisions and Homes.

```markdown
# Intent

{One line: what these trees are for in this repo, and what they replace or sit beside.}

## Decisions

- {Audience per level, scope, homes, what an area is, pillars the product lacks, non-functional requirements, and any default this repo changes}: {the reason, from the survey or the user}.

## Homes

- `{home}/` — {who aligns it and what it covers}. {Only in a root index that splits homes.}

## Settings

- Zoom: {product | contract | code}. An area card may override it.
- Depth: {outline | full | exhaustive}. An area card may override it.
- Budget: {12} leaves per unit, {80} per area, {1000} per home.
- Authority: {`docs/product/` | a spec path | the trees}. The authority wins over a tree. An aligned tree wins over code.
- Check: {trace | tests | run}. {How to start the software or run the suite.}
- Reports: {a folder, or "in chat"}.
- TypeSafe: {allowed | not allowed}. Whether `verify` may send code and test excerpts to TypeSafe. {Only once `verify` has asked.}

## Areas

- `{area}/` — {critical | core | peripheral}: {one line}.

## Format

1. `given` is the world before; `when` is what the actor does or sends; `it should` is an outcome and ends its branch. Its `it should` children are effects checked in the same run.
2. A root reads `{area}::{unit} [{places}]`. The places are the surfaces, the API or the source file where the tree holds.
3. Refusals come first and the happy path last, at every level. The chain of last children is the smoke path. Siblings read top-down and the first that matches wins.
4. Marker lines sit under the root. `// DRAFT:` means nobody has confirmed the tree. `// OPEN: {question}?` means nobody has decided it. `// OUT OF SCOPE: {what} -- {why}` marks a deliberate gap. `// REFINES: {root} > {outcome}` makes the tree a child: it holds on its parent's path to that outcome and states only what the outcome leaves open.
5. `python3 {path}/scripts/trees lint {home}` reports nothing.

## Changing behaviour

A change to behaviour updates its tree in the same change. A new rule lands in the authority first. A changed outcome reopens every child that refines it. A finding no tree covers becomes a question for the user, never a branch on its own. Trees hold intent, never status: what is built, passing or verified lives in the reports.
```

## Area card

Units and Sources are required. Keep the other sections when the zoom needs them. `check diff` matches changed paths against Entry points and Sources, so list real paths there.

```markdown
# {Area}

{One or two sentences: what the actor achieves here.}

{Only when it overrides the index: Zoom: {zoom}. Depth: {depth}.}

## Actors

- {Who runs this flow, with which role, and how they sign in.}

## Entry points

- {Routes, endpoints, commands, or files and symbols.}

## Fixtures

- {Seeded data a check may use, and what a check creates for itself.}

## Units

1. `{unit}.tree` — as {actor}, {goal}, so that {reason}. {Only when it differs from the area's: Rank: {rank}.}
2. `{unit}.tree` (no tree)

## Sources

- {Authority sections and code paths these trees restate.}
```
