# States

Law 12 rules the hidden layer, Law 13 the rung each piece sits on, Law 21 the widths and the targets. This sheet is the inventory a review exercises: the states a region owes, the data shapes that break it, the widths, inputs and environments that reach it, the numbers a target and a focus ring have to clear, and the evidence that proves each row.

## States

- Rest — the surface before anything happens, and the baseline every other state is judged against.
- Hover — gate it behind `@media (hover: hover)`. On touch `:hover` latches after a tap and holds until the user taps elsewhere, so it reads as a stuck selection.
- Focus — programmatic focus on the control. A wrapper lights up through `:focus-within` when the input inside it is the thing focused.
- Focus-visible — the ring the engine shows for keyboard and assistive technology and suppresses for a mouse click. Style `:focus-visible`, never bare `:focus`, and never write `outline: none` without a visible replacement. The ring appears on the frame focus lands and never transitions in.
- Active — the frame between pointer down and commit. Missing here, a control feels dead on a slow network.
- Selected — carried by `aria-selected` or `aria-checked`. A selected default still needs its selection cue even though Law 9 mutes it.
- Disabled — where contrast collapses first. `disabled` removes the control from the tab order and from copy; a control that must stay reachable uses `aria-disabled` and explains why it cannot act. A tooltip on a natively disabled control never opens for keyboard or touch, so a control that explains itself is `aria-disabled`.
- Read-only — the value is present and editing is closed. `readonly` keeps focus, selection and copy where `disabled` takes all three.
- Loading — a skeleton at the region's real size, or a spinner beside the original label, with `aria-busy="true"` on the region while it fills. A bare spinner replacing a label leaves assistive technology with no name for what is busy.
- Empty — zero items, with a message and the action that fills it.
- Partial — some of the data arrived and some failed. It belongs to the region, not to the page.
- Error — inline beside the field, with `aria-invalid="true"` and `aria-describedby` pointing at the message, and the message names how to recover. A red border alone carries meaning in color alone.
- Success — announced through a polite live region. A confirmation carrying the only undo link never expires on a timer.
- Offline — the queued write, the retry and the marker that says the view is not live.
- Stale — data still rendered after its refresh failed. It says how old it is.
- First-run — one pointer at one action, then the next, which is Law 13's ladder running in time.
- Announcement — a banner, a badge or a what's-new. Each is a region with its own spine, and each is dismissible.

Every interactive region owes rest, hover, focus-visible and disabled. What it owes beyond that comes from what it holds:

| Region                                 | States it also owes                                           |
| -------------------------------------- | ------------------------------------------------------------- |
| Collection: table, list, grid          | Empty, one item, many, loading, partial, stale                |
| Form field                             | Active, error, success, read-only, disabled with a reason     |
| Async action: button, form submit      | Active, loading with the label kept, error, success           |
| Overlay: menu, popover, dialog, drawer | Selected, first-run, and the dismissal that returns focus     |
| Disclosure: accordion, collapsible     | Open and closed, carried by `aria-expanded` on the trigger    |
| Chart or map                           | Empty, loading, partial, stale, and the non-visual equivalent |

## Data edges

- Zero items, and the empty state that has to exist for them.
- One item, against a grid or a layout composed around plural content.
- Two items, where a layout that works at one and at many still splits badly.
- Ten times the realistic count, for missing pagination, an unsticking sticky header and a collapse in render time.
- Truncation, where one long cell must lose its tail so its siblings keep their edges, which is Law 3.
- One unbroken string with no wrap opportunity: a 60-character URL, or `Donaudampfschiffahrtsgesellschaft`.
- A very large number, a negative one, a zero and a null, each distinct on screen. Columns that align use `font-variant-numeric: tabular-nums`.
- A missing image, where a broken `src` leaves alt text sitting in a box sized for a picture. Every image declares its `width` and `height` or an `aspect-ratio`, so its box is held before it loads, and its alt text is its meaning or empty when it is decoration.
- Mixed-direction text: an LTR product name inside an RTL sentence, and an RTL name inside an LTR one.
- Emoji alone and mixed into a line, for the line-height jump and the truncation that splits a character.
- Diacritics and tall scripts, where a tight line-height or an `overflow: hidden` row clips the ascenders.

## Widths

320 CSS px is the floor. WCAG 2.2 SC 1.4.10 asks for reflow with vertical scrolling only at a viewport equivalent to 320 CSS px wide, which is 400% zoom on a 1280px viewport. Content read across both axes is the exception: a data grid, a map or a code block scrolls inside its own container rather than scrolling the page. A table read row by row changes vessel instead, per Law 21.

Container widths are the real test, because a region reflows on its own width and not the viewport's. Exercise a 320px container, the region squeezed by a flex or grid sibling until `min-content` blows the layout out, a narrow middle width where the vessel has to change, and a very wide one where the measure runs unbounded and the controls stretch. Render each as a fixed container on one page. Resizing the window scenario by scenario observes a different set of regions each time.

