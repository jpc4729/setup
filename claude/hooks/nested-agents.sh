#!/usr/bin/env bash
set -euo pipefail

# PreToolUse on Agent: scout, worker, verifier and planner may start a Haiku
# `clerk`, and nothing else. Claude Code ignores the type list in `Agent(...)`
# inside subagent frontmatter, so the rule lives here. A `model` override is
# refused too, because it outranks the clerk's own `model`. The main session
# (no agent_id) and every other agent keep their usual Agent tool. Exit 2
# blocks the call and shows the reason to the agent that made it. Any other
# failure, such as bad JSON or no jq, lets the call through: this gate limits
# spend, and a broken gate must not stop the main session's agents.

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
reason=$(jq -r '
  if (.agent_id // "") == "" then empty
  elif (.agent_type | IN("scout", "worker", "verifier", "planner") | not) then empty
  elif (.tool_input.subagent_type // "") != "clerk" then
    "A \(.agent_type) starts only a clerk, not \(.tool_input.subagent_type // "" | if . == "" then "general-purpose" else . end). Do that work yourself."
  elif (.tool_input.model // "") != "" then
    "Start the clerk without a model override; it runs on Haiku."
  else empty end' <<< "$payload")

[[ -z $reason ]] && exit 0
echo "$reason" >&2
exit 2
