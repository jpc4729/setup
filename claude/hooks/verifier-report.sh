#!/usr/bin/env bash
set -euo pipefail

# SubagentStop on verifier: the report must keep the line format in
# agents/verifier.md, so the parent reads the same shape every run, and the
# verdict must follow from the lines. Exit 2 sends the report back once with
# the reasons; on the retry stop_hook_active is true and the report goes
# through as it is, so a stuck verifier still returns. Any other failure, such
# as bad JSON or no jq, lets the report through: this gate checks a format,
# and a broken gate must not lose a report.

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
report=$(jq -r '
  if .agent_type != "verifier" or .stop_hook_active == true then empty
  else .last_assistant_message // empty end' <<< "$payload") || exit 0
[[ -z $report ]] && exit 0

reason=$(awk '
  function bad(msg) { if (++nbad <= 5) out = out "\n- Line " NR ": " msg }
  /^[[:space:]]*$/ { next }
  { last = $0; plain = $0; gsub(/`[^`]*`/, "", plain) }
  plain ~ /\*\*/ { bad("has bold text.") }
  /^(C[1-9][0-9]*|R[1-3])[a-z]* (PASS|FAIL|BLOCKED|UNCLEAR): / { claims++; if ($2 != "PASS:") open++; next }
  /^(MISSING|EXTRA|WRONG): / { gaps++; next }
  /^SCOPE: exact$/ { exact++; next }
  /^PRE-EXISTING: / { next }
  /^VERDICT: (ready|not ready) \| / { verdicts++; verdict = $0; next }
  { bad("starts with none of C1 to Cn, R1 to R3, MISSING:, EXTRA:, WRONG:, SCOPE: exact, PRE-EXISTING: or VERDICT:.") }
  END {
    if (nbad > 5) out = out "\n- " (nbad - 5) " more lines like these."
    if (claims == 0) out = out "\n- No claim line, such as `C1 PASS: <claim> | proof: <proof> | evidence: <evidence>`."
    if (exact + gaps == 0) out = out "\n- No scope line: write `SCOPE: exact` or one MISSING, EXTRA or WRONG line per gap."
    if (exact > 0 && gaps > 0) out = out "\n- `SCOPE: exact` and a scope gap line are both there."
    if (verdicts != 1) out = out "\n- Write exactly one `VERDICT: ready | <why>` or `VERDICT: not ready | <why>` line."
    else if (last != verdict) out = out "\n- The VERDICT line must be the last line."
    else if (nbad > 0) out = out "\n- After you fix these lines, set the VERDICT from them."
    else if (verdict ~ /^VERDICT: ready/ && (open > 0 || exact == 0)) out = out "\n- `VERDICT: ready` needs each claim `PASS` and `SCOPE: exact`; write `VERDICT: not ready`."
    else if (verdict ~ /^VERDICT: not ready/ && open == 0 && exact > 0) out = out "\n- Each claim is `PASS` and the scope is exact; write `VERDICT: ready`."
    printf "%s", out
  }' <<< "$report")

[[ -z $reason ]] && exit 0
printf 'Rewrite your report in the Report format of your instructions. Change only the format and the VERDICT line, not the findings:%s\n' "$reason" >&2
exit 2
