# Translate a rendered UI into Paper

For authoring a board from a product that runs. Read the rendered UI, translate it into the HTML `write_html` accepts, and bind the values to tokens. The goal is a board that matches the product, and that reads back into code the way the product is built. Lines marked _tested_ were run live on 2026-09-24.

## 1 · Read the rendered UI, never the source

Web. Open the route at the board's viewport in a headless browser, and evaluate the snippet below with the screen's root selector. It returns the page's CSS variables and, for every visible element: its box relative to the root, its non-default layout and paint styles, its text with its text style, its `::before` and `::after` content, and inline SVG. Computed values arrive resolved: `rem`, `em`, `calc()` and `var()` come back as px and colours, grid tracks as px. _Tested._

```js
(() => {
  const root = document.querySelector("#app"); // the screen's root selector
  const origin = root.getBoundingClientRect();
  const DEFAULTS = {
    display: "",
    flexDirection: "row",
    flexWrap: "nowrap",
    rowGap: "normal",
    columnGap: "normal",
    alignItems: "normal",
    justifyContent: "normal",
    alignSelf: "auto",
    flexGrow: "0",
    flexShrink: "1",
    flexBasis: "auto",
    gridTemplateColumns: "none",
    position: "static",
    top: "auto",
    left: "auto",
    minWidth: "auto",
    maxWidth: "none",
    paddingTop: "0px",
    paddingRight: "0px",
    paddingBottom: "0px",
    paddingLeft: "0px",
    marginTop: "0px",
    marginRight: "0px",
    marginBottom: "0px",
    marginLeft: "0px",
    backgroundColor: "rgba(0, 0, 0, 0)",
    backgroundImage: "none",
    borderTopWidth: "0px",
    borderRadius: "0px",
    boxShadow: "none",
    opacity: "1",
    overflow: "visible",
  };
  const TEXT = [
    "color",
    "fontFamily",
    "fontSize",
    "fontWeight",
    "lineHeight",
    "letterSpacing",
    "textTransform",
    "textAlign",
  ];
  const pick = (cs, keys, all) =>
    Object.fromEntries(
      keys.map((k) => [k, cs[k]]).filter(([k, v]) => all || (v !== DEFAULTS[k] && !(k === "minWidth" && v === "0px"))),
    );
  const walk = (el) => {
    const cs = getComputedStyle(el);
    if (cs.display === "none" || cs.visibility === "hidden") return null;
    const r = el.getBoundingClientRect();
    const node = {
      tag: el.localName,
      box: [r.x - origin.x, r.y - origin.y, r.width, r.height].map(Math.round),
      style: pick(cs, Object.keys(DEFAULTS)),
    };
    const label =
      el.getAttribute("aria-label") ||
      el.dataset.testid ||
      (typeof el.className === "string" && el.className.split(" ")[0]);
    if (label) node.name = label;
    const text = [...el.childNodes]
      .filter((n) => n.nodeType === 3)
      .map((n) => n.textContent.trim())
      .filter(Boolean)
      .join(" ");
    if (text) Object.assign(node, { text, textStyle: pick(cs, TEXT, true) });
    const pseudo = ["::before", "::after"]
      .map((at) => [at, getComputedStyle(el, at)])
      .filter(([, p]) => !["none", "normal"].includes(p.content))
      .map(([at, p]) => ({ at, content: p.content, color: p.color, marginRight: p.marginRight }));
    if (pseudo.length) node.pseudo = pseudo;
    if (el.localName === "svg") return Object.assign(node, { svg: el.outerHTML });
    const children = [...el.children].map(walk).filter(Boolean);
    if (children.length) node.children = children;
    return node;
  };
  const rootStyle = getComputedStyle(document.documentElement);
  const vars = Object.fromEntries(
    [...rootStyle].filter((k) => k.startsWith("--")).map((k) => [k, rootStyle.getPropertyValue(k).trim()]),
  );
  return JSON.stringify({ viewport: [innerWidth, innerHeight], vars, tree: walk(root) });
})();
```

- Values come from the output, never from a screenshot. The box gives the geometry; the style gives the values.
- A real screen returns a lot. Run it per section — header, list, dock — and author that section.

Native. There is no DOM, so the two halves come from two places.

