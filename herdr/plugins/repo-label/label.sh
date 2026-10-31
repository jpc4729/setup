#!/bin/sh
# herdr labels a workspace with the git checkout folder of its first pane. In
# ~/.local/src/<owner>/<repo>/<folder> that is `main` or the branch folder,
# which the branch line under the label already shows. Rename each such
# workspace to <repo>. Rename it again when that pane moves to another repo,
# because its label is then still a repo name from ~/.local/src. Any other
# label is a name you gave it, and stays. Out of ~/.local/src, nothing changes.
set -eu

herdr=${HERDR_BIN_PATH:-herdr}
src="$HOME/.local/src/"
tab=$(printf '\t')

# True when ~/.local/src/<owner>/<name> is a folder for some owner.
is_repo() {
  case $1 in '' | . | .. | */*) return 1 ;; esac
  for dir in "$src"*/"$1"; do
    [ -d "$dir" ] && return 0
  done
  return 1
}

# The first pane in the list is the one herdr takes the label from. Its cwd is
# the shell's folder, not the folder of a command running in it.
{
  "$herdr" workspace list
  "$herdr" pane list
} | jq -rs --arg src "$src" '
  (.[0].result.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $label
  | .[1].result.panes | unique_by(.workspace_id)[]
  | (.cwd // "") as $cwd
  | select($cwd | startswith($src))
  | ($cwd | ltrimstr($src) | split("/")) as $p
  | select(($p | length) >= 3)
  | [.workspace_id, $p[1], $p[2], $label[.workspace_id]] | @tsv' |
  while IFS=$tab read -r id repo folder label; do
    [ "$label" != "$repo" ] || continue
    if [ "$label" = "$folder" ] || is_repo "$label"; then
      # A workspace can close during the run; go on with the others.
      "$herdr" workspace rename "$id" "$repo" > /dev/null || continue
    fi
  done
