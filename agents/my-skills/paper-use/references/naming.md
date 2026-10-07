# The naming grammar

Five levels, one grammar each. Names are the only index the file has — `find_nodes` matches styles and text, not intent. Write the name at creation, for the person who arrives in six months.

Hard limit: names truncate at 50 characters. Write a label, not a sentence.

## File

```text
<Project>
```

The name the project is known by — the repo name, or the product name as it ships. `Harbor`, `Ledger`, `orchard-admin`.

Never: a version (`v2`, `2.0`), a date, a state (`final`, `WIP`, `new`), an owner, `copy`, a client name the project does not use, or a platform when the file covers all of them. Each is a symptom of a second file that should not exist (L1).

The one exception is a token redesign file, `<Project> — <Initiative>`, declared in the main file's Index while it lives (`prototypes.md`).

## Page

```text
[NN · ][<Qualifier> — ]<Purpose>
```

A noun phrase naming a purpose or a flow: `Checkout`, `Sign-in`, `Foundations`, `Components`. Prefix rules: `page-taxonomy.md`.

- The qualifier is a platform word, only when the platforms' layouts diverge — `10 · Web — Checkout`, `30 · Mobile — Checkout` — or `Proto` for a prototype page.
- A prototype page names its initiative, not a version: `50 · Proto — One-page checkout`.

Never: `Page 3`, `Untitled`, a status, a person, a date alone, or a verb phrase describing an activity (`Fixing the header`).

## Artboard

```text
NN · <Surface> — <state>
```

- `NN` — zero-padded two-digit ordinal, unique within the page, gapless, and in agreement with reading order (left to right, then down).
- A page with bands — breakpoints, themes — starts each band at the next multiple of ten, plus one, after the previous band's last ordinal: `01`–`07` for the default and `11`–`17` for the next; a default band of fourteen boards runs `01`–`14`, and the next band starts at `21`. Gapless within a band.
- `·` separates the ordinal; `—` separates surface from state. Both separators are fixed, so a name splits mechanically in an audit.
- On the archive and explorations pages, the state ends with the date the board arrived: `07 · Checkout — empty, 2026-09-24`.
- `<state>` is the condition being shown, in the file's own language: `loading`, `empty`, `offline`, `too long`, `validation failed`, `read only`.

Examples:

```text
01 · Checkout — loading
02 · Checkout — payment failed
07 · Order summary — ready to place
```

On a prototype page that holds a flow review (`review.md`), each flow's band numbers from its own ten: `11 · Audit — Checkout`, `12 · Notes — Checkout`, `13 · Notes — Checkout v2`, and `00 · Principles and decisions` beside the first band. A redesign takes a code instead of an ordinal: the flow's letter, unique on the page, and the screen's number, `C1 · Cart — redesign`. A second state takes the next letter, `C3b`; a new version adds ` v2`, `C1 v2 · Cart — redesign`. The notes boards use the same codes, and the principles board lists each flow's letter.

On the components page, each component is one sheet, `NN · <Component> — sheet`, and each cell of it is named for its code identity: `Button · primary · lg · hover` (`components.md`).

Never: `Artboard 1`, `Frame 427`, `Copy of 03`, a duplicate ordinal, a name over 50 characters, or the same name on two artboards in one page. Create with the final name; `rename_nodes` afterwards leaves a window where the file was wrong.

## Layer

The role, in the words the product uses:

```text
Header · Total row · Empty state · Photo grid · Sync banner
```

Set it with `layer-name` in `write_html`, at write time (L4). A component's sheet cell and its clones are the one exception: they carry the code identity, `Button · primary · lg` (`components.md`). The `·` and `—` separators are parsed in page and artboard names, and `·` also in sheet cell and clone names, where it separates the component from its props and its state. Group names describe what the group is for; a wrapper that exists only for layout gets the name of the thing it wraps, or it should not exist.

Never: `Frame 12`, `Group 4`, `div`, `Rectangle 245`, a style description (`Blue box`, `16px text`), or the text the node already contains — that name goes stale the moment the copy changes.

## Token

Namespaced by Paper's eleven types, semantic before palette. These namespaces are Paper's convention, from its guide, whatever the codebase uses; the code's own names live in the `code:` descriptions.

```text
color       --color-*          fontFamily   --font-*          fontSize    --text-*
fontWeight  --font-weight-*    lineHeight   --leading-*       letterSpacing --tracking-*
spacing     --spacing-*        radius       --radius-*        container   --container-*
breakpoint  --breakpoint-*     opacity      --opacity-*
```

Examples:

```text
--color-surface        --color-on-surface       --color-primary       --color-on-primary
--text-title-md        --leading-title-md       --tracking-label
--spacing-lg           --radius-md              --font-sans           --font-weight-medium
--opacity-muted
```

- A semantic name says the role (`surface`, `on-surface`, `outline`, `error`); a palette name says the value (`red-600`). Designs reference semantic tokens; semantic tokens alias palette tokens with `var(--…)`.
- One name per value. Two names for the same hex starts a second design system inside one file.
- Create in the order `create_tokens` asks for: semantic colours first — neutral, primary, secondary, accent — then every other type smallest value first.
- A token's `description` may carry its role or its source path, where the name alone does not say it.
- Annotation is everything on the canvas that is not product: review markers and captions, component sheet labels, spec notes. It uses one family, created once per file and kept: `--color-annotation-marker`, `--color-annotation-ink`, `--color-annotation-muted`, `--color-annotation-rule`. It is neither product nor a prototype's. This line is the family's one definition.
- In a mirrored file, a token's `description` starts with its code identity, `code: <path>#<name>` (`css-to-paper.md`).
- A prototype's token puts `proto-` and a slug for its initiative right after the namespace: `--color-proto-checkout-accent`, `--spacing-proto-checkout-gutter`. The slug is one lowercase word taken from the initiative's name (`One-page checkout` → `checkout`), the same on every token of that prototype, unique across the file's live and past initiatives — check the Index before choosing it — and recorded next to the prototype page on the Index. `proto-` keeps prototype tokens apart from theme tokens and from any real token that contains the same word.
- A `--font-*` value must appear in `get_basic_info.fontFamilies`, or the font is not loaded and the text lies.
- A token holds one value; Paper has no modes. A second theme is a second set of semantic tokens with the theme right after the namespace (`--color-dark-surface`, `--color-dark-on-surface`), aliasing the same palette. Its boards carry the theme in the state and take their own ordinal band: `11 · Checkout — empty, dark`.
