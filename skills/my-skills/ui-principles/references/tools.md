# Tools

Every entry was verified: the URL loaded, the license read from the repo or the package, never guessed. Anything that is not open source says so. A tool produces the artifact or the evidence a Law asks for; the judgement stays with the reviewer.

## Law 11 — Color

- Material Color Utilities — https://github.com/material-foundation/material-color-utilities — Apache-2.0 — quantizes a source image into a ranked palette, then builds tonal ramps and light and dark schemes in HCT.
- node-vibrant — https://github.com/Vibrant-Colors/node-vibrant — MIT, declared in package metadata with no LICENSE file at the repo root — pulls vibrant, muted and dark swatches with matching text colors out of any image.
- Coolors — https://coolors.co/ — NOT OPEN SOURCE, free tier caps saved palettes — image-to-palette picker and generator.
- culori — https://culorijs.org/ — MIT — CSS Color Level 4 math in OKLCH, OKLab and Lab, for a ramp that steps evenly to the eye rather than to the number.
- Adobe Leonardo — https://github.com/adobe/leonardo — Apache-2.0 — generates a scale backwards from target contrast ratios instead of auditing one afterwards; WCAG 2 only, no APCA.
- Open Color — https://yeun.github.io/open-color/ — MIT — 13 hues by 10 steps tuned for interface work; a static palette file, dormant since 2023-12 and none the worse for it.
- Radix Colors — https://www.radix-ui.com/colors — MIT — 12 steps where each step has a fixed job, with dark, alpha and P3 variants; plain CSS and hex, not bound to React.
- Tailwind color palette — https://tailwindcss.com/docs/colors — MIT — 24 families by 11 shades authored in OKLCH; the raw `oklch()` values copy out and carry no framework with them.
- Color.js — https://colorjs.io/ — MIT — computes WCAG 2 and APCA contrast from one library, by the editors of the CSS Color spec.
- colour-science — https://www.colour-science.org/ — BSD-3-Clause — scriptable color-vision-deficiency simulation through the Machado 2009 matrices.

Two cautions. The reference APCA implementation, `apca-w3`, is not open source: its license reads All Rights Reserved and restricts use to WCAG work, so take APCA from Color.js instead. And Law 10's rule against meaning in color alone barely automates — axe's `link-in-text-block` is the one mainstream check for WCAG 1.4.1, so status chips, chart series and required-field marks still need a human pass or a second cue.

## Law 17 — Icons

- Lucide — https://lucide.dev — ISC — 1,853 icons on one 24px grid at one 2px centered stroke; the default when one family is the whole requirement.
- Tabler Icons — https://tabler.io/icons — MIT — 6,202 icons on a 24px grid at 2px, outline and filled; the largest single family.
- Phosphor Icons — https://phosphoricons.com — MIT — six weights including duotone, drawn at 16px; pick one weight and never mix them.
- Material Symbols — https://developers.google.com/fonts/docs/material_symbols — Apache-2.0 — the one true variable icon font here, with real `wght`, `FILL`, `GRAD` and `opsz` axes, so one weight at one optical size becomes a setting rather than a download.
- Iconify — https://iconify.design — MIT for the code, each set keeps its own license — 200+ sets behind one API, and the practical way to audit which sets a codebase is actually pulling from.
- svg-sprite — https://github.com/svg-sprite/svg-sprite — MIT — optimizes a folder of SVGs into symbol, view, defs or stack sprites, independent of any build system.
- W3C WAI Images Tutorial — https://www.w3.org/WAI/tutorials/images/ — W3C document license — names a functional icon by its action and gives a decorative one a null alt, which is Law 17's accessible-name rule in its primary source.

Two sets to avoid. Remix Icon left Apache-2.0 in January 2026 for a custom license with field-of-use restrictions, so it is no longer open source. Feather is frozen at May 2024; Lucide is its maintained fork.

## Laws 14 and 15 — Scales and type

- Open Props — https://open-props.style — MIT — plain CSS custom properties for spacing, size, type and radius, so one scale becomes tokens any framework can read.
- Utopia — https://utopia.fyi/type/calculator/ — ISC on `utopia-core`, with no license stated on the site itself — generates `clamp()` custom properties between a minimum and maximum viewport.
- Fluid Type Scale Calculator — https://www.fluid-type-scale.com — MIT — the same job with an unambiguous license in the repo.
- Fontsource — https://fontsource.org — MIT packaging, each font keeps its own license — self-hosts 2,100+ open families as versioned packages, removing the network dependency.
- Google Fonts — https://github.com/google/fonts — mostly SIL OFL 1.1, some Apache-2.0 — where the open-license catalogue actually lives, with a per-family license file to cite.
- Inter — https://rsms.me/inter/ — SIL OFL 1.1 — a variable interface face with a real text and display optical-size split; stable rather than active, quiet since 2024-11.

## Laws 1, 12 and 13 — Vessels, behavior and states

