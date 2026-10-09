# Verify

`verify` proves each leaf met or not met and scores how certain that verdict is, from 0 to 10. `check` gives one verdict by one method. `verify` stacks evidence per leaf, asks TypeSafe to judge what the evidence shows, and climbs to stronger evidence until the verdict reaches the target certainty or three passes run out. `verify static` stays on the code rung and never runs the software.

## Setup

1. Load the `typesafe-ai` skill, or read https://docs.typesafe.ai/llms.txt when the tool lacks it, and confirm the request shape on the live API page. Today it is `POST https://api.typesafe.ai/v1/systemone` with `Authorization: Bearer $TYPESAFE_API_KEY`, model `jev-1.13.0`, and a `questions` map keyed by your own IDs. Pin that version, never `jev-latest`: the alias moves when a release ships, and the readings below were measured on `jev-1.13.0`. Never print the key or write it to a file. When step 3 allows TypeSafe and the key is unset, ask the user to set it or to accept judging without TypeSafe.
2. Errors: retry 429 and 529 with exponential backoff, honouring `retry-after`, at most five tries. Any other error stops the run, and so does a response that lacks an answer for a question ID or names an option you did not send: report it.
3. Data: excerpts of code and tests leave the machine. Send them only when the index's Settings read `TypeSafe: allowed`. When Settings hold no `TypeSafe:` line, ask the user once; record the answer there as `TypeSafe: allowed` or `TypeSafe: not allowed`, and its reason under Decisions.
4. Judge without TypeSafe when Settings read `TypeSafe: not allowed`, when the user accepts it for an unset key, or, for the rest of the run, when the network fails or the retries run out. Answer the questions below yourself, without the `_r` copies, with a confidence from 0 to 1. Cap certainty at 8 and mark the leaf `judged without TypeSafe`.
5. Scope: the units or areas the user names. List the leaves with `scripts/trees paths --aligned <scope>`.
6. Evidence: every rung, unless the user asks for `static`. `static` reads source and never runs the software under check: no test, suite, build, install, server, browser, its CLI, container or sandbox, and no temporary file. It only reads files, searches text, reads `git`, runs `scripts/trees`, reads the TypeSafe docs, calls the TypeSafe API, records the index's `TypeSafe:` setting, and writes the report: no linter, type checker, compiler or package script, and no request to the software or any of its services. A test's source is no evidence until it runs.
7. Target: the certainty the user names; otherwise 10. With `static` the target is at most 6, the code rung's cap; say so when the user named more.
8. Stamp: `V` and the local time as `MMDDHHmm`, for example `V09281430`. Every temporary file and record carries it.

## Evidence ladder

Climb one rung at a time, and only as high as the receipt demands. Each rung caps the certainty it can support. `static` stops at rung 1.

1. Code, cap 6. Find the code on the leaf's path and cite `file:line`. When several spans could be the one, ask TypeSafe one Choice over the candidates plus `none`. The code says so; nothing ran.
2. Existing test, cap 8. Run only the suite tests that drive the leaf's conditions. Their authors asserted what they meant, which may be less than the leaf.
3. Smoke run or temporary test, cap 10. A smoke run drives the running software as `references/check.md` describes under `run`. A temporary test asserts exactly the leaf. Either reaches 10 only when it observes the leaf at its own zoom: a smoke run for `product`, a temporary test for `code`, either for `contract`. Otherwise its cap is 9.

## Temporary tests

- Write one file per unit, named with `intent-verify-<stamp>`, where and how the test runner discovers tests. Mirror an existing test's setup.
- Assert the leaf's outcome and every effect. Set up each earlier sibling on the path to fail, because the first match wins. For a child, reach its parent's path first.
- Prove the test can fail: invert one expectation, run it, watch it fail, restore it. A test that cannot fail proves nothing.
- Run only that file. Never edit production code or an existing test. Use only stamped records.
- Delete every temporary file before you report, and confirm with `git status --porcelain` that none is left. After an interrupted run, find leftovers by the stamp.
- A temporary test that earned a 10 may deserve a place in the suite. Offer it, and keep it only when the user says so, through the `tests` mode.

## Judge

