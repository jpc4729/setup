# shadcn/ui and Tailwind CSS

The manifesto assumes no toolkit, and the gate already rules that a library shipping a component is no reason to place it. This reference is for the surface built on shadcn/ui over Tailwind CSS v4 anyway. It sorts all 65 entries in the shadcn catalogue by how well each one carries the Laws. It builds each skeleton in `composition.md` and each form in `encodings.md` out of named parts. And it gives the utilities that turn the values in `color.md`, `material.md`, `typography.md` and `motion.md` into classes. shadcn is source the CLI copies into the repo, so a default that fights a Law is edited once in the component file and never obeyed. Three commands write over that edit — `apply`, `add --overwrite` and `init --reinstall` — so none runs without the user's approval, and `add <component> --dry-run` or `--diff <file>` previews a change first. `npx shadcn@latest info --json` names the style, the base, the icon library, the Tailwind version and the CSS file. This sheet assumes Tailwind v4; a v3 repo keeps its tokens in `tailwind.config.js`, so the utilities below translate rather than copy.

## Stance

- The catalogue is a parts bin, not a menu. A region assembled from Card, Sheet and Alert because the registry lists them is the gate's `Stock component`. Start from the content, pick the vessel, then find the part.
- Icons, chips, faces and hues are what this stack makes cheap. A Lucide glyph is one import, a Badge one line, an Avatar two. On a dense surface a leading glyph naming each row's kind, a Badge on every closed-set value, a face beside every person and a hue on every status that earns one are the expected build, and their absence needs the argument (Law 17, `Bare row`).
- The stock theme is a skeleton in a formula skin. The stock `--chart-1` to `--chart-5` came from no artifact of anyone's world, and shipped unchanged the surface reads as every other shadcn app, which is Law 18's `Formula skin`.
- The style is a density decision, not a skin. It changes geometry and spacing, not only color. It is picked at `init`, and `apply` switches it later, whole or through `--only`. Eight ship: Vega, clean and neutral; Nova, the default, with reduced padding and margins; Maia, rounded with generous spacing; Lyra, boxy and sharp, for mono fonts; Mira, made for compact interfaces; Luma, fluid and soft; Rhea, Luma made compact; Sera, editorial and typographic. Dense product surfaces take Mira or Rhea. Pick by register and keep one style per product (Law 14).
- The official shadcn skill may load beside this one, and the two disagree on four points: raw palette classes at call sites, color set through `className`, a Card per region, and a Sheet for side panels. On layout the Laws win — no Card per figure, no Sheet for record details. On spelling theirs does: color lives in tokens and in `cva` variants inside the component file, never in a raw palette class at a call site.
- A block is a screen. `dashboard-01` and the sidebar blocks are finished screens: borrow the skeleton, name the one change, strip it back, or Law 20 calls it a `Lifted screen`.
- Fix a shared cause at its owner. A Badge too loud everywhere is one edit in `components/ui/badge.tsx`, not a `className` on forty call sites that will drift apart (`Peer drift`).

## Carries the Laws

Build from these first. Each already holds a Law in its default shape, and each entry says what to keep.

