---
name: intent
description: "Writes, aligns, audits, checks and verifies intent trees (.tree): what a product, a contract or a function should do, at any zoom, for humans to confirm and agents to prove. Use bet for one unit's test plan."
argument-hint: "[map | write | align | audit | check | verify [static] | tests] [area, path or feature]"
disable-model-invocation: true
metadata:
  short-description: "Intent trees humans align on and agents check"
---

# Intent

An intent tree states what the software should do, branch by branch, in words a human can confirm. Humans read the trees to agree on intent. Agents write them from talk, docs and code, keep them true, and check the software against them. A behaviour missing from the trees either does not exist or nobody has decided it.

Code shows what the software does. A tree states what it should do. The gap between them is the finding. Never encode an unconfirmed assumption as a branch: the tree then looks complete, a human skims past it, and every check proves the wrong thing. Ask instead.

Read `references/notation.md` before you write or edit a tree.

## Decide the shape

This skill gives defaults, not a recipe. Four things are fixed: the notation, no branch from an unconfirmed assumption, a draft until a human aligns it, and the authority winning over trees. Everything else is a decision for this repo: how many homes and where, what an area is, which zooms, how deep, the budget, the check.

- Decide what the repo can answer: its packages, docs, tests, tooling and rules. State the decision and the evidence behind it.
- Ask what only the user knows: who aligns the trees, what they care about, and what they want left out. Offer two to four options, recommend one, and give the reason.
- Record every decision and its reason in the index. The next agent keeps the shape instead of re-deciding it.
- Revisit a decision when the result fights it: a home nobody finishes aligning, trees that restate code, areas nobody reads. Propose the change; never drift from a recorded decision silently.

## Terms

Use these words exactly in trees, cards, indexes and reports; a synonym reads as a second concept.

- Home: a folder of trees with its own index and settings. A repo has one home, `.intent/` by default, or several, one per audience or package, listed by a root index.
- Index: the home's `README.md`. It holds the decisions, the settings, the areas and the format.
- Area: one folder in the home, grouped the way its readers think: a flow, a user story, a feature, a service or a source folder. Its `README.md` is the area card.
- Unit: one `.tree` file holding one or more trees: a flow step, an endpoint, or a type.
- Place: where a tree holds, named in brackets on its root: a surface such as `web`, the `api`, or a source file.
- Branch: a `given` or `when` node. Siblings read top-down and the first that matches wins, like guard clauses, so a later sibling assumes every earlier one fails.
- Leaf: an `it should` node under a branch or the root. Effect: an `it should` node under a leaf, checked in the same run. Outcome: a leaf or an effect.
- Child: a tree whose `// REFINES:` line names one outcome of another tree, its parent. It holds only on the parent's path to that outcome, and states only what that outcome leaves open.
- Smoke path: the chain of last children from the root down to a leaf. The happy path comes last, so the smoke path walks the main success.
- Authority: the source that wins when it and a tree disagree: product docs, a spec, or the trees themselves.
- Draft: a tree with a `// DRAFT:` line under its root. Nobody has confirmed it. Aligned: a human confirmed every branch.

## Resolution

Two settings decide how much a tree says. The index sets both. An area card may override them. When neither holds them, ask the user once.

Zoom decides whose words a tree uses:

- `product`: what a person does and sees. No code names. Leaves name screens, messages, statuses, figures and records a person can find.
- `contract`: what crosses a boundary: a request and its response, a command and its exit code, an event, a job, a file, a stored record.
- `code`: what one function or type does. Roots name symbols. Leaves name returns, throws, calls and writes, in source order.

Depth decides how many branches a tree holds:

- `outline`: the smoke path and the refusals a person would name first. It is fast to align.
- `full`: every confirmed requirement. This is the default.
- `exhaustive`: every branch point: each guard, each arm of a conditional including the implicit else, each catch, each loop at zero, one and many, each boundary value. At `code` zoom this reads the function line by line.

Mix zooms by area; one area holds one zoom. Restate never; refine freely. A decision lives in one tree, at the highest zoom that can observe it: `product` whenever a person can see it. A `contract` or `code` area holds what no screen shows, the few functions where a wrong branch costs most, and children that refine a product outcome. It never restates a product tree. `references/zoom.md` says who reads each zoom, shows one behaviour at every zoom, and lists what to probe at each.

Zoom says whose words a tree uses. Refinement says how fine it goes. An outcome that hides a decision its reader does not own opens into a child: a finer tree at the same zoom, or one zoomed in, from `product` to `contract` to `code`, never out. The child repeats none of the parent's conditions and not its outcome. `references/zoom.md` maps the levels to epics, stories and acceptance criteria, and says when to refine and how to split a story.

Budgets cap how much a home asks of the humans who align it: by default 12 leaves per unit, 80 per area and 1,000 per home. A leaf earns its place only when someone could reasonably want a different outcome. `references/zoom.md` holds the boundaries, how to spend depth by risk, and how to cut a home back to budget.

