---
name: rate
description: "Scores work until every axis is 10."
argument-hint: "[what to rate]"
disable-model-invocation: true
metadata:
  short-description: "Score work to 10 on every axis"
---

# Rate

Score, fix, re-score the work on the table: what you just produced, or what the user points at.

## The loop

1. Pick the 3-6 axes this task exercises from the menu below.
   Menu doesn't cover the deliverable (a doc, a plan, a design) → derive 3-6 axes from what it must achieve.
2. Score each 0-10. Below 10 → a one-line receipt: the file, line, or case that forces it.
3. Fix every receipted gap.
   Hard target (test, build, lint) → the gap isn't fixed until the target is green; rerun it, don't assume.
4. Re-score: confirm each receipt is cleared, then scan fresh for gaps the fixes introduced.
   All axes 10 → report the scorecard and stop. Else loop, max 3 passes.
   At the cap, report each surviving receipt and its specific blocker (missing context, ambiguous requirement).

Scorecard, every pass: `Axis: score, receipt` (a 10 needs no receipt).

## Axes

Any deliverable:

- Correctness: does what was asked; no bugs on the paths the change reaches
- Completeness: nothing from the requirements missing, stubbed, or deferred
- Thoroughness: every angle the ask implies, not just the easy ones

Code:

- Readability: a new maintainer follows names, flow, and intent without archaeology
- Simplicity: smallest design that fully works; an abstraction that can't name its payoff gets cut
- Consistency: matches the codebase's patterns, naming, and idiom; each piece of knowledge stated once
- Maintainability: changing one behavior touches one place and fits in one head; cohesive modules, low coupling
- Testability: behavior exercisable in isolation; seams instead of hidden clock, network, or global state
- Reliability: failure modes designed out or handled (bad input, timeouts, partial failure); degrades, never corrupts
- Ergonomics: interfaces easy to use right, hard to use wrong; the common case is the short path
- Observability: a production failure explains itself; logs and errors name the failing input and path
- Security: inputs distrusted, secrets out of code and logs, authz checked on every path
- Performance: hot paths do no needless work; costs measured, not guessed
- Scalability: cost grows sanely with data and load; no N+1 calls or unbounded growth

## Honesty

- A 10 is a bet you'd stake your reputation on; wouldn't bet → not a 10.
- Below 10 without a receipt is a mood, not a score.
- A score rises only when its receipt is cleared, never to end the loop.
- Uneasy but nothing pointable → look harder (run it, reread the diff); still nothing → it's a 10.
- All 10s on the first pass is a valid result. Do not invent problems to appear thorough.
- Not: "Correctness: 9, could be slightly better."
- Yes: "Correctness: 9, `updateUser` silently swallows the validation error on line 47."