- Styles and spacing come from the theme and the view code: asset catalogs and `Color`/`Font` extensions in Swift, `MaterialTheme` and modifiers in Compose, `StyleSheet` and theme objects in React Native.
- Frames come from the platform's inspector: `adb shell uiautomator dump` lists every Android view's bounds in pixels (divide by the density for dp); on iOS, the Xcode view debugger or an XCUITest element's `frame`.
- A React Native app that also builds for the web takes the web path.
- Verify with a simulator screenshot at the board's viewport, side by side (`review.md`, Checking an implementation). A screenshot verifies; it never measures.

## 2 · Translate to what Paper accepts

`write_html` forbids `margin`, `display: grid`, `display: inline` and tables, yet stores them without an error. _Tested._ Nothing warns you, so translate before writing; audit C6 finds what slipped through.

- `margin` → the parent's `gap` between siblings, or the parent's padding at its edges. `margin: 0 auto` → the parent's `justify-content: center`, or `align-self: center`. A negative margin → `position: absolute` for decoration, or a restructure.
- `display: grid` → flex. The rows become a column of flex rows. Equal tracks (`1fr 1fr`) → children with `flex: 1`. Fixed tracks → `width` plus `flex-shrink: 0`. A wrapping card grid → `flex-wrap: wrap` with the resolved track width on each child. A spanning cell → a nested group.
- `display: inline`, `inline-block` or `inline-flex` on a container → `display: flex` in a row with `align-items: center`. Paper gives text nodes `inline-block` on its own; that is not a defect.
- Mixed-style runs (`Pay <strong>now</strong>`) → Paper has no rich text. A `<p>` holding a `<strong>` flattens into one text node and loses the bold. _Tested._ When the emphasis matters, split the run into sibling text nodes in a `flex-wrap: wrap` row; otherwise keep one style.
- `<table>` → a column of flex rows. Every cell is a fixed-width slot (`width` plus `flex-shrink: 0`), the last one `flex: 1` (L7).
- `<input>`, `<button>`, `<select>` → divs. Paper keeps an input's placeholder as text at 50% opacity and drops the chrome of both. _Tested._ Write the border, background, padding and text explicitly.
- `::before` and `::after` → a real element in that position: a bullet, an icon, a divider.
- `currentColor` in an SVG → set `fill` or `stroke` to `var(--token)`. `currentColor` renders black. _Tested._
- An SVG sprite (`<use href="#id">`) → inline the symbol's paths.
- `position: fixed` or `sticky` → the last child of a flex-column artboard, with the scrolling area before it at `flex: 1`; or `position: absolute` at the edge.
- A scroll area → `overflow: clip` at the fold. The scrolled state is another board.
- `line-height: normal` → px: the box height of one line in the snippet's output. A unitless line height → px; Paper stores it as a percentage.
- Works as written: `text-overflow: ellipsis` (stored as a one-line clamp), `rotate`, `aspect-ratio`, `outline` with `outline-offset`, `flex-wrap`, `min-width`, `max-width` and percentage widths. _Tested._

## 3 · Sizing intent: fill, hug or fixed

A board read back into code gives exactly the sizes it was written with. Write the intent, not the pixels.

- Fill — `flex: 1` along the parent's axis, `align-self: stretch` across it, or `width: 100%`. A page's content column, a list row, a field.
- Hug — no width; the content sizes it. A button, a chip, a label.
- Fixed — `width` and `height` in px with `flex-shrink: 0`. Only where the product is fixed: an icon, an avatar, a control with a set size, the artboard itself.
- Limits — `min-width` and `max-width` wherever the code has them. A page column capped at 1200px carries `max-width: 1200px`.
- Read the intent from the snippet's `flexGrow`, `alignSelf` and `maxWidth`, or from the code's CSS. Never from the box: it reports every size as resolved pixels.

## 4 · Values to tokens

- A value that matches a token binds to it, as `var(--token)`.
- In a mirrored file, the token descriptions are the map between the two naming schemes. Each starts with `code: <path>#<name>`: `code: src/styles/theme.css#--brand-500`, `code: tailwind.config.ts#colors.primary.DEFAULT`. Match a computed value to the snippet's `vars`, then the variable to the token whose description names it.
- A value with no token: in a mirrored file, Paper's tokens mirror the code's, so a value the code hardcodes stays a literal and is a finding for the code, and a wave 2 agent reports a missing token to wave 1 instead of creating it (`code-to-design.md`). In a design-led file, a value that appears twice becomes a token (L6).
