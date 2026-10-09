# Prompts

One prompt per stage, in lifecycle order. Fill in every `<…>`. In a tool without slash commands, replace `/intent <mode>` with `Use the intent skill in <mode> mode.`

## Set up a home in an existing repo

```text
/intent map

Set up the intent trees for this repo. They are for <what>, read by <who>. Leave out <anything>.
My answers so far; delete a line to get your recommendation instead:
- Scope: <product only, as user flows and stories with nothing technical | product plus the critical technical rules | technical per package>
- Homes: <one home | one per package, such as .intent/frontend/ and .intent/backend/>
- Areas: <flows | user stories | features | services>
Survey first. Decide what the repo answers and show the evidence. Ask me the rest, each with options, your recommendation and its reason.
Write nothing until I confirm the shape and the areas. Then write the index with every decision and its reason, the area cards, and an outline draft for every unit.
Audit the home. Report the drafts, the OPEN questions and the code findings, then start align on the most critical area.
```

## Reshape a home

```text
/intent map

The current home does not work for me: <what feels wrong>.
Reopen the shape decisions in the index and propose the smallest reshape that fixes it, with options and your recommendation.
Change nothing until I pick. Keep every aligned tree; move or cut only drafts.
```

## Align drafts

```text
/intent align <area, or blank for every draft>

Walk me through the drafts and OPEN questions, one unit at a time, most critical area first.
I answer each question with keep, change, cut, deepen, open or out of scope.
For a tree I already aligned, show me only what changed.
At the end, list every aligned leaf the code does not meet yet.
```

## Specify a new feature

```text
/intent write <feature>

Specify <feature> before we build it: <who uses it, what they want and why, what must never happen>.
Ask me about every gap before you write a branch. Then align the tree with me.
```

## Refine an outcome

```text
/intent write <area>::<unit> > <outcome>

Refine <outcome> into the rules it leaves open: <what is still undecided>.
Zoom <product | contract | code>. Repeat nothing the parent already says.
Ask about every gap before you write a branch. Then align the child with <who owns those rules>.
```

## Go deep on one function

```text
/intent write <Type::function>

Zoom code, depth exhaustive: one branch per guard, conditional arm, catch and loop edge, in source order.
Anything the code does that nobody asked for becomes an OPEN question, not a branch.
```

## Change behaviour

```text
/intent write <area>

<Behaviour> changes to <new behaviour>.
Update the authority first, then the trees, in the same change.
Then run check on diff by trace.
```

## Generate tests

```text
/intent tests <area or unit>

Generate tests from the aligned trees in this repo's test style. <Structure only | Write the assertion bodies too.>
```

## Audit the home

```text
/intent audit <area, or blank for the whole home>

Find every inconsistency: structure, language, logic, authority and repo.
Fix structure and wording once I agree. Turn the rest into questions for align.
```

## Fit a home to its budget

```text
/intent audit

Run the structure layer and list every unit, area and home over budget.
For each, propose cuts, merges or splits from the budget rules, smallest change first. Change nothing until I pick.
```

## Check before a release

```text
/intent check smoke

Check the smoke path of every aligned tree by <run | tests | trace>.
Report each FAIL with its evidence and each GAP as a question.
```

Use `full` to check every leaf, or `explore` to leave the trees on purpose.

## Verify with certainty

```text
/intent verify <area or unit>

Verify every aligned leaf and score how certain each verdict is. Target certainty <10 | 8>.
Temporary tests are fine. Delete them before you report.
```

Use `/intent verify static <area or unit>` to judge from the code alone: it never runs the software, writes no temporary file, and its target is at most 6.

## Report status

```text
/intent

Report the status of <area, or blank for the whole home>: for every aligned leaf, whether it is built, its latest check verdict and its verify certainty, from the reports.
Where no report covers a leaf, say so. Change nothing.
```

## Read an area

```text
/intent

Explain <area> to me as path sentences, smoke paths first. Change nothing.
```