TypeSafe judges what the evidence means. Ask all of a leaf's questions in one request, over one state. Keep each excerpt to the lines on the leaf's path: unrelated detail distracts the model, and state plus the longest question must fit in 32k tokens. A code excerpt also holds each call on the path that the outcome or an effect depends on, such as the repository method that returns the record: a call Jev cannot see is one more hop. Drop comments, except a `// <path>` header above each file's lines, and replace test names with `…`: text that argues for its own answer can move Jev, and a test named after its leaf states the outcome word for word. Jev counts unreliably and reads numbers and dates as text, so compare them in the test or in code and put the result in the state.

```json
{
  "conditions": ["given the order is paid", "when refunds.create resolves"],
  "outcome": "it should return the order with status `cancelled`",
  "control": "it should refuse to cancel the order",
  "effects": ["it should call `refunds.create` once with the captured amount"],
  "zoom": "code",
  "place": "src/orders/service.ts",
  "evidence": [
    { "rung": "code", "source": "src/orders/service.ts:41-52", "excerpt": "…" },
    {
      "rung": "temporary test",
      "source": "test/intent-verify-V09281430.test.ts",
      "excerpt": "…",
      "result": "passed",
      "can_fail": "yes: it failed when one expectation was inverted"
    }
  ]
}
```

For a child, `conditions` starts with its parent's path to the refined outcome. Write `control` as an outcome that cannot happen in the same run as `outcome`: a refusal instead of a success, no call instead of a call, another status. Prefer words the excerpt never uses: a status the setup starts from can read as the control shown. Write `result` as `passed`, or `failed: <message>` when an assertion failed. A test or smoke run that errored before it settled, by a timeout, a crashed setup or a service that was down, is no evidence: leave it out of the state and list it in the report. Keep the can-fail proof in `can_fail`. A mixed string such as "passed; failed when inverted" pulls probability toward `contradicts`.

Four Choice questions, worded the same way every time:

- `relation_<i>`, one per evidence item. Instructions: "How does `evidence[<i>]` relate to `outcome` under `conditions`? Ignore `effects`." Criteria: `shows`, "it exercises every condition in `conditions` and shows all of `outcome` happening"; `contradicts`, "it exercises those conditions and shows a different outcome, or fails on `outcome`"; `says_nothing`, "it does not settle `outcome` under `conditions` either way: other conditions, only part of `outcome`, or unrelated". For code, which never ran, `shows` reads "followed with every condition in `conditions` true, it ends in all of `outcome`" and `contradicts` reads "followed with those conditions true, it ends in a different outcome".
- `covers_<i>`, one per test. Instructions: "What does `evidence[<i>]` check under `conditions`? Compare it with `outcome`. Ignore `result` and `effects`." Criteria: `checks`, "it sets up every condition in `conditions` and checks all of `outcome`"; `checks_other`, "it sets up those conditions and checks for an outcome that differs from `outcome`"; `says_nothing`, "it does not check `outcome` under `conditions`: other conditions, only part of `outcome`, or unrelated". Jev judges what the test checks; you combine it with the runner's `result`.
- `control_<i>`, one per evidence item: the `relation_<i>` wording and criteria with `control` in place of `outcome`. A control is not a relation; it only tests the judge.
- `effect_<j>`, one per effect. Instructions: "Does the evidence show `effects[<j>]` in the same run as `outcome`?" Criteria: `shows`, "an evidence item shows it"; `contradicts`, "an evidence item shows it absent or different"; `says_nothing`, "no evidence item addresses it". When every evidence item is code, they read: `shows`, "followed with every condition in `conditions` true, the code performs it"; `contradicts`, "followed with those conditions true, the code ends without it, or performs a different one"; `says_nothing`, "the code shown does not settle it".

Ask each of these questions a second time with its options in reverse order, under its ID plus `_r`. `jev-1.13.0` can lean toward the first option, and the first option is the one that passes a leaf. The relation question ignores effects on purpose: judged together, one unshown effect drags a passing test toward partial. The rules stay yours, applied in order:

