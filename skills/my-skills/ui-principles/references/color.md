# Color

Law 11 owns where color comes from and Law 9 what earns it. This sheet carries the values: category hues, status, chips, the neutral ramp, contrast, links, chart series and dark surfaces. Color is a data channel with a capacity.

## Category hues

A categorical set is six hues. Six saved views take six dots and each one is found on sight. Eight is the ceiling: past six, new hues land between existing ones, and past eight the channel is spent and the label does the work.

The six, each holding 3:1 against a white page:

- Blue — `oklch(0.546 0.245 263)` — `#2563eb`
- Purple — `oklch(0.541 0.281 293)` — `#7c3aed`
- Green — `oklch(0.627 0.194 149)` — `#16a34a`
- Red — `oklch(0.577 0.245 27)` — `#dc2626`
- Amber — `oklch(0.666 0.179 58)` — `#d97706`
- Pink — `oklch(0.592 0.249 1)` — `#db2777`

One surface carries one set. A sidebar of colored dots, a column of chips and a chart legend on the same screen draw from the same six, and the same hue means the same category in all three. Two sets on one surface make the hue mean nothing. Status is the one second set a surface may carry, because its word and glyph name it and the hue only confirms.

Hue separates a set only at equal lightness, so every member sits near L `0.58`, amber a step above. Chroma matches in proportion, not in number: each hue sits near the same share of the most chroma its angle reaches at that lightness, which is why the raw values run from `0.18` to `0.28`. Two hues within 15° of each other read as one color, so no set spends two members that close. That same equality lets a color-vision deficiency collapse red into green and blue into purple, so a set holding both of a pair gives each a second cue: a shape, a glyph or its label. A dot is 8px, and 8px of color reads as hue and nothing finer.

## Status

Status is a fixed vocabulary, not a palette choice. Six meanings, bound once, reused everywhere:

- Success, closed, healthy — green `#16a34a`
- Error, failed, overdue — red `#dc2626`
- Warning, stale, at threshold — amber `#d97706`
- Information, in progress, new — blue `#2563eb`
- Neutral, draft, idle — the ramp, no hue
- Emphasis, beta, special — purple `#7c3aed`

Neutral is a status. Draft, idle and unchanged sit on the ramp with no accent at all, which is Law 9's silent default arriving as color. A status hue on a routine state burns the one signal that says something changed.

Green and red carry a direction, so a metric that falls where falling is good takes the meaning and not the arithmetic: cost down is green. The direction is cultural too. Chinese markets, among others, read a gain in red, so gain and loss are locale tokens, never fixed hues.

A status hue means one thing everywhere. The danger hue on an action that destroys nothing spends the warning a real destructive action needs.

## Chips

A chip is three parts in one hue plus a fourth decision. Tint background, saturated text, an icon matching the text, and a border only where the chip sits on a tinted surface that swallows its own tint.

- Background — the hue near L `0.94`, chroma `0.03` to `0.06`: `#dbeafe` blue, `#dcfce7` green, `#fee2e2` red, `#ede9fe` purple, `#fce7f3` pink, `#fef3c7` amber.
- Text and icon — the same hue near L `0.52`: `#1d4ed8`, `#15803d`, `#b91c1c`, `#6d28d9`, `#be185d`, `#b45309`.
- Contrast — each pairing holds 4.5:1 or better, amber the tightest at 4.5:1, so a chip needs no second check per hue. The lightness gap between tint and text is about `0.4`.
- Border — none on a white or ramp-0 surface, where the tint is the whole boundary. On a tinted or photographic surface, the text color at 15% alpha, drawn with `material.md`'s hairline recipe.

The icon takes the chip's text color, since Law 14 gives peers in one context one color logic. A chip with a gray glyph and colored text reads as two decisions.

Chip height sits at 20px to 24px with 6px to 8px of inline padding, and the label runs one step below body size at a raised weight. On a chip, uppercase suits a short tag of four characters or fewer, and a word stays sentence case. Section labels follow `typography.md`.

A monochrome chip is the default for a closed-set value whose hue would retrieve nothing, such as a setting's current value: ramp-2 background, ramp-9 text, no hue. Hue is spent where the color is the retrieval key. An open string stays text, never a chip.

## Neutrals

The ramp is tinted toward the accent hue at chroma `0.004` to `0.010`, which is Law 11's default. A pure gray ramp at chroma `0` is a choice, not a defect. Eleven steps, lightness first:

