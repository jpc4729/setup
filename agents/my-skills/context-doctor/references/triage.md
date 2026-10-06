# Reduction decisions

## Protect the contract

The object of this audit is the target codebase's context. Protect the current user's instructions, permissions, safety boundaries, and necessary repository behavior. Existing audited Markdown is not untouchable: its wording, duplication, and obsolete instructions are precisely what the user asked to reduce. Count a repeated instruction once; repetition adds no requirement.

## Inventory closure

Start with active entry points and ancestor files. Inspect configured includes, nested rules, agent definitions, invoked skill bodies, workflows, and recursively referenced agent documents. Supplement the scanners with repository file discovery, including hidden instruction directories and owned templates. Trace each discovered load or read edge; use a visited set to terminate cycles.

Record path, source owner, consumers, load condition, and estimated cost in temporary working notes. Classify every destination as owned agent context, generated copy, vendored source, human documentation, or unresolved. Include unreadable or dynamic destinations as unresolved. Discovery is complete only when every reachable destination has a classification and every identified instruction scope has been inspected. Unknown reach limits the completeness claim; it never proves a file unnecessary.

Select a small task set before changing the inventory: ordinary work, a special command or workflow, an exception, and an unrelated subtree. Record each task's launch directory, active tool, required decisions, and relevant instruction chain. Keep these tasks fixed during comparison.

## Retention evidence

For each decision, ask: under which task condition would its absence cause which specific wrong action? What repository evidence supports that risk? Would the agent encounter the same fact through ordinary discovery before making the consequential choice?

Keep a decision when it preserves a current user requirement, a concrete house policy, or an evidenced non-obvious hazard. An observed failure, a verified wrapper prerequisite, a generated-file contract, or an explicit authorization boundary can establish necessity. “The agent might forget” and “this seems helpful” cannot justify generic advice. A unique workflow may be documented only in the audited file; lack of a second source does not make it disposable.

Delete derivable facts when normal discovery supplies them in time. Verify actual enforcement, including scope and when it runs, before deleting covered prose. Investigate uncertain claims with a focused read; preserve the uncertain minimum and disclose it if evidence remains unavailable.

## Semantic deduplication

Split compound paragraphs into decisions in working notes. Compare scope, trigger, action, prohibition, exception, done condition, and exact command or path. Another instruction subsumes a decision only when it carries all necessary behavior and reaches every affected task. Match meaning, not keywords or repeated strings.

Merge paraphrases and stronger statements that fully cover weaker ones. Preserve distinctions between preference and obligation, before and after, local and production, permission and execution, and a general rule and its exception. A regeneration instruction does not imply review before publishing. An approval rule cannot disappear because a test passes.

Draft the smallest candidate from retained decisions instead of preserving the old section structure. Remove headings and examples that explain nothing beyond those decisions. Keep an example only when its removal leaves a real ambiguity. Use full, clear sentences; fewer words with lost meaning is a failed reduction. State each rule as the action to take. Keep a prohibition only when no action can replace it, and put its action beside it. End each step on a condition the agent can check, such as a command that passes, not on a vague state such as "understand the module". When one idea is spelled out in several places, name it with one common word the model already knows, define it once, and reuse that word.

## Deletion sequence

1. Remove whole owned context files whose useful instructions are already available in the same task scope. Remove empty files and unnecessary adapters only after checking inbound references and active loaders. Leave human documentation and vendored sources outside this operation.
2. Remove repeated preambles, directory tours, dependency versions, README excerpts, generic best practices, command catalogs, and explanations of how agents load rules. Preserve the exceptional command whose obvious alternative breaks the workflow.
3. Remove rules already covered by an instruction in the same scope or by verified enforcement. A linter configuration alone does not prove it enforces a particular rule. Keep guidance needed to avoid harm before a check runs.
4. Merge overlapping survivors into one precise instruction. Keep its trigger, action, exception, done condition, and necessary reason. Use the narrowest existing scope that reaches the task; do not move a local rule into every session just to remove a file.
5. Cut unnecessary pointers and compress the remaining sentences. Re-read the result for lost meaning, then repeat from whole files. Stop only when another deletion would remove necessary behavior or an explicit user constraint.