200% zoom is SC 1.4.4, and all content and functionality survives it with the page still zoomable. Enlarged system text is the same width in another costume: a larger base font size pushes text past a fixed `height` first, so anything holding text takes `min-height` and grows. A breakpoint declared in `rem` or `em` switches when the text needs it; the same breakpoint in `px` never does. A viewport meta tag carrying `user-scalable=no` or a `maximum-scale` takes pinch zoom away, so it never ships.

Viewport units lie at the edges. `100vw` includes the scrollbar gutter, so a full-bleed `100vw` block overflows by the scrollbar's width; take `100%` of a full-width parent. `100vh` on a phone runs under the browser's own bars; `dvh` follows them and `svh` holds the smallest height. A scroll container that cuts off its content lets the next item peek 16px to 32px past the edge, so the scroll reads as possible.

## Inputs

Keyboard — DOM order, reading order and tab order stay identical at every width, and a positive `tabindex` is what breaks that match. A composite widget such as a tab list, a menu, a toolbar or a radio group occupies one tab stop and moves inside itself with arrow keys. Escape dismisses whatever opened last. A dialog traps focus, marks the background `inert`, and returns focus to the trigger on close. It opens with focus on its first field or its primary action, and a destructive confirmation opens on the least destructive one. It carries a title, visually hidden if need be, and opening it never scrolls the page behind. Where its content scrolls, its action row stays put. Tab through a long page and every stop is visible and reachable; a stop that disappears behind a sticky header is a trap with extra steps.

A native `button`, `a` or `input` brings its keyboard behavior with it. A `div` given `role="button"` owes Enter and Space, a tab stop and a name, and a menu, combobox or dialog comes from an established primitive rather than from hand-built focus code. ARIA fills what native semantics lack; where the element already says it, ARIA says it twice.

Pointer — anything that looks clickable is clickable across its whole visible extent, with no dead zone between a checkbox and its label, and nothing that is inert wears the pointer cursor. A decorative layer painted over a control absorbs every pointer event its box covers, so a gradient, a glow or a full-bleed pseudo-element takes `pointer-events: none`; an enabled control never does. A native input hidden behind a custom surface hands its focus ring to that surface through `:focus-within`.

Touch — there is no hover. An action that only appears on approach is unreachable, so it needs another rung on a touch surface. `touch-action: manipulation` removes the double-tap zoom delay on interactive elements. A surface running its own pan, zoom or drag scopes `touch-action: none` to itself and never to the page.

Screen reader — every control has an accessible name, every semantic icon has one and every decorative one is hidden. A client-side route change announces nothing on its own, so the title updates and focus moves into the new view.

The markup carries the same structure the eye sees. Headings descend without skipping a level. A view holds one `main`, each `nav` beside another takes its own `aria-label`, and a rail is a labelled `aside`. A list is a `ul` or `ol`, a data table has `th` headers and a caption, and a group of fields is a `fieldset` with a `legend`.

Announcements climb a ladder and stop at the first rung that works: move focus, then `aria-describedby`, then a polite `role="status"`, and `role="alert"` only for an interruption that cannot wait.

Forms — submit stays enabled until the request starts; validation runs on submit and moves focus to the first error. A placeholder is an example, never the label. A required field says so in its label and through `required` or `aria-required`. Fields take `autocomplete` and `inputmode`, so the browser fills them and the phone opens the right keyboard. Paste is never blocked.

Media — speech takes captions, nothing autoplays with sound, and a video holds a poster until it plays.

Voice control — a user says the visible label. Where the accessible name does not start with the visible text, the spoken command reaches nothing, so an `aria-label` that renames a visibly labelled button breaks the control it was meant to help.

## Environment

- Light and dark, each designed rather than inverted.
- `forced-colors: active`, where authored colors, background images and backdrop filters are dropped and only system colors remain.
- `prefers-contrast: more`, where the foreground and background gap widens by at least 15 points of perceived lightness, remeasured rather than judged by eye.
- `prefers-reduced-motion`, exercised as a row: every animated region rendered under the preference, checked for feedback that vanished with the movement. `motion.md` owns the implementation.
- `prefers-reduced-transparency`, where every translucent surface goes opaque and still separates.
- Locale, tested with pseudo-localization rather than a percentage budget. Short strings grow the most in proportion, so a one-word label can double where a paragraph grows by a third, and some translations run shorter.
- Number and date format, where the grouping and decimal separators swap and the date order changes. Format through `Intl`, never by concatenating parts.
- Reading direction, where the whole layout mirrors. Logical properties carry it; physical `left` and `right` do not. An icon that points along the reading line flips with it — back and forward arrows, send, a speaker's sound waves — through `scale: -1 1`. Logos, checkmarks, clocks and media playback controls never flip.

## Floors

