#!/usr/bin/env bash
set -euo pipefail

# PreToolUse on Bash: refuses a bare `cat`, `sed` (not `-i`), `head`, `tail`
# or `nl` that prints a file, because the rule to use Read with a line range
# does not hold as text alone. The command is split on `&&`, `||`, `;` and
# newlines, so `cd src && head x` is caught too. A part with a pipe or a
# redirect passes, and so does the whole command when it has a heredoc, whose
# body can hold `cat` or `sed` lines. Files under the temp folders and /dev
# pass, as does a path that starts with a variable, such as a mktemp folder.
# A separator inside quotes does not split, so a commit message that holds
# `; cat` passes. This hook is a nudge, not a sandbox: `sudo cat` or an
# escaped quote gets past it. Exit 2 blocks the call and shows the reason. Any
# other failure, such as bad JSON or no jq, lets the call through.

# Arguments: the words of one simple command. Succeeds when it prints a file
# outside the temp folders.
reads_file() {
  local name=$1 word value_opts="" options=1 skip=0 script_seen=0 found=0 temp_only=1
  shift
  case $name in
    cat) ;;
    head | tail) value_opts="n c b" ;;
    nl) value_opts="b d f h i l n s v w" ;;
    sed) value_opts="e f" ;;
    *) return 1 ;;
  esac
  for word in "$@"; do
    word=${word//\"/}
    word=${word//\'/}
    if ((skip)); then
      skip=0
      continue
    fi
    if ((options)) && [[ $word == -?* || ($name == tail && $word == +*) ]]; then
      if [[ $word == -- ]]; then
        options=0
        continue
      fi
      if [[ $name == sed ]]; then
        [[ $word == --in-place* || ($word != --* && $word == *[iI]*) ]] && return 1
        [[ $word == -e* || $word == -f* ]] && script_seen=1
      fi
      [[ ${#word} -eq 2 && " $value_opts " == *" ${word#-} "* ]] && skip=1
      continue
    fi
    if [[ $name == sed && $script_seen -eq 0 ]]; then
      script_seen=1
      continue
    fi
    case $word in
      -) ;;
      /tmp/* | /private/tmp/* | /var/folders/* | /dev/* | \$*) found=1 ;;
      *)
        found=1
        temp_only=0
        ;;
    esac
  done
  ((found && ! temp_only))
}

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
command=$(jq -r '([39] | implode) as $s
  | .tool_input.command // empty
  | gsub("(?<q>\($s)[^\($s)]*\($s)|\"[^\"]*\")"; .q | gsub("[;&|<>\n]"; " "))' <<< "$payload" 2> /dev/null) || exit 0
[[ -z $command || $command == *"<<"* ]] && exit 0

parts=${command//&&/$'\n'}
parts=${parts//||/$'\n'}
parts=${parts//;/$'\n'}
while IFS= read -r part; do
  [[ $part == *[\|\<\>]* ]] && continue
  read -r -a words <<< "$part"
  [[ ${#words[@]} -eq 0 ]] && continue
  if reads_file "${words[@]}"; then
    echo "Read the file with Read and a line range (offset and limit), or find the lines with \`rg -n\` first." >&2
    exit 2
  fi
done <<< "$parts"
exit 0