- Item — the row. `ItemMedia` on the start edge, `ItemContent` in the middle, `ItemActions` on the end edge: two contacts by construction, which is Law 2 as a component. The task row, the settings row, the activity row and the rows of every list outside the Sidebar are Items inside an `ItemGroup`. Item is for display rows and Field is for controls. Keep the default variant; `variant="outline"` on every row boxes each one (`Box in a box`). `ItemSeparator` goes in only where space has failed (Law 5). `ItemMedia variant="icon"` draws a tile behind the glyph: use it where the tile is the recognition, such as an integration's logo, and leave a routine row's glyph bare.
- Field — the form row. `FieldSet` and `FieldLegend` name a group, `FieldGroup` spaces it, and one `Field` holds a `FieldLabel`, the control, a `FieldDescription` and a `FieldError`. `orientation="horizontal"` is the settings row: name and description on the start edge, the Switch on the end edge. `orientation="responsive"` reflows on the `FieldGroup`'s container width, which is Law 21's container query already written. Set `data-invalid` on the Field and `aria-invalid` on the control, so the error reaches both the eye and assistive technology. A label sits nearer its own control than the next field because the `Field` gap is smaller than the `FieldGroup` gap; keep that ratio (Law 5).
- Badge — the chip: a pill, `h-5`, with its glyph forced to `size-3`. The `default` variant is a solid primary fill, which on a routine category is `Loud default`. Add one `cva` variant per status or category in `badge.tsx` — `success`, `warning` — carrying the tint and ink tokens under Color below, and build a monochrome chip on `secondary` or `outline`. One Badge per closed-set value, and never one around an open string, which promises a set that does not exist (`encodings.md`).
- Avatar — the face. Inline at the height of its line, `size-5` beside `text-sm`, which sits below the stock `sm`, inside the sentence that names the person. Large in a profile header with `ring-4 ring-background`, so it separates from the cover and from the page at once, and `AvatarBadge` carries the verification mark on its corner. `AvatarGroup` ends in `AvatarGroupCount` once the faces pass a few. Every Avatar carries an `AvatarFallback`, since a missing image is a data edge (`states.md`), and its initials rank below the name they abbreviate (`encodings.md`).
- Checkbox and Switch — Law 9's own example, shipped as the default. Off is a border and nothing else; on earns the fill and the mark. Never tint the off state. A Checkbox commits with a form and a Switch applies on the spot (`encodings.md`, Boolean).
- Tabs — a muted track with the current trigger raised. Each trigger is a glyph and a word. Tabs switch the region under them. `variant="line"` suits tabs that head a whole pane.
- Toggle Group — the settings panel's segmented control: the same track when it sets a value instead of switching a region, such as a period, a tier or a view. `type="single"`, a glyph and a word per item, and `spacing={0}` so the items join into one track; the default spacing splits them into separate buttons.
- Kbd — a symbol the audience already owns. `⌘K` on the end edge of the search field, `/` on the start edge of the checklist footer, a `KbdGroup` for a chord.
- Input Group — a field that reads before it is read. `InputGroupAddon align="inline-start"` holds the Search glyph, `align="inline-end"` the Kbd hint or a clear Button, `align="block-end"` the toolbar under a chat `InputGroupTextarea`.
- Button — one `default` per decision (Law 8); every other action is `outline`, `ghost` or `link`. Its label names the outcome, never the click (Law 10). The icon sizes keep an icon-only control square and on the scale. An icon-only Button carries an `aria-label`, a Tooltip names it on approach, and its glyph is one the audience owns — link, star, more. It is never the only name of a primary action (Law 10).
- Button Group — one boundary for a cluster instead of three, so the record's action cluster reads as one unit and spends one cue (Law 5). Also the split button and the pager.
- Sidebar — the left pane of the three-pane surface, part for part: `SidebarHeader` with the workspace switcher, `SidebarInput` for search, `SidebarGroupLabel` as the landmark with `SidebarGroupAction` holding the add affordance on its end edge, `SidebarMenuButton isActive` as the one filled pill, `SidebarMenuBadge` for a count on the end edge in `tabular-nums`. `collapsible="icon"` keeps the glyph column and names each row through `tooltip`, so recognition survives the narrow width; confirm in the accessibility snapshot that each collapsed row keeps its text as its name (`Lost name`). The default `offcanvas` throws the glyphs away. Keep `variant="sidebar"`, which meets the main pane with one hairline; `floating` and `inset` wrap the panes in enclosures the surface does not need. `SidebarMenuAction showOnHover` hides its action from `md` up, which lets a width stand in for an input; gate it on hover instead, per States below.
- Breadcrumb — the head of the main column: where the record sits, said once, above its title.
- Chart — the vessel for a magnitude or a trend (Law 1). `ChartConfig` gives each series a label, an icon and a color, written as `color: "var(--chart-1)"` and read back as `fill="var(--color-<key>)"`, so the tooltip and the legend read by glyph. `ChartTooltipContent indicator="dot"` is the comparison chart's tooltip: each value behind its own dot and named. Replace the stock `--chart-*` with the category set.
- Table — two edges: text on the start edge, compared figures `text-right tabular-nums` on the end edge with the header aligned the same way. Data Table is a recipe, TanStack Table over Table, that adds sort, filter and selection. Its faceted filters are Badges, and its status and priority columns lead with a glyph.
- Collapsible — the right rail's section heading with a chevron on its end edge. Each section opens on its own, and the frequent ones open by default.
- Command — the one reveal that opens on its primary action by construction: the search field. `CommandItem` leads with a glyph and ends in `CommandShortcut`, two contacts per row.
- Dropdown Menu — the rung for rare actions, behind an `Ellipsis` Button at the end of the cluster. Items lead with a glyph and end in `DropdownMenuShortcut`, and a destructive item takes `variant="destructive"` below a `DropdownMenuSeparator`. A frequent action inside it is `Buried` (Law 13).
- Popover — a secondary task in place, grown from its trigger through `origin-(--transform-origin)`, which is Law 19's origin rule already wired. It opens on its own primary action.
- Select, Native Select and Combobox — enum entry. In a read-mostly row the current value is a Badge with a glyph and the choices open from it (`encodings.md`, Enum); in a form it is a field. A set longer than one menu is a Combobox with search. Native Select wins on touch, where the platform picker is the one the hand already knows.
- Message and Marker — the conversation's row and landmark. A Message carries the face, the author and the time on two edges, which is the activity feed's reply block. A Marker in its `separator` variant labels a run of turns — Today, Yesterday — which is Law 6's grouping in a thread, and in its `default` variant it states a system event inline.
- Attachment — a file as `encodings.md` draws it: a glyph or a thumbnail for its kind, the name in its own casing, and a `state` of idle, uploading, processing, error or done. The state is the hidden layer, designed.
- Message Scroller — follows a streamed reply only while the reader is pinned to the bottom, and holds their place once they scroll up. That is Law 19's rule against moving what is being read, already written.
- Empty — the designed empty state: an `EmptyMedia` glyph, an `EmptyTitle`, one line of `EmptyDescription`, and `EmptyContent` holding the action that fills the region. Centered is correct here, because nobody compares it.
- Skeleton — loading at the region's real size. Compose it from the row's own geometry, an Item-shaped skeleton under a list and a plot-shaped one under a chart, so nothing moves when the data lands.
- Spinner — pending beside a kept label, inside the Button that fired it with `data-icon="inline-start"`, never in place of the label (`states.md`). The official skill writes that Button `disabled`, which drops focus to the page; `aria-disabled` keeps focus on it while it runs.
- Separator — the third cue. Between panes, and between a stat strip and the actions under it. Never between rows that two edges already hold.
- Tooltip — names an icon-only control on approach, and a Kbd inside it teaches the shortcut on the same approach. It carries no meaning the control lacks at rest. The provider ships with no delay, so a pointer crossing a toolbar flashes one name per glyph; give it a short delay.

