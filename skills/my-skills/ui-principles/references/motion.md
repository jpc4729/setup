# Motion

Law 19 rules motion. This sheet carries its numbers — curves, bands, properties, offsets and reduced motion — as starting bands for a product register. The Law decides whether the motion exists at all.

## Easing

Law 19 sets the direction. These are the curves that carry it.

The built-in CSS keywords are too weak to read as a decision, so name the curve:

```css
--ease-decelerate: cubic-bezier(0.23, 1, 0.32, 1); /* enters, reveals, anything the user waits on */
--ease-accelerate: cubic-bezier(0.32, 0, 0.67, 0); /* exits that leave the frame */
--ease-both: cubic-bezier(0.77, 0, 0.175, 1); /* on-screen movement from A to B */
--ease-sheet: cubic-bezier(0.32, 0.72, 0, 1); /* drawers and sheets */
```

An accelerating curve starts slow, so it belongs only on motion the user has already stopped watching, and only inside the exit band below. A hover tint or a color change takes plain `ease`. Constant motion — a progress fill, a marquee, a spinner — takes `linear`, because progress that eases misreports itself.

A spring replaces a curve when velocity has to survive: a drag with momentum, a gesture the user can reverse, a value tracking the pointer. Two spellings of one model: `{ type: "spring", duration: 0.5, bounce: 0.2 }`, or `{ mass: 1, stiffness: 100, damping: 16 }` when the parameters need direct control, which is a damping ratio of 0.8 and the same bounce 0.2. Bounce stays between 0.1 and 0.3, and everything outside drag-to-dismiss and play uses bounce 0. Motion — https://motion.dev — MIT — is the library that reads these configs; a CSS-only approximation of a bounceless spring is `cubic-bezier(0.2, 0, 0, 1)`.

## Duration

Duration follows travel distance and element size. A short hop sits at the bottom of its band, a full-height slide at the top.

- Hover tint, background or color change, list row: 100–150ms.
- Press feedback, `scale(0.96)` on `:active`: 100–160ms.
- Tooltip and small popover: 125–200ms.
- Dropdown, select, menu, icon swap: 150–250ms.
- Modal and its backdrop: 200–250ms.
- Drawer, sheet, full-screen layer: 300–500ms on `--ease-sheet`.
- Marketing reveal and explanation: 400–800ms.

Past 300ms a user operating a functional surface waits, so only a full-height layer earns more. Past 500ms the wait is the thing they notice. A frequently repeated element halves its band; an element seen once a week may take the top of it.

## Properties

`transform` and `opacity` compose on the GPU: no layout, no paint, one frame of work, and Chromium composites `filter` beside them. `clip-path` is the sanctioned property for a reveal, a wipe or a hold-to-confirm fill, but an engine that has not moved it to the compositor repaints the clipped box on every frame, so keep it to small boxes and short runs. `height` is tolerated on an accordion only, where no transform equivalent exists, and stays at 200ms because it costs layout every frame.

- `width`, `height`, `margin`, `padding`, `top`, `left` and `inset` trigger layout, paint and composite on every frame.
- `box-shadow`, `background-color` and `border-color` trigger paint, and so does `filter` in an engine that does not composite it; animated `blur()` stays under 20px.
- `transition: all` animates properties nobody chose, including ones added later. Name each property.
- Percentages in `translate()` resolve against the element's own size, so `translateY(100%)` clears a sheet whatever its content.
- A child transform driven from a custom property on the parent recalculates style for every child. Set `transform` on the element itself.
- `will-change: transform` is a repair, not a default. Add it after observing a first-frame hitch or a 1px shift, then remove it when the motion ends — a standing hint holds a compositor layer and its memory forever.
- A motion library's `x`, `y` and `scale` shorthands run on the main thread and drop frames under load. Animate the full `transform` string.

## Enter and exit

An enter is deliberate and an exit is not, so the two are never the same length. An enter takes its band above. An exit takes 150ms, a drawer or sheet a little longer but still shorter than its enter, and it retraces the path the enter took.