`0.99` `0.97` `0.94` `0.90` `0.83` `0.71` `0.58` `0.47` `0.37` `0.27` `0.18`

Jobs, from step 0: page, sunken panel, hover fill, hairline and disabled fill, border, disabled text and decorative glyph, icon and control boundary, secondary text and placeholder, strong secondary, body text, heading.

Contrast against the page: body at step 9 holds about 14:1 and secondary at step 7 about 6.6:1. Step 6 holds about 4.2:1, which clears the 3:1 floor for an icon, large text at 18.66px bold or 24px regular, and a boundary a control depends on, but not 4.5:1 for a word. Step 5 falls to 2.5:1 and is decoration or disabled.

What stays on the ramp: every unchanged default, every unchecked box, every table rule, every secondary label, every disabled control, every decorative glyph and every icon that sits beside a label rather than carrying a status. A settings panel runs on the ramp, and the one blue toggle is the one setting that is on.

## Contrast

Every figure on this sheet is measured against a white page. A real foreground is measured against the surface it renders on — the chip tint, the hover fill, the sunken panel, the photograph — and a value nobody measured is never reported.

WCAG 2 is the conformance floor. APCA is the second read, because it weighs polarity and size where WCAG 2 gives one ratio. Body text holds Lc 75 at minimum and 90 by preference. Other content text holds Lc 60, a headline of 36px or more Lc 45, and placeholder text, disabled text and control boundaries Lc 30. Lc 15 is the floor for anything meant to be seen at all. Near 75% perceived lightness even black text reaches only about Lc 60, so a mid-tone surface cannot carry body text in any ink. Take APCA from Color.js, per `tools.md`.

## Links

An inline link is the accent hue at L `0.49` — `#1d4ed8` — and underlined. Underline offset `0.15em`, thickness `1px` at body size, `skip-ink: auto`.

Color alone separates a link from body text only at 3:1 between the two, and the underline is what satisfies WCAG 1.4.1 without that measurement. Hover raises the underline to `2px` and darkens to L `0.38`. Focus takes a `2px` outline at the accent with `2px` of offset, never an underline change, since the underline is already spent.

A link in a nav, a toolbar or a card title drops both the accent and the underline: it is a whole region, its interactivity is its position, and Law 10 already requires that position to show it. Visited state earns its place on document lists, where returning to an already-read item is the task.

## Chart series

A chart spends hue on series identity and lightness on time. This period runs the saturated hue; the comparison period runs the same hue washed out. One hue, two periods, no legend needed.

- This period — the category hue, stroke `2px`, full opacity.
- Comparison — the same hue angle at L `0.88`, chroma `0.06`, stroke `1.5px`: `#fecaca` against `#dc2626`, `#bfdbfe` against `#2563eb`.
- Bars — the same pair stacked, the saturated bar above the pale one, so the delta is read as a length difference and not as a number.
- Gridlines and axis — ramp step 4 for the rules, ramp step 7 for the labels. A gridline that competes with the weakest series is one step too dark.

Label each line directly rather than through a legend. Six series is the ceiling; past six, group the tail into one ramp-6 band and name it.

A series a user must identify holds 3:1 against the plot background. A pale comparison line is exempt, because it is read as the ghost of the line above it and never on its own.

The hovered series holds its color while the rest drop to 40% opacity, which is Law 8's recede-the-neighbors at chart scale.

## Dark surfaces

Hue inverts differently from surface. Lightness rises and chroma falls, because a saturated accent on a dark ground vibrates and a washed one disappears.

- Accent — L `0.55` becomes L `0.72`, chroma drops by about a third: `#2563eb` becomes `oklch(0.72 0.16 263)`.
- Chip — tint becomes the hue near L `0.28`, text the hue near L `0.82`. The gap widens to about `0.5`, and every pair clears 8:1.
- Link — L `0.75`, underline unchanged. A light-mode link color on a dark ground fails the floor.
- Chart comparison — the ghost darkens rather than lightens. Series at L `0.72`, comparison at L `0.42`, chroma `0.06`.
- Status — the same six meanings at the same six hue angles. Only lightness and chroma move.

The ramp flips its lightness order and keeps its tint, so the palette Law 11 sets holds in both themes. Surface lightness per elevation level sits in `material.md`, where one token resolves to two values and no component branches on theme.