## Earns its place under a condition

Right under one condition, wrong outside it. The condition is the whole verdict.

- Card — an enclosure that states a unit: the profile card, the comparison chart, the checklist. It is already quiet — a `ring-1 ring-foreground/10` hairline, no shadow, and a `CardFooter` separated by tone and a rule — and `CardAction` puts a period selector or a menu on the header's end edge, which is a second contact. As the default wrapper for every region it is Law 4's scaffolding, and a Card in a Card, or a Card inside `SidebarInset` when the Sidebar is `variant="inset"`, is `Box in a box` with a `Radius stack`. The `dashboard-01` row of KPI cards is a stat strip carrying four borders it did not need.
- Dialog — the level 4 blocking layer (`material.md`) for a decision that must end before work resumes, or a short create flow with its own primary action. A Dialog that explains the product is `Modal dump`. A Dialog, a Sheet and a Drawer each carry a Title, with `className="sr-only"` where it is not shown, or assistive technology meets an unnamed layer.
- Alert Dialog — the confirmation a destructive, irreversible action owes (Law 13). The action names the verb and the object, "Delete 3 invoices", in `variant="destructive"`; "Continue" names the click, not the outcome. `size="sm"` centers its header at every width and `default` does below `sm`, so left-align the header wherever its description states a consequence the user must read. A reversible action takes an undo instead.
- Toast and Sonner — the announcement of a reversible action, carrying its undo. The Base UI build ships its own Toast; the Radix and React Aria builds use Sonner. A toast holding the only undo never expires on a timer (`states.md`), so the undo also lives in place or the toast waits. A fact the user needs later is never only in a toast.
- Alert — a state the data produced, placed inside the region it concerns: an error, a stale source, a quota near its limit. As a routine tip it is `Loud default` and `Overexplained`.
- Hover Card — a preview of a person or a link on approach. Touch has no approach, so the link it decorates still reaches the same fact.
- Bubble — a conversation between two parties, where the side a bubble sits on names its sender. In an agent transcript only one side needs an enclosure: the user's turn takes a `muted` or `tinted` Bubble, and the reply takes `variant="ghost"`, which draws no surface, so the difference carries the speaker (Law 8) and no turn sits in a box it did not need (Law 4).
- Questionnaire — questions asked one at a time, when each answer changes the next or the set is too long to scan. A short set of independent questions is one Field form shown whole. This is Law 13's ladder run in time: point at one step, wait, then offer the next.
- Accordion — headings people scan on a brand FAQ. A single-open Accordion — the Base UI default, `type="single"` on Radix — closes one section when another opens, so the reader loses what they were comparing; a product rail takes one Collapsible per section instead.
- Resizable — two panes whose width the user genuinely trades: a mail list against its message, code against its preview. Otherwise each region is capped by its content (Law 3) and no handle is owed.
- Pagination — a collection where position in the set matters, such as search results. A feed or a task list takes grouping (Law 6) and loads on scroll.
- Progress — a bar across a wide region with a known total, its figure printed beside it. A row-tall progress is a ring, which shadcn does not ship, and an unknown total takes a Spinner (`encodings.md`).
- Slider — a continuous value, with its figure printed beside it in `tabular-nums`.
- Radio Group — a short exclusive set shown whole in a form. A choice card, a `FieldLabel` wrapping a `Field`, earns its enclosure because the boundary is the selection target (Law 4). It already wears its selection cue through `has-data-checked:bg-primary/5`; keep it.
- Toggle — a pressed state in a toolbar, filled only while pressed (Law 9).
- Calendar and Date Picker — date entry, the picker being a Popover over a Calendar. Display stays relative near and absolute far (`encodings.md`).
- Navigation Menu — a brand site's top navigation. Its panels open on approach, so each opens on its primary link and works on tap.
- Context Menu — a right-click mirror of a visible Dropdown Menu for pointer users. Never the only path: touch has no right click, and nothing at rest says it exists.
- Menubar — a document editor's File, Edit and View. On a product screen it buries frequent actions in menus (`Buried`).

