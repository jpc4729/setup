# Workflows

Say what you want. Claude runs one flow. Read the report.

## The flow

The same flow for every task. A small task skips the plan.

```
 you: "do X", or paste findings
        |
        v
+----------------+   facts, then 1 round of questions
| 1. Understand  |   with Claude's picks; it goes on
+----------------+
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
| 5. Review once |   plan or risky: verifiers, 1 fix round
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
a list of fixes               paste it: "Fix these, in order:"
stop after the plan           add "plan only"
options before any work       add "ask first"
proof for risky work          add "verify this"
a second review               "review again"
a bug                         /diagnose <symptom>
a big, unclear idea           /wayfinder <idea>
a question, no changes        /read-only <question>
many agents at once           add "ultracode"
```

## Prompts to copy

Fill the `<...>` parts. Each prompt runs the whole flow.

Build a feature:

```text
Build <feature> in <area or path>. Done when <result I can see>.
Out of scope: <what to leave alone>.
```

Fix a list of findings:

```text
Fix these, most important first. Skip any that the code does not confirm, and say why.
<paste the findings>
```

Find and fix a bug:

```text
/diagnose <symptom>. It happens when <steps>. Expected: <result>.
```

Review a branch before a pull request:

```text
Review this branch against main for bugs, missing error paths and drift from <goal>.
Fix what the code confirms, then update the docs the change made wrong.
```

Plan only, build later:

```text
Plan only: <work>. Show me the tickets and stop.
```

```text
Build the plan in <plan path>.
```

Answer a question, change nothing:

```text
/read-only How does <thing> work? Show the path:line evidence.
```

Risky change, with proof:

```text
<task>. Verify this: <claims a run can fail, such as "the migration keeps every row">.
```

Check a page in a real browser:

```text
<UI change>. Check it in agent-browser at <url> and show a screenshot.
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

## Old prompt, new prompt

```
old                                          new
-------------------------------------------  ------------------------
"use the planner"                            just ask
"Implement all the work ... Rate 0-10 ..."   just ask
"Walk the final work diff twice ..."         done in step 5
```
