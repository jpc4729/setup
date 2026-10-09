---
name: wayfinder
description: "Charts an idea too big for one session as a map of open decisions in a local file, then resolves one decision per session until the way to the goal is clear."
argument-hint: "[idea | map path [question]]"
disable-model-invocation: true
metadata:
  short-description: "Decision map for work bigger than one session"
---

# Wayfinder

Find the way to a goal that is too big and too unclear for one session. Decide; do not build. The map is done when nothing is left to decide before the work starts. When you want to start the work, the map is probably done.

## The map

One file outside the repository, so nothing commits it: `~/.local/state/maps/<repo>/<slug>.md`. `<repo>` is the repo root's folder name without a leading dot; `<slug>` is two or three words from the idea.

```markdown
# Map: <slug>

Goal: <what done looks like: a spec, a decision or a change; 2 lines at most>
Notes: <constraints, sources to read, standing preferences>

## Decisions

- Q<n> <question>: <answer, one line>. Evidence: <path:line, URL, or the user and the date>

## Open

- Q<n> <question>: <ask | research | try | task>, after: <Q numbers, or none>

## Fog

- <a question you can see coming but cannot yet state precisely>

## Out of scope

- <work past the goal>: <why>
```

- A question goes to Open when you can state it precisely now, even if it waits on another question. Otherwise it goes to Fog, as loosely as you see it. Keep fog coarse: one patch can become several questions, or none.
- Each decision lives in one place. An answer longer than one line goes to `<slug>/Q<n>.md` beside the map, linked from its decision line.
- To the user, name a question by its words, not only by its number.

## Question types

- `ask`: only the user can decide. Ask one question at a time, with the options, the evidence and your pick. Never answer for the user.
- `research`: a fact from code, docs, data or the web. Find it yourself and record the source.
- `try`: the question is how something looks or behaves. Make a cheap, rough sample (a sketch, a stub, a sample output) under one `mktemp -d` directory, show it, and let the user decide.
- `task`: a step that must happen before a decision, such as access, an account or sample data. Do it when you can; else give the user numbered steps. Record what was done and the facts that later questions need.

## Chart (argument: an idea)

1. Settle the goal with the user first; it sets the scope.
2. List the open decisions across the whole idea, broad before deep. Research what a read can answer before you ask.
3. If no fog remains and the work fits one session, say so and stop. No map.
4. Write the map. Leave Decisions empty.
5. Stop; charting resolves nothing. Report the map path and the first open questions.

## Work (argument: a map path, optional question)

1. Read the map. Without a path, use the only map in `~/.local/state/maps/<repo>/`, or ask which one when there are several.
2. Take the question the user names, else the first one in Open whose `after` questions are all decided.
3. Resolve it by its type.
4. Move it to Decisions with its answer and evidence.
5. Update the map: add new precise questions to Open; move fog that is now precise to Open and delete it from Fog; move work past the goal to Out of scope with the reason; change or delete each question the answer makes wrong.
6. Stop after one question; `research` questions are the exception. Report the decision and the next open question.

When Open and Fog are empty, the way is clear. Say so, and name the next step: the work itself, or the `planner` for more than one sitting. Delete the map only when the user asks.