Deletion precedes relocation. A new hook, skill, rule tree, or compatibility copy requires an independent need. One line can remain in the existing file; it does not need a new heading, wrapper, or reference document.

## Pointer accounting

An import loads a destination through the host. A prose-read asks the agent to open it. Both can spend the destination's full tokens; shortening the caller proves no saving by itself. Follow reachable destinations with a visited set so cycles terminate. Count shared content once in the source inventory, but every actual load in a task budget.

Keep a pointer only for a necessary destination that the active tool does not already supply. Give conditional reads a task or path trigger and one destination. The trigger's wording decides when the agent reads the destination: when a weak trigger misses a necessary destination, sharpen the trigger first, and inline the destination only if a sharp trigger still misses it. Remove vague requests for more context and lists of advertised skills. Inline what every task path needs, and keep behind a conditional pointer what only some paths reach; either move must lower the relevant task budget. Delete an inlined source only when it is owned, redundant, and has no other consumers.

A model-invoked skill's `description` is a pointer that every session loads. When no task needs the agent to start a skill on its own and no other skill starts it, make it user-invoked in every tool in use (`Skills across tools` in `references/tool-matrix.md`); its description then leaves the listing. In a description that stays, put the trigger word first, give one trigger per distinct case, merge synonyms, and cut what the body already says.

Add an agent pointer to a human document only when a task needs it. Put token estimates and deletion reasons in the audit summary, not in the resulting instructions.

The scanners warn at 60 root lines, 200 lines per file, and 32768 bytes in a chain. These are diagnostic limits, not targets or proof of what an installed host loaded. Pointer warnings are at most five in a root file, at most twelve in any file, and eight times a file's own tokens in undecidable reading. Continue deleting below these limits.

## Measurement

Capture these before editing and again over the same scope:

- Owned Markdown: file count, bytes, and estimated tokens across the original files plus any additions. Include moved text, skill references, and agent-facing destinations. Identify generated copies separately.
- Loaded context: estimated tokens for each active tool and representative task path, including ancestor instructions and expanded imports. Use the same tasks before and after. Count conditional destinations on the tasks that trigger them.
- Requested reading: destination tokens and undecidable tokens from prose pointers. Trace further reads instead of treating a pointer as a free line.

Use the same estimator for both snapshots. `vitals.py` uses approximately characters / 4 and may miss surfaces. Its `context_tokens` is an inventory sum, despite the text report's “always-on” label; scoped files are not all loaded in every session. Report this sum as an inventory estimate, not as measured prompt usage. Missing loader evidence remains unknown, not zero.

## Scanner states

- `healthy`: no heuristic fired; still perform the deletion sequence.
- `bloated`: over a size warning; delete before splitting.
- `derivable`: potentially recoverable from the repository; check whether a non-obvious exception remains.
- `redundant`: duplicated or enforced elsewhere; verify scope and enforcement before cutting.
- `stale`: a path, command, or claim no longer matches reality; delete unless necessary to repair.
- `misplaced`: may belong in a narrower scope; first decide whether it needs to exist.
- `redirect`: unnecessary or expensive requested reading; audit caller and destination together.

## Wiring defects

The numbers below preserve `intake.sh` diagnostic references. They are investigation prompts, not a requirement to support every tool. Consult the relevant section of `references/tool-matrix.md`; preserve the smallest arrangement supported by the tools in use.

1. Duplicate `CLAUDE.md` body or prose masquerading as an import. Prefer `AGENTS.md`. A unique `CLAUDE.md` body hides `AGENTS.md` from Claude Code by default.
2. Leftover Claude-only file. Prefer `AGENTS.md`. Delete a `CLAUDE.md` pointer, symlink, or unique body after moving survivors into `AGENTS.md`. Do not add a `CLAUDE.md`. A `CLAUDE.local.md` on the path hides `AGENTS.md` unless Project instructions is `claude-md-and-agents-md`.
3. Import inside a code span or fence. Unfence a necessary import; otherwise delete it.
4. Wrong Cursor extension. Check the active loader before renaming or deleting.
5. Duplicate rule bodies across trees. Keep one source; retain adapters only for demonstrated reach.
6. Tool-specific rules unreachable by another active tool. Use an existing shared scope before adding a pointer.
7. Handbook outside a load path. Remove agent-only noise or repair necessary reach; leave human notes alone.
8. Dead `paths` or `globs`. Remove the rule or repair the necessary scope.
9. Required rule below the launch directory. Verify task reach before changing its scope.
10. Gitignored instruction. Distinguish deliberate personal context from a missing shared rule.
11. Configuration loads an already loaded file. Remove the duplicate include.
12. Second per-tool handbook. Delete duplicate text; preserve required tool-specific entry points.
13. Missing context target or dangling symlink. Repair a necessary reference or remove it.