- Nothing appears from nothing. Start a panel at `scale(0.95)` and a tooltip at `scale(0.97)`, both with `opacity: 0`. `scale(0)` is a defect.
- A contextual icon swap is the exception: `scale(0.25)`, `opacity: 0`, `blur(4px)`, crossfaded in both directions.
- `transform-origin` sits at the trigger — `var(--transform-origin)` where a headless primitive supplies it. A modal is exempt and stays centered, because it is anchored to the viewport rather than to a control.
- A staged enter offsets by `translateY(8px)` to `translateY(12px)` and may add `filter: blur(4px)` resolving to `blur(0)`.
- An exit travels a short offset, never the full container height, unless spatial context is the point and the element returns to a place the user can see.
- `@starting-style` gives an entry its first frame with no JS and no mount flag.
- Stagger runs 30–80ms between siblings, 100ms between semantic groups, 80ms between the words of a heading.
- The stagger ceiling is total, not per item: the last element lands within 500ms, and the list stays operable from the first frame.

## Interruption

A CSS transition retargets from wherever the value currently sits. A keyframe animation restarts from zero. Anything the user can fire twice in a second — a toggle, a toast, a menu, a tab — is a transition. Keyframes are for one-shot sequences nobody will interrupt.

A spring carries velocity across the interruption, which is why a flicked element keeps its speed instead of restarting at rest. A dismissal reads velocity, not distance alone: `Math.abs(distance) / elapsedMs > 0.11` dismisses on a flick even when the drag never crossed its threshold. Settle the release with `{ type: "spring", duration: 0.5, bounce: 0.2 }`.

- Take pointer capture once the drag starts, so the gesture survives the pointer leaving the element.
- Ignore new touch points while a drag is running, or switching fingers makes the element jump.
- Damp past a boundary with rising resistance rather than a wall.
- Reverse on a second trigger rather than queueing; a queued animation is the lock Law 19 names.
- `element.animate()` from the Web Animations API gives interruptible, composited motion under JS control with no dependency.

## What not to animate

- Any action fired a hundred times a day, and every keyboard-initiated action, where Law 13's frequency rank turns the delay into a tax paid on every use.
- Text the reader is reading, and data being read or compared in a work tool.
- Decoration on load, on a surface the user opens daily, which is Law 19's movement pointing at nothing.
- A scroll reveal on functional UI, which carries a brand register onto a product surface.
- Hover motion left ungated, since a tap fires a false hover. Wrap it in `@media (hover: hover) and (pointer: fine)`.
- A theme swap, where every transitioned color fires at once and reads as a smear. Inject `*, *::before, *::after { transition: none !important }`, force a reflow, drop it on the next frame.
- A focus ring, which appears on the frame focus lands. A ring that fades in lags every Tab press.
- A state change that has no other channel. Color, an icon or a label carries the meaning; motion only carries the eye.
- An animation whose only purpose is to look alive.

## Reduced motion

`@media (prefers-reduced-motion: reduce)` is the query, and the swap is movement for a crossfade. Drive offsets and scales from tokens, then reset the tokens under the preference, so every component keeps its opacity fade and loses its travel:

```css
:root {
  --motion-offset: 8px;
  --motion-scale: 0.95;
}
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-offset: 0px;
    --motion-scale: 1;
  }
}
```

Offsets go to 0, scale goes to 1, stagger delays go to 0, and parallax, marquees, idle loops and auto-advancing rotations stop. Three floors survive the swap: the state change stays legible without any movement, the element ends in the same place it would have ended, and focus order and the path to every task are untouched. Reduced motion is fewer and gentler, never zero — a 150ms opacity crossfade still bridges a change the user would otherwise have to re-read. In a motion library, read the preference through its own hook and swap the offset value rather than branching the component.

## Evidence

The frame budget is 16.7ms at 60Hz and 8.3ms at 120Hz. A dropped frame is one missed deadline, and jank is a run of them.

- Record the interaction in the browser's performance profiler and read the long frames, rather than predicting from the property list.
- Step the animation frame by frame in the DevTools animations panel to catch timing drift between coordinated properties.
- Replay at 2× to 5× duration to see whether a curve stops abruptly, a `transform-origin` is wrong, or a crossfade shows two objects instead of one.
- Test every gesture on a real device over the network, never on a trackpad.
- Playwright — https://playwright.dev — Apache-2.0 — emulates `reducedMotion` and turns a predicted motion claim into a recorded one.
- Look again the next day. A source-read claim stays a prediction, and a still image proves nothing about motion.

One pair resists every number here: opacity against a height change, when a list reflows while an item enters or leaves. There is no formula for it, so it is tuned by eye, confirmed the next day, and never reported as observed until it has been watched running.
