# Material

Law 16 rules depth. This sheet carries its values: the elevation levels and their stacking bands, the shadow for each, the escalation from tone to hairline to border, transparency, the concentric radius sum, and what a dark surface spends instead of shadow.

## Elevation

One scale per surface. Five levels is the whole vocabulary, and a level exists only where a real stacking relationship exists.

- Level 0 — the page. No shadow, no ring. The background every other level is measured against.
- Level 1 — the resting object: a card, an input. A hairline ring and the faintest shadow, nothing more.
- Level 2 — the persistent floating layer: a sticky header, a toolbar, a non-modal drawer. Content scrolls under it.
- Level 3 — the transient overlay: a dropdown, a popover, a tooltip. It sits above whatever opened it and closes on Escape, so it reads as temporary rather than as structure.
- Level 4 — the blocking layer: a dialog, a sheet. It pairs with a scrim, and only its own overlays sit above it.

A level is a height, not a style. Two objects at the same height take the same shadow, the same ring and the same radius logic, and a difference between them means a difference in height.

Each level owns one stacking band, set as a token, and no `z-index` sits outside the bands. Levels 0 and 1 stay in the flow. Level 2 takes 10, level 4 takes 40, and level 3 takes 50, so a menu opened inside a dialog still clears it. A toast takes 60. An overlay renders outside any ancestor that clips or transforms it, through a portal, because `overflow: hidden` cuts it off and a transformed ancestor re-anchors `position: fixed` to itself.

## Shadow

One light source per surface, placed above and slightly forward. Every shadow on that surface travels down the block axis only. A shadow with a horizontal offset on one object and none on its neighbor describes two suns.

A single blurred shadow reads as cheap because a real object casts two: a tight contact shadow where it meets the surface, and a wide ambient one that falls off slowly. One blur radius gives neither shape. The recipe is a 1px ring, a key shadow with a short offset and a negative spread, and an ambient shadow with a long offset and a wide blur.

- Level 1 — `0 0 0 1px oklch(0 0 0 / 0.06), 0 1px 2px -1px oklch(0 0 0 / 0.06), 0 2px 4px 0 oklch(0 0 0 / 0.04)`
- Level 2 — `0 0 0 1px oklch(0 0 0 / 0.06), 0 4px 6px -2px oklch(0 0 0 / 0.08), 0 12px 16px -4px oklch(0 0 0 / 0.06)`
- Level 3 — `0 0 0 1px oklch(0 0 0 / 0.06), 0 8px 10px -4px oklch(0 0 0 / 0.10), 0 20px 28px -8px oklch(0 0 0 / 0.08)`
- Level 4 — `0 0 0 1px oklch(0 0 0 / 0.06), 0 16px 20px -8px oklch(0 0 0 / 0.12), 0 32px 48px -12px oklch(0 0 0 / 0.10)`

Offset and blur grow together as the level rises, because a higher object casts a longer, softer shadow. Alpha rises with them, since the ambient shadow of a high object covers more ground and needs to stay visible. A larger surface reads as thicker at the same level: raise the blur, not the alpha.

Hover lifts within a level rather than to the next one. Raise each alpha by about `0.02` and leave the geometry alone, then transition `box-shadow` over `150ms ease`. Animating the shadow costs a repaint of the whole box, so a surface that lifts constantly animates `opacity` on a duplicate shadow layer instead.

Shadow is depth. A divider is layout. A `border-block-end` between list items, a table cell boundary and a hairline in dense UI sit at level 0, where Law 5's escalation already puts a line before a shadow.

## Border and tone

Escalate in Law 5's order, one step at a time. A tone step is a background one or two steps along the neutral ramp, and it separates two regions with no ink at all. A hairline is the next step. A full border is the last, and Law 4 has already asked whether the enclosure earns it.

Alpha beats a solid color for every ring and every hairline. `oklch(0 0 0 / 0.1)` sits correctly over a white panel, a tinted panel, a photograph and a gradient. A solid `#e5e7eb` was picked against one background and reads as grime against the next. Black alpha over light and white alpha over dark inherit whatever tint sits beneath them, so the ring stays inside the palette Law 11 sets without carrying a hue of its own.

Draw a hairline with `outline: 1px solid oklch(0 0 0 / 0.1)` and `outline-offset: -1px`. An outline adds no width or height at any offset and follows `border-radius`, so a ring can be added to a laid-out box without moving anything. A `border` changes the box, so it belongs where the line is part of the structure.

