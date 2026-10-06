#!/usr/bin/env bash
# Claude Code Status Line
# Format: profile | dir | branch | model effort | used/total tokens | limits | cache | +lines/-lines | age

# The config dir name, read at runtime so one file serves every profile that
# CLAUDE_CONFIG_DIR selects.
PROFILE="$(basename "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")"
PROFILE="${PROFILE#.}"
PROFILE="${PROFILE//[[:cntrl:]]/}"

set -euo pipefail

input=$(cat)

# Extract values in one jq call. The statusline runs often, so avoid
# repeated parser startup for each field. Fields are split on \x1f, which
# IFS does not collapse, so an empty field keeps its place. clean drops
# control characters, so a name can neither break the split nor print an
# escape sequence.
IFS=$'\x1f' read -r cwd model ctx_size lines_added lines_removed input_tokens cache_create cache_read duration_ms effort \
  five_pct five_reset week_pct week_reset cache_seen cache_expires < <(
    jq -r '
    def clean: gsub("[[:cntrl:]]"; "");
    [
      (.cwd // "" | clean),
      (.model.display_name // .model.name // "claude" | clean),
      (.context_window.context_window_size // 0),
      (.cost.total_lines_added // 0),
      (.cost.total_lines_removed // 0),
      (.context_window.current_usage.input_tokens // 0),
      (.context_window.current_usage.cache_creation_input_tokens // 0),
      (.context_window.current_usage.cache_read_input_tokens // 0),
      ((.cost.total_duration_ms // 0) | floor),
      (.effort.level // "" | clean),
      (.rate_limits.five_hour.used_percentage // -1 | round),
      (.rate_limits.five_hour.resets_at // 0 | floor),
      (.rate_limits.seven_day.used_percentage // -1 | round),
      (.rate_limits.seven_day.resets_at // 0 | floor),
      (.prompt_cache.caching_observed // false),
      (.prompt_cache.expires_at // 0 | floor)
    ] | map(tostring) | join("\u001f")
  ' <<< "$input"
  )

# Colors, as real escape bytes: the line prints with %s, so a backslash
# sequence in a name stays text, not a live terminal escape such as an OSC 52
# clipboard write.
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# Directory (basename, ~ for home)
dir=""
if [[ -n "$cwd" ]]; then
  dir="${cwd/#$HOME/\~}"
  dir=$(basename "$dir")
fi

# Git branch, or the short SHA when detached, read from HEAD so a render starts
# no git process. A .git file points to a worktree's or submodule's git dir. A
# reftable repo keeps a placeholder HEAD, so only then git answers.
branch=""
repo=""
[[ -n "$cwd" ]] && cd -P -- "$cwd" 2> /dev/null && repo=$PWD
while [[ -n "$repo" && ! -e "$repo/.git" ]]; do
  repo=${repo%/*}
done
if [[ -n "$repo" ]]; then
  gitdir="$repo/.git"
  if [[ -f "$gitdir" ]]; then
    read -r gitdir < "$gitdir"
    gitdir=${gitdir#gitdir: }
    [[ "$gitdir" == /* ]] || gitdir="$repo/$gitdir"
  fi
  if read -r head 2> /dev/null < "$gitdir/HEAD"; then
    case "$head" in
      "ref: refs/heads/.invalid")
        branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2> /dev/null ||
          git -C "$cwd" rev-parse --short HEAD 2> /dev/null || true)
        ;;
      "ref: refs/heads/"*) branch=${head#ref: refs/heads/} ;;
      *) branch=${head:0:7} ;;
    esac
  fi
fi
# HEAD is a plain file, so a crafted repo could put an escape sequence in it.
branch=${branch//[[:cntrl:]]/}

# Model shortname
model_short=""
case "$model" in
  *[Oo]pus*) model_short="opus" ;;
  *[Ss]onnet*) model_short="sonnet" ;;
  *[Hh]aiku*) model_short="haiku" ;;
  *[Ff]able*) model_short="fable" ;;
  *) model_short="${model:0:8}" ;;
esac

# Reasoning effort level — dimmed suffix on the model (absent when the
# selected model has no effort parameter, so the segment stays clean).
effort_display=""
[[ -n "$effort" ]] && effort_display=" ${DIM}$effort${RESET}"

# Format token count as human-readable (e.g. 45.2k, 1.0M)
fmt_tokens() {
  local n=$1
  local whole tenths

  if ((n >= 1000000)); then
    whole=$((n / 1000000))
    tenths=$(((n % 1000000) / 100000))
    printf "%d.%dM" "$whole" "$tenths"
  elif ((n >= 1000)); then
    whole=$((n / 1000))
    tenths=$(((n % 1000) / 100))
    printf "%d.%dk" "$whole" "$tenths"
  else
    printf "%d" "$n"
  fi
}

# Context tokens — used_tokens is the input-only sum that matches used_percentage
used_tokens=$((input_tokens + cache_create + cache_read))
# The JSON's context_window_size always reports the model's native window (1M),
# even when CLAUDE_CODE_AUTO_COMPACT_WINDOW lowers the effective ceiling — use
# the override as /max so the display matches where auto-compact actually fires.
ctx_max=$ctx_size
if [[ "${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}" =~ ^[0-9]+$ ]] &&
  ((CLAUDE_CODE_AUTO_COMPACT_WINDOW > 0 && CLAUDE_CODE_AUTO_COMPACT_WINDOW < ctx_size)); then
  ctx_max=$CLAUDE_CODE_AUTO_COMPACT_WINDOW
fi
ctx_display=""
if ((ctx_max > 0)); then
  pct_int=$((used_tokens * 100 / ctx_max))
  # Color based on usage percentage
  if ((pct_int >= 80)); then
    ctx_color="$RED"
  elif ((pct_int >= 50)); then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  ctx_display="${ctx_color}$(fmt_tokens "$used_tokens")${RESET}${DIM}/${RESET}$(fmt_tokens "$ctx_max")"
fi

# Time from now to epoch second $1, as 2d3h, 1h05m or 7m; empty once past.
now=""
countdown() {
  [[ -n "$now" ]] || now=${EPOCHSECONDS:-$(date +%s)}
  local left=$(($1 - now)) h m
  countdown_text=""
  if ((left <= 0)); then
    return 0
  fi
  h=$((left / 3600))
  m=$((left % 3600 / 60))
  if ((h >= 24)); then
    countdown_text="$((h / 24))d$((h % 24))h"
  elif ((h > 0)); then
    printf -v countdown_text '%dh%02dm' "$h" "$m"
  else
    countdown_text="${m}m"
  fi
}

# Rate limits show only from 50% used, when they start to matter: yellow,
# red from 75%, with the time until the window resets.
limits_display=""
add_limit() {
  local label=$1 pct=$2 reset_at=$3 color=$YELLOW
  if ((pct < 50)); then
    return 0
  fi
  if ((pct >= 75)); then
    color=$RED
  fi
  countdown "$reset_at"
  [[ -n "$limits_display" ]] && limits_display+=" "
  limits_display+="${color}${label} ${pct}%${RESET}"
  if [[ -n "$countdown_text" ]]; then
    limits_display+="${DIM} ↻${countdown_text}${RESET}"
  fi
}
add_limit 5h "$five_pct" "$five_reset"
add_limit 7d "$week_pct" "$week_reset"

# Prompt cache, only in its last 5 minutes and once it has expired: after
# that, the next message sends the whole conversation again, slower and
# at full price.
cache_display=""
if [[ "$cache_seen" == "true" ]] && ((cache_expires > 0)); then
  countdown "$cache_expires"
  if [[ -z "$countdown_text" ]]; then
    cache_display="${RED}cache expired${RESET}"
  elif ((cache_expires - now < 300)); then
    [[ "$countdown_text" == "0m" ]] && countdown_text="<1m"
    cache_display="${YELLOW}cache ${countdown_text}${RESET}"
  fi
fi

# Lines changed
lines_display=""
if [[ "$lines_added" != "0" || "$lines_removed" != "0" ]]; then
  lines_display="${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
fi

# Session age. Long unattended runs are the failure this setup guards
# against, so the segment turns yellow past one hour and red past three.
age_display=""
if ((duration_ms >= 60000)); then
  mins=$((duration_ms / 60000))
  if ((mins >= 180)); then
    age_color="$RED"
  elif ((mins >= 60)); then
    age_color="$YELLOW"
  else
    age_color="$DIM"
  fi
  if ((mins >= 60)); then
    age_display="${age_color}$((mins / 60))h$(printf '%02d' $((mins % 60)))m${RESET}"
  else
    age_display="${age_color}${mins}m${RESET}"
  fi
fi

# Build output — profile tag first so you always know which config dir is active
out="${MAGENTA}${PROFILE}${RESET}"
[[ -n "$dir" ]] && out="$out ${DIM}|${RESET} $dir"
[[ -n "$branch" ]] && out="$out ${DIM}|${RESET} $branch"
[[ -n "$model_short" ]] && out="$out ${DIM}|${RESET} ${CYAN}$model_short${RESET}$effort_display"
[[ -n "$ctx_display" ]] && out="$out ${DIM}|${RESET} $ctx_display"
[[ -n "$limits_display" ]] && out="$out ${DIM}|${RESET} $limits_display"
[[ -n "$cache_display" ]] && out="$out ${DIM}|${RESET} $cache_display"
[[ -n "$lines_display" ]] && out="$out ${DIM}|${RESET} $lines_display"
[[ -n "$age_display" ]] && out="$out ${DIM}|${RESET} $age_display"

printf '%s' "$out"
