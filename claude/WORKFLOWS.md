# Workflows

Say what you want. Claude runs one flow. Read the report.

## The flow

The same flow for every task. A small task skips the plan.

```
 you: "do X", or paste findings
        |
        v
+----------------+   facts, then 1 round of questions
| 1. Understand  |   with Claude's picks; it goes on,
+----------------+   or waits if a wrong pick is costly
        |
        v
+----------------+   only for 2+ parts: planner writes
| 2. Plan        |   1-5 tickets, Claude shows them
+----------------+
        |
        v
+----------------+   small: Claude does it
| 3. Build       |   plan: a fresh worker per ticket
+----------------+   (fails twice: replan once, then stop)
        |
        v
+----------------+   smallest check while working,
| 4. Check       |   lint, format, types at the end
+----------------+
        |
        v
+----------------+   small: Claude reads its diff
| 5. Review once |   plan or costly: 1 verifier, 1 fix round
+----------------+   no scores, no loops
        |
        v
+----------------+   changes, checks, findings,
| 6. Report      |   at most 3 lessons
+----------------+
```

## What to type

```
what you want                 type
----------------------------  ---------------------------------
any task                      just ask
a list of fixes               paste it: "Refute these, then fix"
attack a plan, no edits       paste "Attack this plan"
eval a skill                  paste "Eval the skill <name>"
stop after the plan           add "plan only"
options before any work       add "ask first"
proof for risky work          add "verify this"
proof from two models         add "verify this with two models"
parts built in parallel       add "use workers"
cheap summaries or counts     add "use clerks"
a second review               "review again"
a bug                         /diagnose <symptom>
a big, unclear idea           /wayfinder <idea>
a question, no changes        /read-only <question>
see the app run               /run
a recipe to prove changes     /verify-setup
bugs in a diff or an area     "find bugs in <diff or path>"
a deeper bug review           /code-review
simpler code                  /simplify
write or fix a skill          /skills-claude
conflicts after a rule edit   /doctor prompt-audit
a workflow of agents          add "ultracode"
```

A workflow stays small, under about 5 agents (`workflowSizeGuideline`), unless the prompt asks for more.

## Prompts to copy

Fill the `<...>` parts. A prompt that says to stop does only that. The others run the whole flow.

Build a feature:

```text
Build <feature> in <area or path>. Done when <result I can see>.
Out of scope: <what to leave alone>.
```

Fix a list of findings:

```text
Refute these, then fix the ones you cannot disprove, most important first.
Assume each finding is wrong. Keep it only with the input or state that makes it true, and say why you dropped the rest.
One repair. Do not add machinery for a case nothing can reach. A smaller change that meets the request wins.
<paste the findings>
```

Find and fix a bug:

```text
/diagnose <symptom>. It happens when <steps>. Expected: <result>.
```

Review a branch before a pull request:

```text
Review this branch against main. Adversarial review only: hunt for what breaks, and do not fix anything.
Each defect needs the input or state that breaks it. A risk no caller, input or stored data can reach is not a defect.
Show me the list and stop.
```

Plan only, build later:

```text
Plan only: <work>. Show me the tickets and stop.
```

```text
Attack this plan. Change nothing.
Give it to one fresh `verifier` with only my request word for word, the plan path and the repo, not this conversation, so it reads the plan as a worker will. Claims:
C1 A worker that reads only this plan and the repo can build each ticket on the first try. For each ticket that fails, name what it lacks.
C2 Each assumption the plan depends on holds in the repo. Name the main one, and the input that shows the plan is wrong.
C3 No smaller design meets the Goal. Name one if it exists.
C4 Each ticket is one change you can measure alone. Name each ticket that bundles changes.
Follow Occam's razor, and keep the design highly cohesive and loosely coupled.
```

```text
Build the plan in <plan path>.
If this plan has no attack yet, stop and do that first, with the "Attack this plan" prompt. Change nothing until I say so.
```

Plans are in `~/.local/state/plans/<repo>/`.

Answer a question, change nothing:

```text
/read-only How does <thing> work? Show the path:line evidence.
```

Risky change, with proof:

```text
<task>. Verify this. Each claim is one yes/no check a run can fail:
<claim, such as "the migration keeps every row">
```

Check a page in a real browser:

```text
<UI change>. Check it in agent-browser at <url> and show a screenshot.
```

A long job toward one number:

```text
/goal <number> reaches <target>, measured by <command>. Make one change at a time and measure after each. Revert a change that does not move the number. Do not delete a feature or a test. Stop after 50 turns. This goal overrides the "two fixes that do not help" stop.
```

Eval a skill:

```text
Eval the skill <name>, then improve it. Change nothing else.
1. Take 10 real tasks that used it, inputs unchanged. If you cannot find 10, ask me.
2. Write 8 yes/no questions, one fact each. Show them and wait.
3. Run each task in a fresh subagent with only the skill and that input. Do not post or spend. Write what those steps would do.
4. A separate subagent judges. It sees only the input and the output. I grade all 10 first. Continue only when the judge matches me on 9 of 10, and fails the ones I failed.
5. Take the question with the worst pass rate. Try two fixes. Keep one only when that question passes on at least 2 more tasks and no other question drops.
6. Save the new skill as a new file. Give me the before and after scores and the lines you changed.
```

Continue in a fresh session:

```text
/handoff <what the next session does>
```

Then `/clear`, and paste the kickoff prompt that `/handoff` printed.

## Keep it quick

- One task in a session. Type `/clear` between unrelated tasks.
- Near 300k tokens with work left: `/handoff`, then `/clear`.
- A session went wrong: `/retro`.