## Against the grain

The default shape breaks a Law. Use one only for the exception named.

- Sheet — a Dialog drawn as a side panel, so it is level 4: a scrim, a focus trap, the page inert behind it. Every property then works against the Laws. It covers the record it was opened from, so the fact the user was comparing against goes dark under the scrim and the form loses contact with the row it edits (Law 3). It slides in from the viewport edge rather than growing from its trigger, so the eye crosses the screen to find it (Law 19). It opens on a title and a description and pins its footer to the far foot with `mt-auto`, so the primary action sits as far from the eye as the panel allows (`Headless reveal`). Its width stops at `sm:max-w-sm`, which squeezes whatever it holds (`Squeezed vessel`). And it is a page in a panel's costume (`Detour`). The work it usually carries has a better home: record details in a persistent right rail, a few fields in place or in a Popover, a blocking decision in a Dialog, a real task on its own route. The exception is navigation at a narrow width, which is where the Sidebar already renders one. Replacing a Sheet a product already ships is a migration, so fix mode proposes it rather than applying it.
- Drawer — an edge panel driven by a swipe: Base UI's Drawer, or vaul in the Radix build. On touch it is the gesture rung and follows the hand, which Law 19 asks for. On a pointer surface it is a costume: a swipe handle nobody drags with a mouse, a panel rising far from its trigger, and a header centered on a vertical swipe below `md`, which is `Ceremonial body` once its description is read. Snap points park content below the drawer's own fold. Use it as the touch rung of a Dialog or a Popover, and switch on input with a `(pointer: coarse)` media query, never on a width borrowed from a device (`Device breakpoint`).
- Carousel — one item visible, the rest behind a swipe or an arrow. Content hidden to fit is what Law 21 forbids, and autoplay is `Hostage rotation`. A product surface shows the set as a grid or a list. A brand gallery where every item matters may keep one, paused on approach and operable without waiting.

