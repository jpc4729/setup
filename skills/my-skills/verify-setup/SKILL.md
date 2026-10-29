---
name: verify-setup
description: "Writes or updates this repo's `.claude/skills/verify/SKILL.md`: how an agent starts the app, reaches each main surface and captures evidence."
argument-hint: "[surface to add or fix; default all]"
disable-model-invocation: true
metadata:
  short-description: "Repo recipe to prove a change works"
---

# Verify setup

Write the recipe that the `verifier`, the `worker` and `/run` follow to prove a change in this repo. When the file exists, read it first and change only what is wrong or missing. With an argument, do only that surface.

## The loop

1. Find how the repo starts: the dev, build and test commands, ports, env files, seed data and the services it needs.
2. Find each surface a change can reach: a page, an API route, a CLI command, a job.
3. Run each step yourself, from a clean start. Keep a step only after it works. A step that needs a password, hardware or a paid service goes under `Not covered`.
4. For each surface, write the shortest path to evidence: a URL with the agent-browser steps, one HTTP request, or a CLI call, and what a pass looks like.
5. Write `.claude/skills/verify/SKILL.md`, 80 lines at most, with `disable-model-invocation: true`. Stop each process you started.

## Recipe shape

- Start: the commands, the ready signal, how to stop.
- One section per surface: the path, the evidence to capture, what a pass looks like.
- Not covered: each surface with no agent check, and why.

## Report

- The path, each surface with the step that proved it, and each item under `Not covered`.