An image takes the same inset hairline, `oklch(0 0 0 / 0.1)` in light and `oklch(1 0 0 / 0.1)` in dark, so a photograph whose edge matches the page keeps its boundary. A near-black neutral there reads as dirt on the edge.

An inner highlight puts the light source back on the top edge: `inset 0 1px 0 0 oklch(1 0 0 / 0.08)` on a raised surface, and the same over a translucent one where the bright edge reads as light catching the material. One highlight per surface, on the edge nearest the light.

Hairlines render badly at fractional device pixel ratios. At `devicePixelRatio` 1.5 a 1px line snaps to 1 or 2 device pixels depending on where the box lands, so two identical rows can show two different weights. Declare hairlines in `px` and never in `rem`, since a scaled `rem` hairline lands between device pixels at every zoom step. A sub-pixel width such as `0.5px` rounds to zero in some engines and vanishes, so hold 1px and lower the alpha instead.

## Transparency and blur

`backdrop-filter: blur(20px) saturate(180%)` with a background of `oklch(1 0 0 / 0.6)` is the working default for light chrome, and `oklch(0.2 0 0 / 0.6)` for dark. Saturation compensates for the wash the blur leaves behind. Keep the blur radius at or under 20px: the filter samples every pixel behind the box on every frame, and the cost climbs with the radius and with the area.

Glass needs something behind it. A translucent bar works when content scrolls under it and the blur has real material to chew on. The same bar over a flat fill is an opaque panel that costs a compositor layer, so make it opaque and take the frame back. Never stack one light translucent surface on another; the second one has only the first one's haze to sample and legibility collapses.

Over an unknown backdrop, contrast is not one number. It varies continuously across the surface, so measure the worst region rather than the average. Where the worst region fails, raise the background alpha toward `0.85` until it holds, or put a scrim behind the text. Text on glass runs one weight heavier with a small positive `letter-spacing`, and color sits on the solid layer beneath rather than on the translucent foreground.

A scrim is a flat dim, not a blur: `oklch(0 0 0 / 0.4)` behind a level 4 dialog. A blocking layer takes one. A parallel non-blocking panel takes translucency and an offset with no scrim, because dimming the page behind it breaks a flow the user has not left. A decorative scrim takes `pointer-events: none` and `aria-hidden="true"`; a scrim that dismisses on click is a control and keeps both.

Two environments delete the effect. Under `prefers-reduced-transparency: reduce`, set an opaque background and `backdrop-filter: none`. Under `forced-colors: active`, the filter is dropped by the engine, so the surface needs a `Canvas` background and a real border in a system color or it merges with whatever is behind it.

## Radius

Radius scales with the surface, not with the brand. A badge or chip takes 4px or a pill, an input or button 6px to 8px, a card 10px to 12px, a panel or sheet 16px to 20px, a full-bleed modal 24px or more. A pill takes `border-radius: 9999px` and belongs to a shape, not to the scale.

Concentric nesting is arithmetic. A 12px card with 4px of padding holds an 8px inner surface. Run it the other way when the inner value is fixed: outer equals inner plus inset. Past about 24px of inset the two layers no longer read as one shape, the arithmetic stops describing anything, and each radius is chosen on its own. Law 14 owns the judgement about when a nested shape is concentric at all; this sheet only supplies the sum.

## Dark surfaces

A dark surface rises by lightness. Black shadow on a near-black background is invisible, so the ambient and key layers do no work and only cost a repaint. Set a base near L `0.18` on the tinted ramp from `color.md` and add `0.02` to `0.03` of lightness per level. Levels 0 to 4 then run roughly `0.18`, `0.21`, `0.24`, `0.27`, `0.30`, and the steps stay visible because OKLCH lightness steps evenly to the eye.

The ring carries the separation that shadow carried in light. `0 0 0 1px oklch(1 0 0 / 0.08)` at rest, `0 0 0 1px oklch(1 0 0 / 0.13)` on hover, with no key or ambient layer behind it. Keep one soft ambient shadow only under level 4, where a dialog needs to detach from a dimmed page.

One token name, two values. `--elevation-2` resolves to the three-layer shadow in light and to the white ring plus a lighter surface color in dark, and no component ever branches on theme. A dark theme built by inverting a light one inherits the light theme's shadows, which is Law 11's inverted-theme failure arriving as depth.

Alpha compounds. Three nested surfaces each carrying a `0.06` ring stack to a visible gray seam at every boundary, and the ring that read as a hairline in isolation reads as a border in the nest. Drop the ring from the inner surfaces and let tone separate them, which is the escalation running backwards and the right direction here.