- 24 by 24 CSS px — WCAG 2.2 SC 2.5.8, Level AA, the hard floor for a pointer target.
- 44 by 44 CSS px — SC 2.5.5, Level AAA, and the practical size for a primary touch control.
- 44 by 44 pt — the iOS and iPadOS default. 28 by 28 pt on macOS.
- 48 by 48 dp — the Android minimum.
- Spacing exception — an undersized target still passes SC 2.5.8 when a 24px circle centered on it intersects no other target and no other such circle. In the plain case, 20px targets need 4px of gap.
- Breathing room — past the floor, adjacent bordered or filled controls keep about 12px between them, and borderless text and icon controls about 24px, so a slip lands on nothing.

The visible element stays small; the hit area is what grows. Expand it with a pseudo-element on the wrapping `<label>` or `<button>`, never on the `<input>`, since a replaced element does not render `::before` or `::after` reliably. Where the box can simply be bigger, `min-width` and `min-height` with `place-items: center` hands the engine real geometry. Overlapping hit areas send a tap to whichever element paints on top, so an expanded area that collides shrinks to the largest size that does not.

A focus indicator is checked around its whole perimeter, against every color it crosses: the component fill, the page surface, an image, a gradient, and the hover and selected states underneath it. The browser's own ring adapts to the platform and to forced colors, so adding only `outline-offset: 2px` keeps that adaptation. A custom ring in `currentColor` has been checked against nothing.

A platform minimum and a WCAG criterion are separate floors, and the higher one governs. None of these rows is proved by a still image: hover, focus, disclosure, keyboard order and pointer behavior each need the interaction actually run, and a row nobody ran stays a prediction.

## Evidence

A row is proved one of three ways. A source row is a pattern that is the defect wherever it appears, confirmed by reading the code. A rendered row needs the interaction run and captured. A direction row is judged against the brief and recorded as an observation. Any browser driver does the rendered work; the capability matters, not the tool.

### Rendered

- Rest and hover — capture the region at rest, move the pointer onto the target, capture the same element again.
- Focus and keyboard order — press Tab from the top and capture after each stop. The accessibility snapshot gives the order and every name, which turns `Unlabeled`, `Nameless icon` and `Order break` from predictions into observations.
- Environments — emulate `prefers-reduced-motion`, `forced-colors`, `prefers-contrast` and `prefers-color-scheme`, then capture. Nothing emulates `prefers-reduced-transparency`, so set the opaque fallback by hand and say so.
- Widths — render each container width as a fixed box on one page, and resize the viewport to 320px wide.
- Zoom — 200% zoom is the viewport at half its width, and enlarged text is a 32px root font size. Run both.
- Touch — open in a mobile device profile, where hover does not exist.
- Data edges — intercept the request and return an empty list, one item, ten times the count, an error status, a slow response and a network failure.
- Motion — record video, since a still proves nothing about movement.
- Geometry — read bounding boxes and computed styles from the page, never from a picture, for near-misses, gaps, radii and sizes.
- A repair — capture the same element and the same accessibility snapshot before and after, and diff the snapshots.

### Source

Each pattern is a lead. The confirmed ones are the defect wherever they appear.

| Pattern                                                                        | Failure                        |
| ------------------------------------------------------------------------------ | ------------------------------ |
| `outline: none` or `outline-none` with no `:focus-visible` replacement         | `Quieted floor`, confirmed     |
| An icon-only `button` with no `aria-label` and no text                         | `Nameless icon`, confirmed     |
| `tabindex` above 0                                                             | `Order break`, confirmed       |
| `user-scalable=no` or `maximum-scale` in the viewport meta                     | Zoom, Widths above, confirmed  |
| A `placeholder` on a field with no label                                       | `Unlabeled`, confirmed         |
| A `div` or `span` with a click handler and no role, key handler or tab stop    | `Costume`, confirmed           |
| A paste handler that calls `preventDefault`                                    | Forms above, confirmed         |
| An arbitrary value such as `p-[13px]`, or a raw px value outside the scale     | `Off-scale`                    |
| `space-x-*`, `space-y-*`, or margins on the children of a flex or grid         | `Orphan inset`                 |
| A hand-written `@media` at exactly 640, 768, 1024 or 1280px inside a component | `Device breakpoint`            |
| A `z-index` outside the stacking bands in `material.md`                        | `Off-scale`                    |
| More distinct `box-shadow` values than elevation levels                        | `Flat elevation` or `Two suns` |
| More than two `font-family` values                                             | `Second family`                |
| A hardcoded `fill` or `stroke` color inside an icon SVG                        | `Mixed family`                 |
| `text-align: center` on text that is compared                                  | `Ceremonial body`              |
| Physical `margin-left`, `left` or `pl-*` in a translated layout                | Reading direction above        |
| `100vw`, `100vh` or `h-screen`                                                 | Widths above                   |
| `disabled` on a submit that waits for the form to be valid                     | Forms above                    |
| `transition: all` or `transition-all`                                          | `motion.md`                    |

Counts open a look and are never a finding on their own: six or more cards on one surface (`Box in a box`), five or more pills in one region (`Confetti`), one spacing value covering two thirds of the gaps (`Monotone gap`), and a type scale whose largest step is less than twice its smallest (`Flat field`).
