#!/usr/bin/env bash
set -euo pipefail

# PreToolUse on Agent: scout, planner and reviewer may start a Haiku `clerk`,
# and worker and verifier a `clerk` or a `browser`, and nothing else. Claude
# Code ignores the type list in `Agent(...)` inside subagent frontmatter, so
# the rule lives here. A `model` override is refused too, because it outranks
# the agent's own `model`. The main session (no agent_id) may start any agent
# on Fable, but only with `Fable: <reason>` as the first line of the brief,
# the Fable rule in CLAUDE.md. No subagent may start an agent on Fable. Every
# other agent keeps its usual Agent tool. Exit 2 blocks the call and shows the
# reason to the agent that made it. Any other failure, such as bad JSON or no
# jq, lets the call through: this gate limits spend, and a broken gate must
# not stop the main session's agents.

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
reason=$(jq -r '
  (.tool_input.subagent_type // "" | if . == "" then "general-purpose" else . end) as $type
  | (if .agent_type | IN("worker", "verifier") then ["clerk", "browser"] else ["clerk"] end) as $allowed
  | if (.agent_id // "") == "" then
    if (.tool_input.model // "" | test("fable"; "i") | not) then empty
    elif (.tool_input.prompt // "" | split("\n")[0] | test("^Fable: \\S") | not) then
      "Make `Fable: <reason>` the first line of the brief, with a reason from the Fable rule in CLAUDE.md, or start the \($type) without the model override. It runs on Opus."
    else empty end
  elif (.tool_input.model // "" | test("fable"; "i")) then
    "Only the main session starts an agent on Fable. Start the \($type) without the model override."
  elif (.agent_type | IN("scout", "worker", "verifier", "planner", "reviewer") | not) then empty
  elif ($type | IN($allowed[]) | not) then
    "A \(.agent_type) starts only a \($allowed | join(" or a ")), not \($type). Do that work yourself."
  elif (.tool_input.model // "") != "" then
    "Start the \($type) without a model override; it runs on its own model."
  else empty end' <<< "$payload")

[[ -z $reason ]] && exit 0
echo "$reason" >&2
exit 2