## Plumbing

No layout claim. Place freely.

- Label — superseded by `FieldLabel` inside a Field.
- Input, Textarea and Input OTP — fields. They take their glyphs and hints through Input Group, and a Textarea grows with `field-sizing-content`.
- Scroll Area — a styled scroll container for a pane that scrolls on its own.
- Aspect Ratio — holds a cover band or a piece of media at a fixed shape, so nothing jumps when it loads.
- Direction — the provider that flips a surface for right-to-left reading. Logical utilities such as `ps-*`, `me-*` and `border-s` are what let the flip leave the layout whole.
- Typography — a docs page of prose styles, not a component.

## The skeletons, in parts

Each skeleton in `composition.md`, named by the parts that build it.

- Three-pane surface — `SidebarProvider`, then `Sidebar`, then `SidebarInset` marked `@container/main`, and inside it a child `grid` holding the main column and the right rail on `@5xl/main:grid-cols-[minmax(0,1fr)_20rem]`, the rail's `border-s` as the third edge. Below that width the rail stacks under the main column in reading order. It never becomes a Sheet.
- Main column head — `Breadcrumb`, then the title with a `ghost` Pencil Button beside it, then a muted subline. On the end edge, level with the Breadcrumb, a `ButtonGroup` of `outline` icon Buttons: Link, Star, Ellipsis.
- Grouped task list — a muted `text-xs` group label, then an `ItemGroup` of `size="sm"` Items: a Checkbox in `ItemMedia`, the sentence carrying an inline Avatar, an underlined link and a Badge, and the due time in `ItemActions` behind a Clock glyph.
- Activity feed — the same Item, with the status ring in `ItemMedia` in the hue its outcome earns, the actors underlined in the sentence, the elapsed time on the end edge. A reply nests as a Message inset from the spine, its Avatar and author on the first line.
- Key-value block — a `dl` on `grid-cols-[auto_1fr]`, so every value shares one start edge whatever the label's length:

```tsx
<dl className="grid grid-cols-[auto_1fr] items-center gap-x-8 gap-y-3 text-sm">
  <dt className="whitespace-nowrap text-muted-foreground">Hire date</dt>
  <dd className="flex min-w-0 items-center gap-2">
    <Calendar className="size-4 shrink-0 text-muted-foreground" />
    <span className="truncate">Jan 8, 2024</span>
  </dd>
  <dt className="whitespace-nowrap text-muted-foreground">Employment</dt>
  <dd>
    <Badge variant="secondary">
      <CircleDashed data-icon="inline-start" />
      Full time
    </Badge>
  </dd>
</dl>
```

