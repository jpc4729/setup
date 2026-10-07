#!/usr/bin/env bash
# Install this setup into the agent homes under $HOME.
#
#   ./install.sh      install
#   ./install.sh -n   list what would change, write nothing
#
# Files are copied, never symlinked: every agent writes state into its home,
# and a symlink would carry those writes back into this repo.
# A replaced file is kept beside it as <name>.bak.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
dry=""
[[ "${1:-}" == "-n" ]] && dry="-nv"

for tool in jq yq rsync; do
  command -v "$tool" > /dev/null || {
    echo "install.sh: $tool is missing" >&2
    exit 1
  }
done

# The apps rewrite these files themselves, so they are merged, not copied:
# the keys here win, and every key the app wrote survives.
merged="claude/settings.json codex/config.toml grok/config.toml cursor/mcp.json cursor/cli-config.json"

# copy <repo dir> <home dir>
copy() {
  local excludes=() f
  for f in $merged; do
    [[ "${f%/*}" == "$1" ]] && excludes+=(--exclude "/${f##*/}")
  done
  # The managed policy is installed separately.
  [[ "$1" != codex ]] || excludes+=(--exclude "/requirements.toml")
  [[ -n "$dry" ]] || mkdir -p "$2"
  # A folder's README.md documents the repo, not the home.
  rsync -a ${dry:+"$dry"} --backup --suffix=.bak --exclude .DS_Store \
    --exclude /README.md ${excludes[@]+"${excludes[@]}"} "$repo/$1/" "$2/"
}

# Codex reads the managed macOS preference, not the user requirements file.
# Keep the expanded file for inspection.
codex_requirements() {
  local live="$HOME/.codex/requirements.toml" tmp encoded
  if [[ -n "$dry" ]]; then
    echo "expand codex/requirements.toml into $live"
    [[ "$(uname -s)" != Darwin ]] || echo "install com.openai.codex managed requirements preference"
    return
  fi
  tmp="$(mktemp)"
  sed "s|@HOME@|$HOME|g" "$repo/codex/requirements.toml" > "$tmp"
  if ! cmp -s "$tmp" "$live"; then
    [[ ! -f "$live" ]] || cp "$live" "$live.bak"
    install -m 600 "$tmp" "$live"
  fi
  rm -f "$tmp"
  if [[ "$(uname -s)" == Darwin ]]; then
    encoded="$(base64 < "$live" | tr -d '\n')"
    defaults write com.openai.codex requirements_toml_base64 "$encoded"
  fi
}

# merge <repo file> <home file>
merge() {
  local live="$2" tmp new=""
  if [[ -n "$dry" ]]; then
    echo "merge $1 into $live"
    return
  fi
  mkdir -p "$(dirname "$live")"
  tmp="$(mktemp)"
  # Codex expands neither ~ nor $HOME in its config.
  sed "s|@HOME@|$HOME|g" "$repo/$1" > "$tmp"
  # 0600: API-key headers get added to these files by hand. A new file still
  # goes through the merge, so the next run finds nothing to rewrite.
  [[ -f "$live" ]] || { install -m 600 "$tmp" "$live" && new=1; }
  # shellcheck disable=SC2016  # $f is a yq variable
  case "$live" in
    *.toml) yq -p toml -o toml eval-all '. as $f ireduce ({}; . * $f)' "$live" "$tmp" ;;
    *) jq -s '.[0] * .[1]' "$live" "$tmp" ;;
  esac > "$tmp.out" || echo "install.sh: $live does not parse; left alone" >&2
  # cat, not mv: keeps the live file's mode.
  if [[ -s "$tmp.out" ]] && ! cmp -s "$tmp.out" "$live"; then
    [[ -n "$new" ]] || cp "$live" "$live.bak"
    cat "$tmp.out" > "$live"
  fi
  rm -f "$tmp" "$tmp.out"
}

copy claude "$HOME/.claude"
copy codex "$HOME/.codex"
copy cursor "$HOME/.cursor"
copy grok "$HOME/.grok"
copy opencode "$HOME/.config/opencode"

# Every tool's rules run checks through quiet, so it must be on PATH.
[[ -n "$dry" ]] || mkdir -p "$HOME/.local/bin"
rsync -a ${dry:+"$dry"} --backup --suffix=.bak "$repo/bin/quiet" "$HOME/.local/bin/"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "install.sh: add ~/.local/bin to PATH, so the agents can run quiet" >&2 ;;
esac
for f in $merged; do
  merge "$f" "$HOME/.$f"
done
codex_requirements

# Codex and Grok read ~/.agents/skills. Claude gets one symlink per skill into
# it. Cursor gets real copies, because it skips a symlinked skill.
# A skill folder of the same name is replaced; other skills are left alone.
for dir in "$repo"/agents/skills/*/ "$repo"/agents/my-skills/*/; do
  name="$(basename "$dir")"
  for home in "$HOME/.agents/skills" "$HOME/.cursor/skills"; do
    [[ -n "$dry" ]] || mkdir -p "$home/$name"
    rsync -a ${dry:+"$dry"} --delete --exclude .DS_Store "$dir" "$home/$name/"
  done
  link="$HOME/.claude/skills/$name"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "install.sh: $link is a real folder; left alone" >&2
  elif [[ -n "$dry" ]]; then
    echo "link $link"
  else
    mkdir -p "$HOME/.claude/skills"
    ln -sfn "../../.agents/skills/$name" "$link"
  fi
done

# Skills you start by name. The `user-invocable-only` entries of Claude's
# skillOverrides are the one list. Codex, Cursor and Grok have no such setting,
# so each installed copy gets the flag each one honors: `disable-model-invocation`
# for Cursor and Grok, `policy.allow_implicit_invocation` for Codex. opencode
# denies the same names in opencode.jsonc.
while IFS= read -r name; do
  for skill in "$HOME/.agents/skills/$name" "$HOME/.cursor/skills/$name"; do
    if [[ -n "$dry" ]]; then
      echo "start $skill only by name"
      continue
    fi
    [[ -f "$skill/SKILL.md" ]] || continue
    awk '
      NR == 1 && $0 == "---" { print; print "disable-model-invocation: true"; fm = 1; next }
      fm && $0 == "---" { fm = 0 }
      fm && /^disable-model-invocation:/ { next }
      { print }
    ' "$skill/SKILL.md" > "$skill/SKILL.md.tmp"
    mv "$skill/SKILL.md.tmp" "$skill/SKILL.md"
    mkdir -p "$skill/agents"
    yaml="$skill/agents/openai.yaml"
    [[ -f "$yaml" ]] || : > "$yaml"
    awk '
      /^[[:space:]]*allow_implicit_invocation:/ { next }
      { print }
      /^policy:/ { print "  allow_implicit_invocation: false"; done = 1 }
      END { if (!done) { print "policy:"; print "  allow_implicit_invocation: false" } }
    ' "$yaml" > "$yaml.tmp"
    mv "$yaml.tmp" "$yaml"
  done
done < <(jq -r '.skillOverrides // {} | to_entries[] | select(.value == "user-invocable-only") | .key' "$repo/claude/settings.json")