## Budget defects

14. Ancestor chain exceeds the configured host budget. Delete unnecessary content before considering scoped loading.
15. File exceeds a size warning. Reduce content rather than splitting it to pass a line count.
16. Repeated preamble in a fan-out. Keep only necessary instructions at their existing shared scope.
17. Unscoped rule repeats loaded instructions. Delete the copy.
18. Native rule exceeds its host limit. Reduce it and verify the installed limit.

## Content defects

19. Nested instruction conflicts with its parent. Preserve explicit requirements and resolve the exception beside the governing rule.
20. Command drift. Verify the real task runner; retain only necessary command exceptions.
21. Dead pointer. Delete it unless the destination is needed for a concrete task.
22. Unreferenced document. No finding for human documentation; delete unused owned agent-only material after checking consumers.
23. Generic advice. Delete it instead of converting it into more rules.
24. Assumed enforcement. Verify the specific check; do not create enforcement merely to delete prose.

## Source defects

25. Missing skill link. Repair only if the skill is needed by an active tool.
26. Diverged generated copies. Change the owned source and regenerate.
27. Hand-edited generated or vendored surface. Preserve local changes and identify the correct source.
28. Colliding skill names. Resolve the active lookup before removing a copy.
29. Duplicate Claude entry points. Keep only those necessary for the active load path.
30. Extra handbook names. Remove redundant owned copies without losing unique instructions.
31. Committed auto-memory. Separate personal state from required project context; do not delete human notes by filename alone.
32. Extra `CONTEXT.md` handbook. Remove redundant instructions after checking configured imports.
33. Dead Copilot `applyTo`. Remove or repair only the required rule.
34. `CLAUDE.md` symlink duplicates a loaded body. Delete it so Claude Code reads `AGENTS.md`. Grok loads a symlink as a second copy.
35. Skill adapter pasted into a handbook. Delete the paste when the active skill already supplies it.

## Redirect defects

36. Ordered reading chain. Remove unnecessary reads; retain dependencies the task actually needs.
37. Vague read trigger. Replace with a concrete task trigger or delete.
38. Too many destinations. Audit necessity; the pointer cap is not a quota.
39. High reading amplification. Reduce the reachable content, not just the caller.
40. Context-system narration. Delete unless it compensates for a verified loading failure.
41. Short destination. Compare inline and conditional cost before moving text; preserve other consumers.
42. Pointer repeats a listed skill trigger. Delete when the active tool already advertises it.

## Acceptance

1. Reconstruct what each baseline task receives after the edit. Every necessary action, approval, prohibition, exception, and literal command remains available when needed. Unrelated tasks gain no newly unconditional reading. Verify reach before consolidating across scopes.
2. Revisit every surviving file, section, and decision. Attempt one more deletion or merge; retain it only with the evidence described above. Scanner health, a line cap, or an arbitrary percentage is never the stopping point. An unresolved scope prevents a claim of exhaustive reduction.
3. Count the same original source inventory plus all additions and destinations. Owned Markdown tokens must fall for a Markdown reduction; task context must not increase. Moving the body behind a compulsory pointer, hiding it in comments, or changing line wrapping does not qualify. Preserve non-context code and configuration unless separately authorized.
4. A no-change result requires evidence that each survivor is necessary, or that no context file is needed. Disclose required corrections that add tokens separately. Never manufacture cuts, hooks, adapters, or scaffolding to improve the headline.
5. Show target-codebase before/after costs, major deletions, preserved contracts, and unresolved findings. Strict helper results and reasoned task coverage are distinct from running an agent with reduced context. Claim the latter only after you execute and inspect it. Worked cases in `examples/reductions.md` calibrate judgment; handcrafted expected outputs do not measure autonomous performance.