- Stat strip — a `dl` on `grid-cols-2 @sm:grid-cols-4` under an `@container` ancestor, the label in `text-xs text-muted-foreground` above the value in `font-semibold tabular-nums`, and no Card per figure.
- Settings row — a Toggle Group track, then Items: a bare glyph, the setting's name, and in `ItemActions` a Badge with its own glyph that opens the choices, then a ChevronRight. The one boolean is a Switch, and the only saturated fill in the panel.
- Checklist enclosure — a Card holding an `ItemGroup`, and the stock `CardFooter`, already separated by tone: a Kbd on the start edge, the named progress ring on the end edge.
- Profile header — a cover band in an Aspect Ratio, an Avatar pulled up across its lower edge with an `AvatarBadge` holding a BadgeCheck, and the action cluster sitting on the same edge through `items-end`. Then the name, the tagline, a meta line behind MapPin and Link, a stat strip, a Separator, and two unequal Buttons, `outline` and `ghost`.
- Comparison chart — a Card, a `CardTitle` led by a ChartColumn glyph, a Select in `CardAction`, a horizontal bar chart with the current series in its hue and the comparison in the pale step behind it, and `ChartTooltipContent indicator="dot"`.

## Tailwind

Tailwind v4 is configured in CSS. `@theme` declares a token and the utility that reads it. `@theme inline` maps shadcn's runtime variables into utilities, so `bg-muted` resolves to `var(--muted)` and flips with the theme. Every scale Law 14 asks for is a namespace there, and a value outside the namespace is an arbitrary value, which is where `Off-scale` hides. Tokens go in the file `info --json` names as `tailwindCssFile`, never in a second stylesheet.

### Scale

- Spacing — `--spacing: 0.25rem`, so `gap-3` is 12px and every step is a multiple. An arbitrary `p-[13px]` or `mt-[7px]` is `Off-scale`; search a diff for `-\[[0-9.]+px\]`.
- Gaps belong to the parent: `gap-*` on the flex or grid container, never a margin on a child, or one relationship is spaced twice (`Orphan inset`). Gaps grow outward — `gap-1.5` between a glyph and its label, `gap-3` between rows, `gap-6` to `gap-8` between groups — and the gap above a heading runs about twice the gap under it (Law 22).
- Radius — shadcn derives every step from one `--radius` of `0.625rem`, `sm` at 0.6 times it up to `4xl` at 2.6 times, so one number moves every corner together. The stock parts already scale radius with the surface, as `material.md` asks: a Badge is a pill, a Button and a Popover `rounded-lg`, a Card and a Dialog `rounded-xl`. An inner corner is the outer minus the inset: inside a `rounded-xl p-2` surface, `rounded-[calc(var(--radius-xl)-0.5rem)]`.
- Elevation — the stock scale spends tone and hairline before shadow, which is `material.md`'s order. A Card and a Dialog wear `ring-1 ring-foreground/10` and no shadow. A Popover and a Hover Card add `shadow-md`. A Sheet and a Toast take `shadow-lg`. The ring is an alpha hairline, so it sits on any surface and flips to a white alpha in dark. Keep the scale and add no level. The overlays portal out and stack by themselves, so they take no manual `z-index`. A preset's translucent `menuColor` is glass, and it holds only where content sits behind the menu (`material.md`).
- Motion — declare `motion.md`'s curves as `--ease-decelerate`, `--ease-accelerate` and `--ease-both` in `@theme`, and `ease-decelerate` exists as a utility. The stock Button, Toggle and Tabs trigger ship `transition-all`, which `motion.md` rules out; name the properties in the component file, `transition-[color,background-color,border-color,translate]`, since v4's `translate-*` utilities move the `translate` property rather than `transform`. Leave `box-shadow` out: it is the focus ring, and a ring that transitions shows late. The stock Sheet runs `duration-200 ease-in-out` and the Popover, Dropdown Menu, Hover Card and Dialog run `duration-100`, both outside `motion.md`'s bands, so set them in the component file too. `motion-reduce:` removes the movement and keeps the fade.