## Modes

- `map`: set up the home, list areas and units, and report what has no tree.
- `write`: discover the requirements of one unit and write its trees.
- `align`: walk trees with the user until each is confirmed.
- `audit`: find every inconsistency between the trees, the authority and the repo.
- `check`: run the software against the trees by one method, one verdict per leaf.
- `verify`: stack evidence per leaf until its verdict is certain, and score that certainty from 0 to 10. `verify static` judges from the code alone and never runs the software.
- `tests`: generate test code whose names are the leaves.

With no mode named, pick from the request:

- A new feature or a question about intent → `write`.
- Breaking an outcome into finer rules → `write` with that outcome as the parent.
- "Is this right?" → `align`.
- "Is it consistent?" → `audit`.
- "Does it work?" → `check`.
- "How sure are we?" → `verify`.

Every mode starts by finding the home: look for an index next to `.tree` files, or a root index that lists homes, before you create anything.

The loop for new work is `write`, `align`, refine, build, `check`. To refine, `write` a child for each outcome the rank calls for, and `align` it with the people who own its decisions. Each level is checked at its own zoom, like the paired levels of a V-model. The loop for existing code is `map`, drafts, `align`, `audit`, `check`. `examples/prompts.md` holds a ready prompt for each stage; when a mode ends, offer the prompt for the next stage.

## map

1. Find the home. An existing index holds decisions; keep them unless the user reopens one.
2. Survey the sources: product docs, routes and screens, endpoints and commands, packages, entry modules and existing tests. Probe the pillars in `references/zoom.md`: a pillar with no area is where missing areas hide. Use subagents for a large repo when the tool offers them.
3. Decide the shape, as the section above says. Settle at least these, and write nothing until the user confirms:
   - Audience: who aligns the trees: the product owner, the engineers, or both. With children, name who aligns each level.
   - Scope: product only, as user flows or stories with nothing technical; product plus the critical technical rules; or technical per package.
   - Homes: one home, one per package such as `.intent/frontend/` and `.intent/backend/`, or one per product.
   - Areas: flows, user stories, features, services or source folders, and each area's rank: critical, core or peripheral. A unit may override its area's rank.
   - Non-functional requirements: which become leaves and which stay in their own documents, as `references/zoom.md` says.
   - Resolution and the rest: zoom, depth and budget per home, the authority, and the check method.
4. Propose areas and their units in run order, sized to the budget, with depth set by rank. Propose only as many areas as the user can judge in one reply, then offer the rest.
5. Write the index, with the decisions and their reasons, and the area cards from `references/layout.md`. At `product` zoom each unit on a card carries its story: the actor, the goal and the reason. A unit with no tree yet reads `(no tree)` on its card.
6. Draft trees only when the user asks for them in bulk. Draft at `outline` depth, whatever the area's depth: a full-depth draft from code transcribes the code, and nobody aligns a transcript. Never draft children in bulk, for the same reason; refine through `write`. Each draft carries `// DRAFT: from <source> -- not aligned` under its root.
7. Report the areas, the units, the aligned trees, the drafts, the `// OPEN:` count and the units with no tree. Bugs and inconsistencies seen in the code go in the report as code findings, never into a tree.

## write

### 1. Recognition

Settle these before discovery and show them to the user:

```text
Unit: {what the trees cover}
Story: {as <actor>, <goal>, so that <reason>; product zoom only}
Refines: {<parent root> > <outcome>, or "none"}
Area: {folder, new or existing}
Zoom / depth: {from the area card, the index or the user}
Authority: {the source that wins over the tree, or "trees"}
Sources: {docs, code and tests you read}
```

### 2. Discovery

Discovery gates the tree: every branch traces to a confirmed requirement. For a child, discovery starts from the parent's path and asks only what its outcome leaves open.

1. Extract. The authority gives rules. Code gives what IS: guards become refusals, validation becomes constraints, conditionals become branches, side effects become effects. Tests give what someone already checked. The request gives explicit statements; flag everything it only implies.
2. Classify by the categories for the zoom in `references/zoom.md`. A category with no requirement usually means nobody thought about it, not that it does not matter.
3. Probe. Who else calls this? Does a failed side effect leave partial work behind? What happens at the exact boundary values, on a repeat, on two at once, offline, with the wrong role?
4. Present a checklist and ask about every open line:

   ```text
   ## Requirements: {unit}

   ### {category}
   - [x] {stated by the authority or confirmed by the user}
   - [ ] seen in code: {what the code does} -- intended?
   - [ ] ??? {question nobody has answered}
   ```

5. A deferred item becomes a `// OPEN:` line. An excluded item becomes a `// OUT OF SCOPE:` line. Nothing drops silently.

At `outline` depth the checklist holds only the smoke path and the top refusals. Skip the confirmation round only when the authority already states every branch. Bulk drafting from code also skips it; the draft marker sends the tree to `align`.

### 3. Write

