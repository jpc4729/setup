---
name: diagnose
description: "Finds a bug's cause from a command that shows the failure, then fixes it there."
argument-hint: "[symptom, failing command or issue]"
disable-model-invocation: true
metadata:
  short-description: "Bug cause from a failing command"
---

# Diagnose

Find the cause of the bug the user names, fix it there, and prove the fix with the command that showed the failure. If you catch yourself reading code for a theory before that command exists, stop and build the command. With no argument, take the failure this conversation last showed; when there is none, ask for the symptom and how to see it.

## The loop

1. Reproduce. Get one command that goes red on the user's exact symptom, not on a nearby failure: a test, a script, a request or a CLI call. Run it and keep its failing output. Prefer the narrowest command, and seconds over minutes.
   No command reproduces it → force it: build the trigger input, tighten the conditions (timing, size, concurrency) or add tagged logs until it fires. Still nothing → stop. Report what you tried, and ask for the input, data, access or environment that would.
   Flaky → run it in a loop until it fails, and record the failure rate.
   Fails only after a restart or on one machine → suspect state before code: caches, build output, lock files, config, an old process or version.
2. Shrink. Remove half of the inputs, steps and config at a time while the command stays red, and one at a time when few remain, until every part left is load-bearing: removing any one turns it green.
3. Hypothesize. Write 3-5 causes, most likely first. For each, name the run whose result would disprove it. A cause with no such run is a guess: sharpen it or drop it. A cause the user names is one of them and gets its own disproving run. Show the list to the user, then start testing without waiting.
4. Test. Do the cheapest disproving run first, one change at a time. Tag each debug log with one unique prefix, such as `[DEBUG-a4f2]`. For a slow path, measure a baseline first; logs do not show time.
   A change that "might help" is a hypothesis, not a fix. When a run disproves it, revert it.
5. Fix the cause, not the symptom: a guard that hides the crash is not a fix. Search for the same pattern and fix each place it occurs.
6. Prove. Run the step 1 command again; it must go green. Add it as a regression test where the repo keeps tests of that kind, at a place that runs the real bug path (the same callers and chain). When no such place exists, report that as a finding; when the repo keeps no such tests, say why there is none.
7. Clean up. Remove every tagged log (search for the prefix), every scratch file and every reverted experiment.

## Report

- Cause: one sentence, with `path:line` and the run that proves it.
- The step 1 command, with its output before and after the fix.
- Each disproved hypothesis and the run that disproved it, one line each.
- Each other place you fixed, and each place you found and left, with the reason.
