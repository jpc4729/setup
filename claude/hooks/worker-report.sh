#!/usr/bin/env bash
set -euo pipefail

# SubagentStop on worker: the report's first line must start with `Done`,
# `Partly done`, `Blocked` or `Answer:`, the outcome the parent acts on, as
# worker.md asks. Exit 2 sends the reason back to the worker, which then writes
# the report again. It blocks once: with `stop_hook_active` set, the worker
# stops whatever it wrote. List marks, `#`, `*` and backticks before the word
# do not count. Any failure, such as bad JSON, no jq or no
# `last_assistant_message`, lets the worker stop.

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
reason=$(jq -r '
  if .stop_hook_active == true or (.last_assistant_message | type) != "string" then empty
  else
    ([.last_assistant_message | splits("\n") | gsub("[`*]"; "") | sub("^[\\s>#-]+"; "")
      | select(. != "")] | first // "") as $first
    | if $first | test("^((done|partly done|blocked)\\b|answer:)"; "i") then empty
    else "Start the first line of your report with `Done`, `Partly done`, `Blocked` or `Answer:`, then write the whole report again." end
  end' <<< "$payload" 2> /dev/null) || exit 0

[[ -z $reason ]] && exit 0
echo "$reason" >&2
exit 2
