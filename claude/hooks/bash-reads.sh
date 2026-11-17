#!/usr/bin/env bash
set -euo pipefail

# PreToolUse on Bash: refuses a `cat`, `sed` (not `-i`), `head`, `tail` (not
# `-f`) or `nl` that prints a file, because the rule to use Read with a line
# range does not hold as text alone. The command is split on `&&`, `||`, `;`
# and newlines, so `cd src && head x` is caught too. Only the command before
# the first pipe counts, so `sed -n 1,9p x | cut -c1-80` is caught, and so is
# `cat x | rg y`, which `rg y x` replaces. A part that still has a redirect
# after `2>/dev/null` and `2>&1` are taken out passes, and so does the whole
# command when it has a heredoc, whose body can hold `cat` or `sed` lines.
# Files under the temp folders and /dev pass, as does a path that starts with
# `$TMPDIR` or a variable that the same command sets from mktemp, from
# `scratch` or to a temp path, and a relative path after a `cd` to one. A
# keyword such as `do` or `then` is skipped, so a loop body is checked too.
# A separator or space inside quotes does not split, so a commit message that
# holds `; cat` passes. This hook is a nudge, not a sandbox: `sudo cat` or an
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
      [[ $name == tail && ($word == --follow* || ($word != --* && $word == *[fF]*)) ]] && return 1
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
      /tmp/* | /private/tmp/* | /var/folders/* | /dev/*) found=1 ;;
      \$*)
        found=1
        var=${word#\$}
        var=${var#\{}
        var=${var%%[!A-Za-z0-9_]*}
        [[ " $temp_vars " == *" $var "* ]] || temp_only=0
        ;;
      /* | ~*)
        found=1
        temp_only=0
        ;;
      *)
        found=1
        ((temp_cwd)) || temp_only=0
        ;;
    esac
  done
  ((found && ! temp_only))
}

{ payload=$(< /dev/stdin); } 2> /dev/null || payload=$(cat)
command=$(jq -r '([39] | implode) as $s
  | .tool_input.command // empty
  | gsub("(?<q>\($s)[^\($s)]*\($s)|\"[^\"]*\")"; .q | gsub("[;&|<> \n]"; "."))' <<< "$payload" 2> /dev/null) || exit 0
[[ -z $command || $command == *"<<"* ]] && exit 0

# Variables that hold a temp path: TMPDIR, and each name this command sets
# from mktemp or scratch, or to a temp path, such as `d=$(mktemp -d)`.
temp_vars="TMPDIR"
rest=$command
temp_re=$'([A-Za-z_][A-Za-z0-9_]*)=["\']?(\\$\\((mktemp|scratch)|/tmp/|/private/tmp/|/var/folders/)(.*)'
while [[ $rest =~ $temp_re ]]; do
  temp_vars+=" ${BASH_REMATCH[1]}"
  rest=${BASH_REMATCH[4]}
done

# 1 after a `cd` to a temp folder, so a relative path is a temp path.
temp_cwd=0
parts=${command//&&/$'\n'}
parts=${parts//||/$'\n'}
parts=${parts//;/$'\n'}
while IFS= read -r part; do
  part=${part%%|*}
  part=${part//2>\/dev\/null/}
  part=${part//2> \/dev\/null/}
  part=${part//2>&1/}
  read -r -a words <<< "$part"
  # A keyword such as `do` starts the part in a loop or an if.
  while ((${#words[@]})); do
    case ${words[0]} in
      do | then | else | '{' | '!') words=("${words[@]:1}") ;;
      *) break ;;
    esac
  done
  [[ ${#words[@]} -eq 0 ]] && continue
  if [[ ${words[0]} == cd ]]; then
    # The folder is the first word that is not an option. A bare `cd` and
    # `cd -` count as home. reads_file fails for a temp folder.
    dir=~
    for word in "${words[@]:1}"; do
      [[ $word == -* ]] || {
        dir=$word
        break
      }
    done
    if reads_file cat "$dir"; then temp_cwd=0; else temp_cwd=1; fi
    continue
  fi
  [[ $part == *[\<\>]* ]] && continue
  if reads_file "${words[@]}"; then
    echo "Read the file with Read and a line range (offset and limit), or find the lines with \`rg -n\` first." >&2
    exit 2
  fi
done <<< "$parts"
exit 0