- Zag.js — https://zagjs.com/ — MIT — framework-agnostic core with adapters for React, Vue, Svelte, Solid and vanilla — component interaction as finite state machines, which is the closest thing to a portable inventory of the hidden layer.
- Ark UI — https://ark-ui.com/ — MIT — React, Vue, Svelte, Solid — the same unstyled set with a parallel API across four frameworks, and the proof that behavior specifies independently of one.
- Radix Primitives — https://www.radix-ui.com/primitives — MIT — React only — unstyled accessible primitives; the most-cited React headless baseline, now maintained by WorkOS.
- React Aria — https://react-aria.adobe.com/ — Apache-2.0 — React only — built against the W3C ARIA Authoring Practices, so its written interaction rules are citable even where React is never shipped.
- shadcn/ui — https://ui.shadcn.com/ — MIT — React only — not a dependency: the CLI copies source into the repo, so the components are owned and edited locally. Svelte and Vue ports are community projects, not official.
- Web Awesome — https://webawesome.com/ — MIT core, paid Pro tier — web components — 50+ custom elements that run as plain HTML in any framework or none; the successor to the archived Shoelace.
- Open UI — https://open-ui.org/ — W3C Software and Document License — a specification, not a library — documents the anatomy, parts and states of 30+ controls, and is the vendor-neutral source for naming them.
- Apache ECharts — https://echarts.apache.org/ — Apache-2.0 — framework-agnostic — the production default when a magnitude the user compares needs a chart rather than a column of figures.
- Observable Plot — https://github.com/observablehq/plot — ISC — framework-agnostic — a layered grammar of graphics; better than ECharts when the encoding is the thing being described.

Three to skip. Shopify Polaris restricts use to Shopify integrations and its React repo was archived in September 2026. Material Web states in its own README that it is in maintenance mode pending new maintainers. Melt UI has been quiet for a year while its README still claims active development.

## Law 18 — Identity

- IBM Carbon — https://carbondesignsystem.com/ — Apache-2.0 — React and web components officially — a full open system whose written guidance stands apart from its code.
- Adobe Spectrum — https://spectrum.adobe.com/ — Apache-2.0 — guidance is framework-agnostic, implementations span CSS, web components and React — deep published rules on tokens, spacing, type and motion.
- GitHub Primer — https://primer.style/ — MIT — React, CSS and Rails ViewComponent — three implementations of one set of rules, which is what separable guidance looks like.
- U.S. Web Design System — https://designsystem.digital.gov/ — CC0 1.0 public domain — framework-agnostic — accessibility and UX guidance with no framework binding and no copyright to clear, though GSA trademarks are reserved.
- GOV.UK Design System — https://design-system.service.gov.uk/ — MIT code, Open Government Licence v3.0 documentation — framework-agnostic — the most research-backed open pattern guidance there is; the branding is not granted with it.

An Apache-2.0 or CC0 license covers the code, never the marks. Spectrum grants no trademark rights and does not ship Adobe Clean, USWDS reserves every GSA seal and logo, and GOV.UK branding stays out of scope.

## Law 21 — Breakpoints and targets

- CSS Containment Level 3 — https://www.w3.org/TR/css-contain-3/ — W3C — defines `@container`, `container-type` and the `cq*` units, so a region queries its own width rather than the viewport.
- CSS Box Sizing Level 3 — https://www.w3.org/TR/css-sizing-3/ — W3C — defines `min-content`, `max-content` and `fit-content`, which is a size taken from content rather than from a device number.
- CSS Values and Units Level 4 — https://www.w3.org/TR/css-values-4/ — W3C — defines `min()`, `max()` and `clamp()`, and the small, large and dynamic viewport units.
- CSS Logical Properties Level 1 — https://www.w3.org/TR/css-logical-1/ — W3C — inline and block properties, so one layout survives a reading-direction change untouched.
- MDN `env()` — https://developer.mozilla.org/en-US/docs/Web/CSS/env — MDN, CC BY-SA 2.5 — the safe-area insets, with the fallback argument.
- WCAG 2.2 — https://www.w3.org/TR/WCAG22/ — W3C Recommendation — the source of the target size, reflow and resize floors in `states.md`: SC 2.5.8, SC 2.5.5, SC 1.4.10 and SC 1.4.4.
- Apple Human Interface Guidelines — https://developer.apple.com/design/human-interface-guidelines/accessibility — Apple, proprietary documentation — 44 by 44 pt default on iOS and iPadOS, 28 by 28 pt on macOS.
- Android accessibility guide — https://developer.android.com/guide/topics/ui/accessibility/apps — Google, proprietary documentation — 48 by 48 dp minimum touch target.

## Findings — evidence

- axe-core — https://github.com/dequelabs/axe-core — MPL-2.0 — the rules engine most other checkers wrap; runs in any browser or headless driver.
- Pa11y — https://github.com/pa11y/pa11y — LGPL-3.0-only — a CLI and Node API over headless Chrome, with `pa11y-ci` for gating a whole sitemap.
- IBM Equal Access — https://github.com/IBMa/equal-access — Apache-2.0 — a second engine that plugs into Selenium, Puppeteer or Playwright, useful when one engine's blind spots are the question.
- Lighthouse CI — https://github.com/GoogleChrome/lighthouse-ci — Apache-2.0 — asserts budgets per commit so a score cannot regress quietly; low activity, last commit 2025-06.
- Playwright — https://playwright.dev/docs/test-snapshots — Apache-2.0 — `toHaveScreenshot()` turns a predicted visual claim into an observed one, and the same runner emulates `forcedColors`, `reducedMotion`, `colorScheme`, `contrast`, viewport and locale. It has no emulation for `prefers-reduced-transparency` and no zoom command.
- react-doctor — https://github.com/millionco/react-doctor — Modified MIT, which requires written permission to feed it into an AI or machine-learning training pipeline or to resell it as a hosted service — React only — static rules over JSX, Tailwind and styled-components that surface candidates for Laws 4, 5, 14, 15 and 17 and a few source-confirmed defects. Its design hits are predictions, and its telemetry stays on until `--no-telemetry`.
- Storybook — https://github.com/storybookjs/storybook — MIT — framework-agnostic — forces every hidden state into an addressable, screenshot-able story, which is Law 12's inventory made executable.

An automated pass is evidence for the rules it covers and for nothing else. A clean run never upgrades a prediction into an observation, and the Findings rule holds: a still image cannot prove hover, disclosure, motion, keyboard or pointer behavior.
