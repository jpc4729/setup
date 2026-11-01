#!/bin/sh
# shellcheck shell=sh  # herdr runs it with sh
# herdr labels a workspace with the git checkout folder of its first pane. In
# ~/.local/src/<owner>/<repo>/<folder> that is `main` or the branch folder,
# which the branch line under the label already shows. Rename each such
# workspace to <repo>. Out of ~/.local/src, give back the label herdr gives
# that folder, because herdr cannot clear a name: a new workspace opens in the
# folder of the last one, so it gets that repo's name before you cd away.
# Rename only herdr's own label, a repo name from ~/.local/src or the last name
# this script set. Any other label is a name you gave it, and stays.
set -eu

herdr=${HERDR_BIN_PATH:-herdr}
src="$HOME/.local/src/"
state=${HERDR_PLUGIN_STATE_DIR:-$HOME/.local/state/herdr/plugins/local.repo-label}
tab=$(printf '\t')
mkdir -p "$state"

# True when ~/.local/src/<owner>/<name> is a folder for some owner.
is_repo() {
  case $1 in '' | . | .. | */*) return 1 ;; esac
  for dir in "$src"*/"$1"; do
    [ -d "$dir" ] && return 0
  done
  return 1
}

# The label herdr gives a folder: its git checkout folder, else the folder
# itself, and ~ for $HOME.
herdr_label() {
  top=$(git -C "$1" rev-parse --show-toplevel 2> /dev/null) || top=$1
  if [ "$top" = "$HOME" ]; then
    printf '%s\n' '~'
  else
    basename "$top"
  fi
}

# The first pane in the list is the one herdr takes the label from. Its cwd is
# the shell's folder, not the folder of a command running in it. Out of
# ~/.local/src/<owner>/<repo>/<folder>, repo and folder are "/", which no
# folder name can be. The label goes last: read drops an empty field.
{
  "$herdr" workspace list
  "$herdr" pane list
} | jq -rs --arg src "$src" '
  (.[0].result.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $label
  | .[1].result.panes | unique_by(.workspace_id)[]
  | select((.cwd // "") != "")
  | (.cwd | ltrimstr($src) | split("/")) as $p
  | (if (.cwd | startswith($src)) and ($p | length) >= 3 then $p[1:3] else ["/", "/"] end) as $rf
  | [.workspace_id, $rf[0], $rf[1], .cwd, $label[.workspace_id]] | @tsv' |
  while IFS=$tab read -r id repo folder cwd label; do
    last=$(cat "$state/$id" 2> /dev/null) || last=/
    { [ "$repo" != / ] && [ "$label" = "$folder" ]; } ||
      [ "$label" = "$last" ] || is_repo "$label" || continue
    if [ "$repo" != / ]; then
      want=$repo
    else
      want=$(herdr_label "$cwd")
    fi
    [ "$label" != "$want" ] || continue
    # A workspace can close during the run; go on with the others.
    "$herdr" workspace rename "$id" "$want" > /dev/null || continue
    printf '%s\n' "$want" > "$state/$id"
  done