1. Answers. A question and its `_r` copy that pick different options read as `says_nothing`; when they agree, the answer takes the lower confidence. An answer below confidence 0.5, the docs' floor for a model that is unsure, reads as `says_nothing`. A relation that reads `shows` while its control also reads `shows` reads as `says_nothing`: the judge cannot tell the outcome from its opposite on that item. So does a test's relation that reads `shows` while its `covers` does not read `checks`. Controls play no further part.
2. Verdict. A test's `covers` reads as `contradicts`, at its own confidence, when it reads `checks` and the test failed, or `checks_other` and the test passed. `NOT MET` when any relation, effect or `covers` reads `contradicts`: one confident red flag is enough. `MET` when a relation reads `shows` and none of them reads `contradicts`. `UNKNOWN` otherwise.
3. Judgment. The answers that support the verdict are each relation that reads `shows` for `MET`, and each relation, effect or `covers` that reads `contradicts` for `NOT MET`. Each gets 10 at confidence 0.8 or more, otherwise 10 × confidence rounded half up. From 0.8 the citation-check cookbook, run on `jev-1.12`, lets the same three-way Choice stand without a person.
4. Certainty. Each supporting answer gives the lower of its judgment and its rung's cap; the highest wins, the more confident on a tie, and its answer is the deciding answer. An effect takes the highest cap in the state. An effect that reads `says_nothing` caps a `MET` at 5. `UNKNOWN` scores 0.
5. Second judge, `static` only. Before you ask TypeSafe, trace the leaf as `references/check.md` describes under `trace`, and settle your verdict, `MET`, `NOT MET` or `UNKNOWN`, with its `file:line`. Keep it out of the state. When your verdict and Jev's differ, the leaf is `UNKNOWN`, and its receipt names both.

Choice confidence measures how concentrated the answer is, not whether it is true. These rules were calibrated on `jev-1.13.0` on 2026-10-03, on synthetic cases only:

- Runs: 12 cases at three zooms, six runs each. Passing temporary tests and smoke runs scored `MET` 10 in every run. Failing ones scored `NOT MET` 10, except a contract test whose failure message compares status codes: its relation read `contradicts` below the floor, and its `covers` gave `NOT MET` at 5 to 7. A passing test whose leaf names another outcome scored `NOT MET` 10. A test with the wrong setup, and a test that checks part of the outcome, stayed `UNKNOWN`. None passed or failed the suite wrongly.
- Code alone: 24 cases at three zooms, three runs each. Jev read every correct path as `shows`, at 0.66 to 1.00, enough to pass in 21 of 33 runs. It failed 15 of 36 runs on paths with a bug, and never a correct path. But it read a validator that lacks its email check as `shows` at 0.96 or more, and a guard that misses an empty list at 0.60 to 0.70. Hence the second judge.

Record the `model` each response names. Move the pin only when, on the new version, a passing temporary test with a can-fail proof reads `shows` and the same test failing reads `contradicts`, each at 0.8 or more with its `_r` copy.

## Certainty loop

1. Score each leaf. Below the target, write a one-line receipt: the missing rung, the unshown effect, the conflict, or an overruled answer, with its `file:line`.
2. Climb to the rung the receipt names, and judge again. An overruled answer needs other evidence, on its rung or the next. With `static`, add new code instead: the guard that routes to the outcome, the call behind an effect, or the caller that reaches the path.
3. Stop at the target, or after three passes. At the cap, report the receipt that survived and what blocks it.

Honesty:

- A 10 is a verdict you would stake your reputation on.
- A score below 10 without a receipt is a mood, not a score.
- Only new evidence moves a score. Rereading the same evidence does not.
- Stop at the target. Never write a temporary test to decorate a leaf that already reached it.
- Certainty measures the verdict, not the software. `NOT MET 10/10` is a strong result.

## Fan-out

When the tool can spawn subagents, give each unit its own, at most four at once, and name `static` in each brief when the run is static. Temporary tests that share a database run one agent at a time.

## Report

Report in chat unless the index names a reports folder.

```text
<file>:<line> MET|NOT MET|UNKNOWN <certainty>/10 <rung> — <evidence> — jev|self <option> <confidence> [— receipt: <what keeps it below 10>]
```

The `jev|self` part names the deciding answer; an `UNKNOWN` leaf writes `none` there. Read as a test suite, a leaf passes when it is `MET` at or above the target and its deciding answer has confidence 0.8 or more, and fails when it is `NOT MET` on the same terms; in `static`, only when the second judge agrees, which needs TypeSafe. Every other leaf needs review. `UNKNOWN` never passes. A `static` report opens with `static: code reads only, the software never ran`.

1. Counts per verdict, and per certainty: 10, 7 to 9, 0 to 6.
2. Every `NOT MET` with its evidence.
3. Every leaf below the target, with its receipt and blocker.
4. The Jev model version, each answer the Answers rule overruled and why, every test or smoke run that errored with its leaf, and every leaf judged without TypeSafe.
5. The temporary files created and the proof that each is deleted.