1. Put refusals and failures first and the happy path last, at every level. The chain of last children is then the smoke path. At `code` zoom, siblings follow the source order of the guards.
2. Trace both ways. Every branch traces to a requirement, and every requirement has a branch. A missing branch is a missing check. An orphan branch is an assumption.
3. A leaf names one outcome a reader can observe at the tree's zoom, and one someone could reasonably want different. A second outcome of the same run is an effect under it.
4. Stay inside the budget. Split a unit over it by flow step, or move a heavy outcome's detail into a child. At `code` zoom, write one tree per function and one unit per type or module.
5. A behaviour that differs by place gets its own tree in the same unit, two blank lines apart.
6. A child carries `// REFINES: <parent root> > <outcome>` under its root, and lives in the area whose readers own its decisions.
7. Add the unit to its area card.
8. Run `scripts/trees lint <file>` from this skill's directory and fix every diagnostic.

### 4. Review

Show the tree and run `align` on it. A tree written from confirmed requirements still needs one read by the human who owns the intent.

## align

The human reads and the agent asks. Show trees verbatim and keep questions short.

1. Scope: the trees or areas the user names; otherwise every tree with `// DRAFT:` or `// OPEN:`.
2. Per unit, show a draft whole. For a tree already aligned, show only the branches `git diff` reports changed since the last commit, or since a ref the user names, and every child that refines a changed outcome. Then ask at most five questions, taken in this order:
   - each `// OPEN:` line;
   - each leaf the code contradicts, citing the code that does otherwise;
   - each child that repeats its parent, or promises less or more than the outcome it refines;
   - each leaf that looks accidental: a silent failure, a place that disagrees with its sibling tree, a refusal with no message;
   - each category for the zoom that has no branch.
3. For a reader who does not read trees, add path sentences: `scripts/trees paths <file>` prints one sentence per leaf.
4. Apply each answer to its branch: keep it, change it, cut it, deepen it, or turn it into a `// OPEN:` or `// OUT OF SCOPE:` line. Deepen an outline draft only where the user asks, or where the area's rank calls for it. An answer that adds a rule the authority lacks lands in the authority first. Propose that edit, then change the tree.
5. When the user has agreed with every branch, delete the `// DRAFT:` line. The tree is now aligned.
6. Report what changed. List separately every aligned leaf the code does not meet yet: that is the work the alignment found, not a defect in the tree.

## audit

Find every place the home disagrees with itself, the authority or the repo. Read `references/audit.md` for the layers, the codes, the fan-out and the report.

1. Scope: the areas the user names; otherwise the whole home.
2. Run `scripts/trees audit <home>` for the structure layer. Then read for language, logic, authority and repo findings.
3. Every finding names both sides that disagree.
4. Fix structure and wording once the user agrees; they change no meaning. Every other finding is a question for `align`.

## check

Check the software against the trees. Read `references/check.md` for the methods, kinds, verdicts, subagent brief and report.

1. Scope: the areas or units the user names; `diff` for the areas whose card lists a path the working diff touches; otherwise the whole home.
2. List the leaves with `scripts/trees paths --aligned [--smoke] <scope>`. Drafts drop out, because checking a draft tests a guess. A child's leaves carry a `^ refines` line: reach the parent's path first.
3. Give every listed leaf one verdict, `PASS`, `FAIL`, `BLOCKED` or `SKIP`, by the method the index or the user names: `trace`, `tests` or `run`.
4. A finding no leaf covers is a `GAP`: a question for the user, never a branch on its own.

## verify

Read `references/verify.md` and follow it. It uses the `typesafe-ai` skill when the tool has it.

## tests

Turn trees into test code the suite runs. First read two or three existing test files and mirror their nesting, naming and setup exactly.

- The root becomes the top-level suite. Each `given` and `when` becomes a nested group. Each leaf becomes one test case. Its effects become assertions inside that case, not separate tests.
- Set up each case so every earlier sibling on its path fails. Otherwise a happy-path test can pass without the session or input it assumes.
- A child becomes its own suite. Its setup reaches the parent's path first, then its own branches.
- Copy labels verbatim into test names. A test name then maps back to its leaf, and `check` with `tests` can match them.
- Write structure and setup comments by default. Write assertion bodies only when the user asks; each body proves its leaf and nothing more.
- Put tests where the project keeps them. The trees stay in the home.
- A `// OUT OF SCOPE:` or `// OPEN:` line produces no test.

## Keep trees true

- A change to behaviour updates its tree in the same change. A new rule lands in the authority first. A changed outcome reopens every child that refines it.
- An aligned tree wins over code: when they disagree, the code is wrong until the user says otherwise. A draft wins over nothing.
- Trees hold intent, never status. `// DRAFT:` is the only state a tree carries. What is built, passing or verified lives in `check` and `verify` reports.
- The index states these rules for every agent that reads the repo. Offer one line for the repo's `AGENTS.md` that points at the home. Never write it unasked.
