# Typography

Laws 14 and 15 rule the scale and the type. This sheet carries their numbers: ratios, roles, measure, leading, tracking, figures, wrapping, the icons that sit with text for Laws 17 and 22, and the WCAG floors.

## Scale

- A scale is one ratio applied repeatedly from a base of `1rem`, which is the browser default of 16px until the reader changes it.
- Useful ratios: 1.125 major second, 1.2 minor third, 1.25 major third, 1.333 perfect fourth, 1.5 perfect fifth. Below 1.125 adjacent steps stop reading as different; above 1.5 the middle of the scale empties out.
- One ratio rarely covers both ends. A common split runs about 1.125 through the UI sizes and 1.333 to 1.5 above them, as the table below does, so small steps stay usable and display steps stay separated.
- Five to seven steps cover a product surface. Each step carries a size, a line-height and a weight, so picking a role is one decision rather than three.

| Role    | Size               | Line-height | Weight |
| ------- | ------------------ | ----------- | ------ |
| Display | `2.25rem` (36px)   | `1.1`       | `600`  |
| Title   | `1.5rem` (24px)    | `1.2`       | `600`  |
| Heading | `1.125rem` (18px)  | `1.3`       | `600`  |
| Body    | `1rem` (16px)      | `1.5`       | `400`  |
| Caption | `0.8125rem` (13px) | `1.4`       | `400`  |

- Round every computed step to `0.0625rem`, which is 1px at the default root. An unrounded `1.2601rem` renders at a subpixel and buys nothing.
- Headings map to descending steps. Two adjacent levels may share a step at the small end when weight or tracking keeps them apart.
- Emphasis inside a role is a weight change, `400` to `600`. It is not a size change.
- Fluid steps use `clamp(min, intercept + slope * 1vw, max)`. Slope is `(max − min) / (maxViewport − minViewport)` expressed in `vw`; intercept is `min − slope × minViewport`.
- Worked: `1.5rem` at a 320px viewport up to `2.25rem` at 960px is `clamp(1.5rem, 1.125rem + 1.875vw, 2.25rem)`.
- The `rem` term in that expression is load-bearing. A `clamp()` built from `vw` alone ignores the reader's browser font size and fails SC 1.4.4.

## Measure and leading

- Long-form body runs 60 to 75 characters per line. `max-inline-size: 65ch` measures it directly, one `ch` being the advance of `0` in the current font.
- At a `1rem` body size that range lands near 560px to 680px, and it moves when the family or the size moves. Recheck it after either changes.
- Display and headings run shorter, 20 to 40 characters, which is one to three balanced lines.
- Line-height falls as size rises, and the values are unitless so they scale with `font-size`. A fixed `24px` does not.
- `2rem` and above: `1.05` to `1.15`. `1.5rem` to `2rem`: `1.2`. `1.125rem` to `1.5rem`: `1.3`. Body at `1rem`: `1.5` to `1.6`. Captions at `0.8125rem`: `1.4`.
- Any text that wraps to three or more lines takes at least `1.4`, whatever its size and however tight the row.
- Paragraph gap is roughly one line: `margin-block-end: 1em` measured in the paragraph's own em, so it tracks the size.
- Space above a heading runs about twice the space below it — `margin-block-start` near `1.5em` against a `margin-block-end` near `0.5em`, in the heading's em.
- Those gaps are measured to the box, not the ink. `text-box: trim-both cap alphabetic` removes the font's reserved leading so the rendered gap matches the number. Chromium 133+ and Safari 18.2+, not Firefox, so unsupported browsers keep the default leading.

## Weight, tracking and optical size

- Tracking tightens as size rises. `3rem` and above: `-0.03em` to `-0.02em`. `1.5rem` to `3rem`: `-0.02em` to `-0.01em`. `1rem` to `1.5rem`: `-0.01em` to `0`.
- Body at reading sizes takes `0`. Negative tracking on a wrapping paragraph costs legibility and returns nothing.
- Uppercase belongs to two places: a pane's small section label and a chip's tag of four characters or fewer. A heading, a button and a sentence stay in sentence case.
- Uppercase labels below `0.875rem` take `0.04em` to `0.08em`, commonly `0.05em`, because uppercase forms carry no lowercase sidebearings.
- Weight below `1.125rem` (18px) stays at `400` or heavier. Weights `100` to `300` are display-only at `1.75rem` (28px) and up, and they still need checking against the background there.
- A pairing of `400` body with `600` headings separates cleanly. `400` against `500` does not, and reads as a rendering accident.
- Set common axes through their properties: `font-weight: 650` for `wght`, `font-optical-sizing: auto` for `opsz`, `font-stretch` for `wdth`, `font-style: oblique 10deg` for `slnt`.
- A property survives a non-variable fallback. `font-variation-settings: "wght" 650` silently does nothing there, so reserve raw tags for custom axes such as `"GRAD" 80`.
- `opsz` is what makes one family cover both ends: the same file thickens hairlines and opens spacing at text sizes, then refines both at display sizes. Families without the axis ship the split as separate Text and Display files.
- Inter — SIL OFL 1.1 — exposes `wght` and `opsz` only, which is typical; a font supports the axes its designer drew and no others.
- Kerning is on by default and adjusts specific pairs. `font-kerning: none` is a deliberate act, not a reset.
- Prefer the `font-synthesis-weight` and `font-synthesis-style` longhands over `font-synthesis: none`. The shorthand also kills small-cap, superscript and subscript synthesis, which erases emphasis instead of reporting it.

## Figures and tables