### Color

- Hues — `color.md`'s category set is Tailwind's own palette at the same OKLCH values: `blue-600`, `violet-600`, `green-600`, `red-600`, `amber-600` and `pink-600`. A chip is the 100 step for the tint and the 700 step for the ink, with 950 and 300 in dark. These are the values the tokens hold, never classes at a call site.
- Name the job, not the hue. Wrap each pair in a token that flips with the theme, so a status changes hue in one place, no call site carries `dark:`, and a chip is a Badge variant built on `bg-success-tint text-success-ink`:

```css
:root {
  --success-tint: oklch(96.2% 0.044 156.743);
  --success-ink: oklch(52.7% 0.154 150.069);
}
.dark {
  --success-tint: oklch(26.6% 0.065 152.934);
  --success-ink: oklch(87.1% 0.15 154.449);
}
@theme inline {
  --color-success-tint: var(--success-tint);
  --color-success-ink: var(--success-ink);
}
```

- Neutrals — `neutral` has chroma 0, which is a choice, not a defect. To tint the ramp toward the accent, per `color.md`, take the base that leans toward it: `zinc` or `mist` beside a blue, `mauve` beside a violet or a pink, `olive` beside a green, `stone` or `taupe` beside a warm accent. `npx shadcn migrate base-color` moves an existing repo between bases, and the stock `--surface` token sits at chroma 0 either way, so retint it with the base.
- Muted is the default. `text-muted-foreground` carries every label, caption, routine glyph and unchanged value, and `text-foreground` carries the values. Hue goes on what changed (Law 9).
- Links — shadcn ships no link token, and its `--primary` is near-black. An inline link is `text-link underline decoration-1 underline-offset-[0.15em] hover:decoration-2`, where a `--link` token holds `blue-700` and flips with the theme (`color.md`). A link in a nav, a toolbar or a card title drops both.

### Type

- Product text is `text-sm`, group labels and captions `text-xs` and no smaller, a pane heading `text-base font-semibold`, a record title `text-2xl font-semibold tracking-tight`.
- `tabular-nums` on every figure a user compares, and `text-right` on the cell and its header together.
- `text-balance` on headings, `text-pretty` on paragraphs, `max-w-prose` on anything read at length.
- `truncate` needs `min-w-0` on its flex or grid child, or one long value pushes its siblings off their edges (`Crowded cell`). The full value stays reachable in a Tooltip or on the record.
- A chip's tag of four characters or fewer and a pane's section label may take `uppercase tracking-wider`; every other word stays in sentence case (`typography.md`).

### Icons

- One family per repo, set once as `iconLibrary` in `components.json`, which the CLI reads when it writes a component. The choices are `lucide`, the default, `tabler`, `hugeicons`, `phosphor` and `remixicon`, and Remix Icon is no longer open source (`tools.md`). `npx shadcn migrate icons` moves a repo between families whole. A second family is `Mixed family`.
- Stroke follows the text weight through the family's stroke prop, `strokeWidth` in Lucide, at the values in `typography.md`.
- Size follows the text. The stock parts size an unsized child glyph through `[&_svg:not([class*='size-'])]:size-4`, so a glyph beside `text-sm` is 16px and one inside a Badge is 12px. A glyph never grows for emphasis (`Loud glyph`).
- `data-icon="inline-start"` or `"inline-end"` on a glyph inside a Button, a Badge or a Toggle trims the padding on that side, so the glyph's ink rather than its box sits the same distance from the edge (Law 22).
- A routine glyph is `text-muted-foreground`; a status glyph takes its status ink. `shrink-0` keeps it whole in a tight row.
- Lucide hides every glyph from assistive technology unless it is given an `aria-label` or a `title`, so a decorative glyph needs nothing and a semantic one needs its name.
- One glyph per data type across the product, so the glyph column becomes a third edge (`composition.md`). The roles are named here in Lucide; map each to its match in the repo's `iconLibrary`. Calendar for a date, Clock for a time or a deadline, User for a person, Users for a team, MapPin for a place, Globe for a region, Link for a URL, Mail for an address, Tag for a category, Folder and FileText for files, CreditCard and Receipt for money moved, ChartColumn for a comparison, TrendingUp and TrendingDown for a direction, CircleCheck, CircleAlert and TriangleAlert for outcomes, BadgeCheck for verified, ChevronsUpDown for a switcher, Ellipsis for more, CircleQuestionMark for help. A second glyph for a type already solved is `Second answer`.

