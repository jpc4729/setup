---
name: diagnose
description: "Finds a bug's cause from a command that shows the failure, then fixes it there. Use on diagnose, a bug, a failing or flaky test, a crash or a regression."
argument-hint: "[symptom, failing command or issue]"
disable-model-invocation: true
metadata:
  short-description: "Bug cause from a failing command"
---

# Diagnose

Find the cause of the bug the user names, fix it there, and prove the fix with the command that showed the failure. No theory before that command exists.

## The loop

1. Reproduce. Get one command that shows the user's symptom: a test, a script, a request or a CLI call. Run it and keep its failing output. Prefer the narrowest command, and seconds over minutes.
   No command reproduces it → stop. Report what you tried, and ask for the input, data, access or environment that would.
   Flaky → run it in a loop until it fails, and record the failure rate.
   Fails only after a restart or on one machine → suspect state before code: caches, build output, lock files, config, an old process or version.
2. Shrink. Remove inputs, steps and config one at a time while the command still fails.
3. Hypothesize. Write 3-5 causes, most likely first. For each, name the run whose result would disprove it.
4. Test. Do the cheapest disproving run first, one change at a time. Tag each debug log with one unique prefix, such as `[DEBUG-a4f2]`. For a slow path, measure a baseline first; logs do not show time.
   A change that "might help" is a hypothesis, not a fix. When a run disproves it, revert it.
5. Fix the cause, not the symptom: a guard that hides the crash is not a fix. Search for the same pattern and fix each place it occurs.
6. Prove. Run the step 1 command again; it must pass. Add it as a regression test where the repo keeps tests of that kind, else say why there is none.
7. Clean up. Remove every tagged log (search for the prefix), every scratch file and every reverted experiment.

## Report

- Cause: one sentence, with `path:line` and the run that proves it.
- The step 1 command, with its output before and after the fix.
- Each disproved hypothesis and the run that disproved it, one line each.
- Each other place you fixed, and each place you found and left, with the reason.