- `font-variant-numeric: tabular-nums` (OpenType `tnum`) fixes every digit to one advance width. Apply it to any value that changes or that sits in a compared column: timers, counters, prices, percentages, table cells.
- Proportional figures are the default and belong in prose, where fixed digit widths open visible gaps. A phone number, a postcode, a version or an ID is read as a string, not compared by place value, so it keeps them too.
- `font-variant-numeric: lining-nums` (`lnum`) keeps digits at cap height for interface text. `oldstyle-nums` (`onum`) lets them sit on the baseline with ascenders and descenders, which suits running editorial prose only.
- `font-variant-numeric: slashed-zero` (`zero`) separates `0` from `O` in IDs, codes, hashes and license keys.
- `font-variant-numeric: diagonal-fractions` (`frac`) draws a real fraction instead of stacking a slash between two full-size digits.
- Reach a numeric feature through `font-variant-numeric`, never `font-feature-settings`, because each `font-feature-settings` declaration replaces every feature it does not repeat.
- Compared numbers hang from the end edge: `text-align: end` on the cell and on its header together, so the header never drifts off its column.
- Decimal alignment has no shipped implementation. `text-align: <string>` is defined in CSS Text Level 4 and implemented nowhere, so fix the decimal count instead with `Intl.NumberFormat` and `minimumFractionDigits`, then end-align.
- A monospace family gives equal digit widths when the text family ships no `tnum`. It changes the voice of the column, so it is a fallback, not a first move.

## Wrapping and punctuation

- `text-wrap: balance` evens the line lengths of a short block. Chromium caps it at six lines and ignores it past that, which is why it belongs on headings and not on paragraphs.
- `text-wrap: pretty` stops a single word landing alone on the last line. It is the screen answer for descriptions and long-form.
- The CSS `orphans` and `widows` properties default to `2` but apply only to fragmented contexts — print, paged media, multicol. They do nothing in continuous flow.
- `overflow-wrap: break-word` keeps a long URL, token or ID inside its container. `white-space: nowrap` keeps a label or badge on one line.
- `hyphens: auto` needs a correct `lang` attribute or the browser has no dictionary to break against. `hyphenate-limit-chars: 6 3 3` stops two-letter fragments.
- `&shy;` (U+00AD) marks where one long word may break. `&#8209;` (U+2011) is a non-breaking hyphen for a compound that must stay whole.
- `&nbsp;` (U+00A0) joins a number to its unit, a figure to its currency, and a short final word to the one before it.
- Punctuation by code point: en dash U+2013 for ranges, em dash U+2014 for an aside, single ellipsis U+2026 rather than three periods, minus sign U+2212 for a negative number, curly quotes U+2018 U+2019 U+201C U+201D in prose.
- Straight quotes stay in code, where the character is the syntax.
- `text-transform` presents a case change without rewriting the stored string, so the value a search index, a screen reader and a translation see stays in natural case.
- `text-align: justify` stretches word spaces until both edges line up, and with no hyphenation it opens rivers through the measure Law 15 caps.
- Truncation is `text-overflow: ellipsis` with `overflow: hidden` and `white-space: nowrap` for one line, `line-clamp` for several. Both hide content, so the full value stays reachable.

## Icons beside text

- An icon takes its size from the text it sits with, `1em` to `1.25em` of it, drawn on the family's native grid of 16, 20 or 24 so strokes land on whole pixels.
- Stroke tracks the weight of that text, in units of a 24-unit viewBox: `1.5` beside regular `400` text, `2` beside `500` to `600`, `2.5` beside `700`. One family at one grid stays one family across all three.
- Outline is the resting form and filled the active one, where the set ships both. That pair is a state, not a second family.
- A glyph's ink, not its box, sets the padding. Beside a label inside a button, the icon side takes about 2px less padding than the text side. A play triangle shifts about 2px toward its point; better, the SVG draws it centered by mass.

## Floors

- Long-form body starts at `1rem` (16px). Interface text starts near `0.875rem` (14px), captions at `0.8125rem` (13px), and rarely goes below `0.75rem` (12px).
- iOS Safari zooms the page when an input's text renders below 16px. Hold the input at `1rem`, or keep `font-size: 16px` and scale the box down with a compensated width and line-height.
- WCAG 2.2 SC 1.4.3 sets 4.5:1 for text and 3:1 for large text, where large is 18pt (24px) or 14pt (18.66px) bold. SC 1.4.6 raises those to 7:1 and 4.5:1 at AAA.
- SC 1.4.4 requires text to resize to 200% with no loss of content or function. Test at 200% browser zoom and again at a 32px root font size, since the two exercise different code paths.
- SC 1.4.12 requires no loss of content at `line-height: 1.5`, paragraph spacing of 2× the font size, `letter-spacing: 0.12em` and `word-spacing: 0.16em`. A fixed-height row fails it before anything else does.
- Sizing in `rem` inherits the reader's setting. `html { font-size: 16px }` overrides it and removes the preference from the page.
- `user-select: none` removes selection. A drag or gesture surface needs it; running text loses the reader's ability to copy, quote and look up.
- SC 1.4.5 bars images of text at AA where real text can do the job, and SC 1.4.9 closes the remaining exceptions at AAA. Real text stays searchable, translatable, resizable and selectable; a picture of text is none of those.
- `lang` drives hyphenation, quote marks and pronunciation. `dir` set at the boundary where direction changes, with `<bdi>` isolating a mixed-direction value, keeps digit order intact.

Two cautions. Every value on this sheet is a starting point checked against a rendered page, never a substitute for one: wrapping, widows, truncation and the real character count only appear at real content lengths, and a computed style proves none of them. And support is uneven at the edges — `text-box` misses Firefox, `text-wrap: pretty` and `balance` differ in how many lines each engine will treat, and `text-align: <string>` exists only on paper, so each is progressive enhancement over a layout that already holds without it.
