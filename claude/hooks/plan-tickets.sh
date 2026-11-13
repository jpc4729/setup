#!/usr/bin/env bash
set -euo pipefail

# SubagentStop on planner: shows you the plan path and the ticket lines of the
# planner's report, because only the main session sees that report, and the
# rule to list the tickets did not hold as text alone. It prints a
# `systemMessage`, which Claude Code shows to you, not to the model. A line
# counts when, after list marks, `*`, backticks and a `TICKETS:` label, it
# starts with `PATH:` or `T<n>`. A report with no ticket line, such as `NO PLAN:`, shows nothing. Any
# failure, such as bad JSON or no jq, shows nothing and never stops the planner.

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
jq -c '[.last_assistant_message // "" | splits("\n")
    | gsub("[`*]"; "") | sub("^[\\s>-]+"; "") | sub("^TICKETS:\\s*"; "")
    | select(test("^(PATH:|T[0-9]+\\b)"))]
  | select(any(.[]; test("^T[0-9]")))
  | {systemMessage: join("\n")}' <<< "$payload" 2> /dev/null || true