### States

- Every part carries `data-slot`, and `shadcn/tailwind.css` registers `data-open:`, `data-closed:`, `data-checked:`, `data-selected:`, `data-active:` and `data-disabled:` to match the Base UI and Radix attributes alike; `npx shadcn eject` inlines that file and drops the dependency, and the variants then live in the repo's own CSS. Style a state through its variant: `data-open:bg-accent`, `aria-invalid:border-destructive`, `has-data-checked:border-primary`.
- A parent reaches a part through its slot, with no new prop: `[&_[data-slot=item-media]]:text-muted-foreground` mutes every routine row glyph in one list, while a status glyph keeps the hue on its own class.
- Focus stays visible. The stock ring is `focus-visible:ring-3 focus-visible:ring-ring/50`, a box-shadow, and the Button, Toggle, Native Select and Toast pair it with `outline-none`. Forced-colors mode drops box-shadows, so that pairing leaves no focus indicator there (`states.md`). Swap the bare `outline-none` for `focus-visible:outline-hidden` in the component file: it removes the browser outline everywhere except under forced colors, where it paints a 2px outline on the focused control.
- Tailwind v4 wraps every `hover:` in `@media (hover: hover)`. `opacity-0 group-hover:opacity-100` therefore never shows on a touch screen, and the action is stranded (`Hover-only action`). Hide it only where hover exists, and reveal it on focus too:

```tsx
<Button
  variant="ghost"
  size="icon-sm"
  aria-label="Copy value"
  className="group-hover/row:opacity-100 group-focus-within/row:opacity-100 [@media(hover:hover)]:opacity-0"
>
  <Copy />
</Button>
```

- `pointer-coarse:` and `pointer-fine:` branch by input, which is how a rung changes with the hand rather than with the width.

### Breakpoints

- `@container` on a region and `@md:` on its children reflow the region on its own width. Name the container when regions nest: `@container/rail`, then `@sm/rail:grid-cols-4`. Viewport variants such as `md:` belong to the page frame alone (`Viewport reflow`). Container sizes run from `@3xs` at 16rem to `@7xl` at 80rem, in rem, so they move with the user's font size (`states.md`).
- The Table wraps itself in `overflow-x-auto`, which is `Squeezed vessel` as a default. Below the width its columns need, render the rows as Items with the key figure on the end edge.

### Dark

- `@custom-variant dark (&:is(.dark *))` and one token set under `.dark`. shadcn's dark set raises `--card` and `--popover` by lightness and draws `--border` as a white alpha, which is `material.md`'s dark surface already written. Keep it, and never patch a component with `dark:` where a token would flip.

Two cautions. shadcn edits its components in place, and a copied file stays as edited until one of the three overwriting commands above runs, so the installed `components/ui` is the truth. This reference is a map read on 2026-09-22 from the shadcn docs and the `base-nova` registry, Tailwind CSS 4.3.3 and lucide-react 1.31, and checked on 2026-09-29 against the shadcn source; `npx shadcn@latest docs <component>` prints the URLs of a part's docs, examples and API reference, which hold its current composition, and `npx shadcn@latest info` names the style and base a repo runs. And every verdict here is about a default: a Sheet rebuilt as a non-modal pane that grows from its trigger is no longer the Sheet rejected above, and a Card with its ring gone is no longer a box.
