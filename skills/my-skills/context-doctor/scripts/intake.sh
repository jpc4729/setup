#!/usr/bin/env bash
# Collect the ground truth of what a repo loads into an agent's context window:
# git facts, manifests, CI, lint and format configs, hooks, every context surface
# with its size, the per-tool loaded set, and the mechanical defects.
#
# Read-only by contract. The skill that drives this script may propose a repair,
# but nothing here writes into the repo under audit: an audit that can edit is an
# audit nobody re-runs on a repo they do not own.
#
# The defect count is a floor. Everything here is mechanical; the content half of
# references/triage.md needs a reader, and scripts/vitals.py reads the lines.
#
# Usage: intake.sh [--strict] [repo-root]
#   --strict  exit 1 when any defect was reported, for a CI gate
set -euo pipefail

# Codex truncates the merged chain at this many bytes and says nothing, so a
# chain at or over the cap loses its tail in every session. The rest of the caps
# and their sources are in references/triage.md, Budget defects.
CODEX_CHAIN_CAP=32768
# The root file is loaded every session by every tool, and past about 60 lines
# the model follows the first half.
ROOT_LINE_CAP=60
# Every other context file is read against a narrower boundary and less often,
# so it carries more before the same thing happens.
ANY_LINE_CAP=200
# Windsurf counts characters, not bytes, and 12000 is the workspace-rule cap. The
# 6000 figure belongs to the home global file, which this script never sees.
WINDSURF_FILE_CAP=12000

STRICT=0
DEFECTS=0
LINT_SEEN=0
LS_FILES=""
LS_BYTES=0
LS_TOTALS=""

usage() {
  echo "Usage: intake.sh [--strict] [repo-root]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    -*)
      echo "intake.sh: unknown option: $1" >&2
      usage
      exit 2
      ;;
    *) break ;;
  esac
done

ROOT="${1:-.}"
# A flag after the path would otherwise be dropped in silence, and --strict
# dropped in silence is a CI gate that never gates.
if [[ $# -gt 1 ]]; then
  echo "intake.sh: unexpected argument: $2" >&2
  usage
  exit 2
fi
if [[ ! -d "$ROOT" ]]; then
  echo "intake.sh: not a directory: $ROOT" >&2
  usage
  exit 2
fi
cd "$ROOT"

defect() {
  DEFECTS=$((DEFECTS + 1))
  echo "defect: $*"
}

# awk rather than `wc -l`, which counts newlines: a file whose last line has no
# newline reads one line short, and a 201-line root file would pass the cap.
line_count() {
  awk 'END { print NR }' "$1" 2> /dev/null || echo 0
}

byte_count() {
  wc -c < "$1" | tr -d ' '
}

# Windsurf's cap is in characters. Under a C locale `wc -m` silently counts bytes
# again, so the locale is forced and the byte count is only the fallback.
char_count() {
  local n
  n="$(LC_ALL=en_US.UTF-8 wc -m < "$1" 2> /dev/null | tr -d ' ')" || n=""
  [[ -n "$n" ]] || n="$(byte_count "$1")"
  printf '%s' "$n"
}

# The token estimate is bytes over four, the usual English-prose average for the
# GPT and Claude tokenizer families; path-heavy markdown runs denser, so it reads
# slightly high there. It is an estimate for a budget, never a tokenizer.
# scripts/vitals.py estimates on the same basis.
stat_line() {
  local b
  b="$(byte_count "$1")"
  echo "$1  ($(line_count "$1") lines, $b bytes, ~$(((b + 3) / 4)) tokens)"
}

# A symlink is described rather than measured: reading through it would count a
# body twice, and a dangling one has no body to count at all.
describe() {
  if [[ -L "$1" ]]; then
    if [[ -e "$1" ]]; then
      echo "$1  -> $(readlink "$1")"
    else
      echo "$1  -> $(readlink "$1")  (dangling)"
    fi
  else
    stat_line "$1"
  fi
}

# Everything after the closing frontmatter fence. A file with no frontmatter is
# all body, which is what makes this safe to call on any markdown file. The CR
# strip comes first because a CRLF checkout would otherwise never match `---`.
body_of() {
  awk 'BEGIN { n = 0 }
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { n = 1; next }
    n == 1 && $0 == "---" { n = 2; next }
    n == 1 { next }
    { print }' "$1"
}

frontmatter_of() {
  awk 'BEGIN { n = 0 }
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { n = 1; next }
    n == 1 && $0 == "---" { exit }
    n == 1 { print }' "$1"
}

# Normalised so two files differing only in trailing whitespace, blank lines or
# line endings still compare equal. cksum rather than a hash because the two
# platforms disagree on the name of every hash tool.
body_digest() {
  body_of "$1" | tr -d '\r' | sed -e 's/[[:space:]]*$//' -e '/^$/d' | cksum | cut -d' ' -f1
}

same_inode() {
  local a="$1" b="$2" ia ib
  [[ -e "$a" && -e "$b" ]] || return 1
  ia="$(stat -f %i "$a" 2> /dev/null || stat -c %i "$a")"
  ib="$(stat -f %i "$b" 2> /dev/null || stat -c %i "$b")"
  [[ -n "$ia" && "$ia" == "$ib" ]]
}

# One `@path` line and nothing else: the shape of both a CLAUDE.md bridge and a
# rules-tree stub.
is_import_pointer() {
  local body count
  body="$(body_of "$1" | tr -d '\r' | sed -e 's/[[:space:]]*$//' -e '/^$/d')"
  count="$(printf '%s\n' "$body" | grep -c '' || true)"
  [[ "$body" == "@"* && "$count" == "1" ]]
}

# A CLAUDE.md @import that is not AGENTS.md is a fork. Prefer AGENTS.md and
# delete the CLAUDE.md either way.
is_agents_pointer() {
  local body path
  is_import_pointer "$1" || return 1
  body="$(body_of "$1" | tr -d '\r' | sed -e 's/[[:space:]]*$//' -e '/^$/d')"
  path="${body#@}"
  path="${path#./}"
  [[ "$(basename "$path")" == "AGENTS.md" ]]
}

# The path a one-line pointer names, empty for anything else. Claude Code expands
# the import at launch, so the target's bytes are what that session pays and the
# pointer's own bytes are noise.
pointer_target() {
  local body path
  is_import_pointer "$1" || return 0
  body="$(body_of "$1" | tr -d '\r' | sed -e 's/[[:space:]]*$//' -e '/^$/d')"
  path="${body#@}"
  path="${path#./}"
  printf '%s' "$path"
}

import_path() {
  local target
  target="$(pointer_target "$1")"
  case "$target" in
    \~/*) printf '%s/%s' "$HOME" "${target#\~/}" ;;
    /*) printf '%s' "$target" ;;
    *) printf '%s/%s' "$(dirname "$1")" "$target" ;;
  esac
}

# Claude Code skips an import inside a code span or a fenced block on purpose, so
# a fenced `@AGENTS.md` is a pointer that points nowhere. Only a file whose whole
# body is that inert import qualifies; a body with prose around it is a body, and
# defect 1 already covers it.
has_only_inert_import() {
  local rest
  rest="$(awk '
    { sub(/\r$/, "") }
    /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    { gsub(/`@[A-Za-z0-9._\/-]+\.md`/, ""); print }' "$1" |
    sed -e 's/[[:space:]]*$//' -e '/^$/d')"
  [[ -z "$rest" ]] && grep -qE '@[A-Za-z0-9._/-]+\.md' "$1"
}

# The first path that exists among a list of shell patterns. The patterns are
# expanded here rather than tested by name, so a `.prettierrc.yaml` counts as the
# same evidence as a `.prettierrc`.
first_match() {
  local pat cand
  for pat in "$@"; do
    for cand in $pat; do
      if [[ -e "$cand" ]]; then
        printf '%s' "$cand"
        return 0
      fi
    done
  done
  return 0
}

key_in() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] || return 1
  grep -qE "$pattern" "$file" 2> /dev/null
}

# A tool named by a config file is enforcement; a tool named only in prose is
# not. Fails when nothing matched, so a caller can fall back to the manifest key.
enforce() {
  local tool="$1" hit
  shift
  hit="$(first_match "$@")"
  [[ -n "$hit" ]] || return 1
  LINT_SEEN=1
  echo "- $tool: $hit"
}

# The same evidence in its other form: a formatter configured inside a shared
# manifest runs exactly as a formatter with a file of its own.
enforce_key() {
  local tool="$1" file="$2" pattern="$3"
  key_in "$file" "$pattern" || return 1
  LINT_SEEN=1
  echo "- $tool: $file"
}

ls_reset() {
  LS_FILES=""
  LS_BYTES=0
}

# One entry of a tool's loaded set: the label as that tool resolves the file, and
# the bytes it adds. A scoped rule is listed because it exists and adds nothing,
# because it does not load until a matching file is read.
ls_add() {
  local label="$1" bytes="$2"
  if [[ -n "$LS_FILES" ]]; then
    LS_FILES="$LS_FILES, $label"
  else
    LS_FILES="$label"
  fi
  LS_BYTES=$((LS_BYTES + bytes))
}

ls_print() {
  LS_TOTALS="$LS_TOTALS$1 $LS_BYTES"$'\n'
  if [[ -z "$LS_FILES" ]]; then
    echo "- $1  nothing"
  else
    echo "- $1  $LS_FILES  $LS_BYTES bytes always-on"
  fi
}

# The first name that exists takes the directory and the walk stops there, which
# is how Codex and OpenCode each end with one file and never two.
ls_first() {
  local f
  for f in "$@"; do
    [[ -e "$f" ]] || continue
    ls_add "$f" "$(byte_count "$f")"
    return 0
  done
  return 0
}

# Claude Code expands `@path` at launch, so a pointer is priced at the target.
ls_memory_file() {
  local f="$1" tgt resolved
  [[ -e "$f" ]] || return 0
  tgt="$(pointer_target "$f")"
  resolved="$(import_path "$f")"
  if [[ -n "$tgt" && -f "$resolved" ]]; then
    ls_add "$f -> $tgt" "$(byte_count "$resolved")"
  else
    ls_add "$f" "$(byte_count "$f")"
  fi
}

# A rules file is listed either way and weighed only when it loads every session.
# Which frontmatter key decides that, and whether its presence or its absence
# means always-on, is per-tool.
ls_rules() {
  local dir="$1" glob="$2" key="$3" want="$4" f hit
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    hit=0
    frontmatter_of "$f" | grep -qE "$key" && hit=1
    if [[ "$hit" == "$want" ]]; then
      ls_add "$f (always)" "$(byte_count "$f")"
    else
      ls_add "$f (scoped)" 0
    fi
  done <<< "$(find -L "$dir" -type f -name "$glob" -print 2> /dev/null | sort || true)"
}

# Directories whose contents are somebody else's checkout. Walking them turns a
# vendored AGENTS.md into a finding about a repo the user does not own.
PRUNE=(node_modules .git vendor dist build target .venv venv .next .turbo .cache coverage)
PRUNE_ARGS=()
for _p in "${PRUNE[@]}"; do
  PRUNE_ARGS+=(-name "$_p" -prune -o)
done
unset _p

# A partial walk is worth reporting; an unreadable directory is not worth dying
# over mid-report, where set -e would make it look like a --strict failure.
find_context_files() {
  find . "${PRUNE_ARGS[@]}" \( -type f -o -type l \) \
    \( -name AGENTS.md -o -name AGENT.md -o -name AGENTS.override.md \
    -o -name Agents.md -o -name CLAUDE.md -o -name CLAUDE.local.md \
    -o -name Claude.md -o -name CONTEXT.md -o -name MEMORY.md \) -print |
    sed 's|^\./||' | sort -u || true
}

# Rules trees nest. Anchoring every check at the repo root is how a monorepo with
# fifty package-level rule files reports a clean bill of health. `-L` because a
# rules directory that is itself a symlink is a real tree the tools read, and
# without it the walks below would find nothing inside one and pass.
find_rule_dirs() {
  find -L . "${PRUNE_ARGS[@]}" -type d -path "*/$1/rules" -print 2> /dev/null |
    sed 's|^\./||' | sort || true
}

echo "# context-doctor intake"
echo "root: $(pwd)"
if git rev-parse --show-toplevel > /dev/null 2>&1; then
  # Both sides resolved, or /var against /private/var warns on every macOS run.
  TOP="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)"
  [[ "$(pwd -P)" == "$TOP" ]] ||
    echo "warning: not at the repo root ($TOP); globs are resolved from here"
fi
echo

# Both walks are read-only and both are needed before the first section that
# reports on them, so they run once here and every later section reads these.
CONTEXT_FILES="$(find_context_files)"
RULE_DIRS=""
for tool in .claude .cursor .grok .windsurf .devin; do
  found="$(find_rule_dirs "$tool")"
  [[ -n "$found" ]] || continue
  RULE_DIRS="$RULE_DIRS$found"$'\n'
done

echo "## repo"
if git rev-parse --show-toplevel > /dev/null 2>&1; then
  echo "- toplevel: $(git rev-parse --show-toplevel)"
  branch="$(git rev-parse --abbrev-ref HEAD 2> /dev/null || true)"
  [[ -n "$branch" && "$branch" != "HEAD" ]] || branch="detached"
  echo "- branch: $branch"
else
  echo "- toplevel: not a git repo"
  echo "- branch: not a git repo"
fi
# A dotfiles source keeps homes under `dot_*` names a tool never reads as nested
# project files. They are user-global always-on once applied. Edit those sources;
# never the live copies under $HOME.
if { [[ -f justfile ]] || [[ -f Justfile ]]; } && [[ -d dot_agents ]]; then
  echo "- dotfiles source repo: yes"
else
  echo "- dotfiles source repo: no"
fi
echo

# The commands a rule may name, read from their real source. A rule quoting a
# script that is in none of these is drift, and this is where that is settled.
echo "## manifests"
MANIFEST_SEEN=0
manifest() {
  MANIFEST_SEEN=1
  echo "- $*"
}

if [[ -f package.json ]]; then
  pm="$(sed -n 's/.*"packageManager"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' package.json | head -1 || true)"
  if command -v jq > /dev/null 2>&1; then
    scripts="$(jq -r '.scripts | keys | join(" ")' package.json 2> /dev/null || true)"
    [[ -n "$scripts" && "$scripts" != "null" ]] || scripts="none"
    line="package.json: scripts: $scripts"
  else
    line="package.json: jq missing, scripts not listed"
  fi
  [[ -z "$pm" ]] || line="$line; packageManager: $pm"
  manifest "$line"
fi

for lock in pnpm-lock.yaml:pnpm yarn.lock:yarn package-lock.json:npm bun.lockb:bun bun.lock:bun; do
  [[ -f "${lock%%:*}" ]] || continue
  manifest "${lock%%:*}: lockfile, package manager ${lock##*:}"
done

# `just --summary` would execute the file's own settings, which this script may
# not do. An assignment carries the same colon as a recipe and is not one.
for jf in justfile Justfile; do
  [[ -f "$jf" ]] || continue
  recipes="$(grep -E '^[@_A-Za-z][A-Za-z0-9_-]*( [^:]*)?:' "$jf" 2> /dev/null |
    grep -v ':=' | sed -e 's/^@//' -e 's/[ :].*$//' |
    sort -u | tr '\n' ' ' | sed 's/ $//' || true)"
  [[ -n "$recipes" ]] || recipes="none"
  manifest "$jf: recipes: $recipes"
  break
done

if [[ -f Makefile ]]; then
  targets="$(grep -E '^[A-Za-z0-9_.-]+:' Makefile 2> /dev/null | grep -v '^\.PHONY' |
    sed 's/:.*$//' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)"
  [[ -n "$targets" ]] || targets="none"
  manifest "Makefile: targets: $targets"
fi

if [[ -f pyproject.toml ]]; then
  tables="$(grep -oE '^\[tool\.[A-Za-z0-9_.-]+\]' pyproject.toml 2> /dev/null |
    sed -e 's/^\[tool\.//' -e 's/\]$//' -e 's/\..*$//' |
    sort -u | tr '\n' ' ' | sed 's/ $//' || true)"
  [[ -n "$tables" ]] || tables="none"
  manifest "pyproject.toml: [tool.*] tables: $tables"
fi

[[ -f Cargo.toml ]] && manifest "Cargo.toml: Rust package manifest"
if [[ -f go.mod ]]; then
  mod="$(awk '$1 == "module" { print $2; exit }' go.mod 2> /dev/null || true)"
  [[ -n "$mod" ]] || mod="unnamed"
  manifest "go.mod: Go module $mod"
fi
[[ -f Gemfile ]] && manifest "Gemfile: Ruby gem dependencies"
[[ -f mix.exs ]] && manifest "mix.exs: Elixir project"
[[ -f composer.json ]] && manifest "composer.json: PHP dependencies"

for pin in .nvmrc .node-version .python-version .ruby-version .tool-versions \
  .mise.toml mise.toml rust-toolchain rust-toolchain.toml; do
  [[ -f "$pin" ]] || continue
  case "$pin" in
    .tool-versions | .mise.toml | mise.toml | rust-toolchain.toml)
      # Head-limited: a long mise file would otherwise spend a model's window on
      # versions of tools no rule mentions.
      v="$(grep -vE '^[[:space:]]*(#|$)' "$pin" 2> /dev/null | head -8 | tr -d '\r' |
        tr '\n' ';' | sed -e 's/;/; /g' -e 's/; $//' || true)"
      ;;
    *) v="$(head -1 "$pin" 2> /dev/null | tr -d '\r' || true)" ;;
  esac
  [[ -n "$v" ]] || v="empty"
  manifest "$pin: $v"
done
((MANIFEST_SEEN)) || echo "- none"
echo

echo "## ci"
CI_SEEN=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  CI_SEEN=1
  nm="$(awk 'sub(/^name:[[:space:]]*/, "") { print; exit }' "$f" 2> /dev/null |
    tr -d '\r"' | sed -e "s/^'//" -e "s/'\$//" || true)"
  if [[ -n "$nm" ]]; then
    echo "- $f: $nm"
  else
    echo "- $f"
  fi
done <<< "$(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) \
  -print 2> /dev/null | sed 's|^\./||' | sort || true)"
for f in .gitlab-ci.yml .circleci/config.yml Jenkinsfile azure-pipelines.yml bitbucket-pipelines.yml; do
  [[ -f "$f" ]] || continue
  CI_SEEN=1
  echo "- $f"
done
if [[ -d .buildkite ]]; then
  CI_SEEN=1
  echo "- .buildkite/  ($(find .buildkite -type f 2> /dev/null | wc -l | tr -d ' ') files)"
fi
((CI_SEEN)) || echo "- none"
echo

# scripts/vitals.py and references/triage.md decide from this section whether a
# prose rule is already enforced by a tool: a rule a formatter or a hook owns is
# a rule the context file does not need to carry.
echo "## enforcement"
echo "### lint and format"
enforce prettier '.prettierrc*' 'prettier.config.*' ||
  enforce_key prettier package.json '"prettier"[[:space:]]*:' || true
enforce biome 'biome.json' 'biome.jsonc' || true
enforce eslint 'eslint.config.*' '.eslintrc*' || true
enforce stylelint '.stylelintrc*' 'stylelint.config.*' || true
enforce ruff 'ruff.toml' '.ruff.toml' ||
  enforce_key ruff pyproject.toml '^\[tool\.ruff' || true
enforce_key black pyproject.toml '^\[tool\.black\]' || true
enforce flake8 '.flake8' ||
  enforce_key flake8 setup.cfg '^\[flake8\]' || true
enforce mypy 'mypy.ini' ||
  enforce_key mypy pyproject.toml '^\[tool\.mypy' || true
enforce rustfmt 'rustfmt.toml' '.rustfmt.toml' || true
enforce clippy 'clippy.toml' || true
enforce golangci '.golangci.yml' '.golangci.yaml' || true
enforce shellcheck '.shellcheckrc' || true
enforce editorconfig '.editorconfig' || true
enforce markdownlint '.markdownlint*' || true
enforce lint-staged '.lintstagedrc*' 'lint-staged.config.*' ||
  enforce_key lint-staged package.json '"lint-staged"[[:space:]]*:' || true
enforce tsconfig 'tsconfig.json' || true
((LINT_SEEN)) || echo "- none"

echo "### hooks"
HOOK_SEEN=0
# Every jq call is guarded: a settings file this script cannot parse is reported
# as unreadable, because a hook that may exist is not evidence that one does.
for s in .claude/settings.json .claude/settings.local.json; do
  [[ -f "$s" ]] || continue
  HOOK_SEEN=1
  if ! command -v jq > /dev/null 2>&1; then
    echo "- $s: jq missing, hooks not listed"
    continue
  elif ! jq -e . "$s" > /dev/null 2>&1; then
    echo "- $s: unreadable"
    continue
  fi
  hooks="$(jq -r '.hooks | to_entries[] | .key as $e | .value[]?.hooks[]? | "\($e): \(.command)"' \
    "$s" 2> /dev/null || true)"
  [[ -n "$hooks" ]] || echo "- $s: no hooks"
  while IFS= read -r h; do
    [[ -n "$h" ]] || continue
    echo "- $s  $h"
  done <<< "$hooks"
done
for d in .husky .githooks; do
  [[ -d "$d" ]] || continue
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    HOOK_SEEN=1
    echo "- $f"
  done <<< "$(find "$d" -maxdepth 1 -type f -print 2> /dev/null | sed 's|^\./||' | sort || true)"
done
hookspath="$(git config --get core.hooksPath 2> /dev/null || true)"
if [[ -n "$hookspath" ]]; then
  HOOK_SEEN=1
  echo "- core.hooksPath: $hookspath"
fi
if [[ -f .pre-commit-config.yaml ]]; then
  HOOK_SEEN=1
  ids="$(grep -E '^[[:space:]]*- id:' .pre-commit-config.yaml 2> /dev/null |
    sed -e 's/^[[:space:]]*- id:[[:space:]]*//' -e 's/[[:space:]]*$//' |
    tr '\n' ' ' | sed 's/ $//' || true)"
  [[ -n "$ids" ]] || ids="none"
  echo "- .pre-commit-config.yaml: hook ids: $ids"
fi
if [[ -f lefthook.yml ]]; then
  HOOK_SEEN=1
  echo "- lefthook.yml"
fi
((HOOK_SEEN)) || echo "- none"
echo

echo "## files"
SINGLES=(
  AGENTS.md AGENTS.override.md AGENT.md
  CLAUDE.md CLAUDE.local.md GEMINI.md CONTEXT.md MEMORY.md
  .cursorrules .windsurfrules
  .github/copilot-instructions.md
  opencode.json opencode.jsonc .opencode/opencode.json
)
FILES_SEEN=0
for p in "${SINGLES[@]}"; do
  if [[ -e "$p" ]]; then
    FILES_SEEN=1
    echo "- $(stat_line "$p")"
  fi
done
# Nothing at the root, nothing nested and no rules tree: the repo has no context
# surface at all, and the summary turns that into the one instruction that fits.
EMPTY_REPO=0
if ((FILES_SEEN == 0)) && [[ -z "$CONTEXT_FILES" && -z "$RULE_DIRS" ]]; then
  EMPTY_REPO=1
  echo "- none"
fi
echo

echo "## trees"
TREES=(.claude .cursor .codex .grok .opencode .agents .windsurf .devin .github/instructions .gemini)
for d in "${TREES[@]}"; do
  [[ -d "$d" ]] || continue
  echo "### $d"
  # A symlink is printed as itself rather than followed: a skills farm of links
  # into a sibling tree would otherwise list the same bodies twice, and a
  # dangling link would not appear at all.
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    echo "- $(describe "$f")"
  done <<< "$(find "$d" -path '*/skills/*/*' -prune -o \( -type f \( -name '*.md' \
    -o -name '*.mdc' -o -name '*.json' -o -name '*.jsonc' \) -o -type l \) -print | sort || true)"
  # A skills farm holds hundreds of files that say nothing about context wiring,
  # and this whole report lands in a model's window. One line per skill; the
  # dangling-link and adapter-dump checks below still walk the trees in full.
  while IFS= read -r sk; do
    [[ -n "$sk" ]] || continue
    echo "- $sk/  ($(find -L "$sk" -type f 2> /dev/null | wc -l | tr -d ' ') files)"
  done <<< "$(find "$d" -mindepth 2 -maxdepth 2 -type d -path '*/skills/*' -print 2> /dev/null | sort || true)"
done
echo

echo "## nested AGENTS.md / CLAUDE.md"
if [[ -n "$CONTEXT_FILES" ]]; then
  while IFS= read -r f; do
    echo "- $(describe "$f")"
  done <<< "$CONTEXT_FILES"
fi

if [[ -n "$RULE_DIRS" ]]; then
  echo
  echo "## rules trees"
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    echo "- $d  ($(find "$d" -type f | wc -l | tr -d ' ') files)"
  done <<< "$RULE_DIRS"
fi
echo

# What each tool holds after `cd` to the repo root, from the load rules in
# references/tool-matrix.md. The byte total counts the always-on files only,
# because a scoped rule costs nothing until a matching file is read.
echo "## loaded set"

# Claude Code v2.1.277+: CLAUDE.md on the project path hides AGENTS.md. With
# none of the three CLAUDE.md names at the root, it reads AGENTS.md instead.
ls_reset
claude_md=0
for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md; do
  [[ -e "$f" ]] || continue
  claude_md=1
  ls_memory_file "$f"
done
if [[ "$claude_md" == 0 ]]; then
  for f in AGENTS.md .claude/AGENTS.md; do
    ls_memory_file "$f"
  done
fi
ls_rules .claude/rules '*.md' '^paths:' 0
ls_print claude-code

# Codex reads one file per directory and never a rules tree, which is why a repo
# that keeps its rules in .claude/rules hands Codex a strictly smaller body.
ls_reset
ls_first AGENTS.override.md AGENTS.md
ls_print codex

ls_reset
ls_first AGENTS.md
ls_rules .cursor/rules '*.mdc' '^alwaysApply:[[:space:]]*true' 1
ls_print cursor

# Grok reads every recognized name and expands no import, so a pointer costs its
# own bytes here and a symlinked CLAUDE.md costs the handbook a second time. The
# inode check is what keeps a case-insensitive disk from reporting one file as
# both Agents.md and AGENTS.md; the portable spelling is probed first so the
# survivor of that collapse is the name that is really on disk.
ls_reset
grok_seen=$'\n'
for f in AGENTS.md AGENT.md Agents.md CLAUDE.md CLAUDE.local.md Claude.md \
  .claude/CLAUDE.md .claude/CLAUDE.local.md; do
  [[ -e "$f" ]] || continue
  dup=0
  while IFS= read -r g; do
    [[ -n "$g" ]] || continue
    if same_inode "$f" "$g"; then
      dup=1
      break
    fi
  done <<< "$grok_seen"
  ((dup)) && continue
  grok_seen="$grok_seen$f"$'\n'
  ls_add "$f" "$(byte_count "$f")"
done
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  ls_add "$f" "$(byte_count "$f")"
done <<< "$(find -L .grok/rules .claude/rules .cursor/rules -type f -name '*.md' \
  -print 2> /dev/null | sort || true)"
ls_print grok

ls_reset
ls_first AGENTS.md CLAUDE.md
for cfg in opencode.json opencode.jsonc .opencode/opencode.json; do
  [[ -f "$cfg" ]] || continue
  if ! command -v jq > /dev/null 2>&1; then
    ls_add "$cfg instructions (jq missing)" 0
    continue
  fi
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    # An entry may be a glob or a URL. It is printed as written and weighed only
    # when it names one real file, because resolving it here would be a guess.
    if [[ -f "$entry" ]]; then
      ls_add "$entry" "$(byte_count "$entry")"
    else
      ls_add "$entry" 0
    fi
  done <<< "$(jq -r '.instructions[]?' "$cfg" 2> /dev/null || true)"
done
ls_print opencode

# An observation and not a defect: five tools reading one repo may legitimately
# read different amounts, but a difference nobody chose is where a rule that one
# tool obeys and another never saw comes from.
ls_distinct="$(printf '%s' "$LS_TOTALS" | awk 'NF { print $2 }' | sort -u | wc -l | tr -d ' ')"
if [[ "$ls_distinct" != "1" ]]; then
  echo "- divergence: $(printf '%s' "$LS_TOTALS" |
    awk 'NF { printf "%s%s %s", (n++ ? ", " : ""), $1, $2 } END { printf "\n" }')"
fi
echo

echo "## classify"
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  case "$(basename "$f")" in
    CLAUDE.local.md)
      if [[ -L "$f" && ! -e "$f" ]]; then
        echo "- $f  dangling"
        defect "$f is a symlink to a file that does not exist; nothing loads there (triage 13)"
      else
        echo "- $f  personal overlay"
      fi
      ;;
    CLAUDE.md | Claude.md)
      if [[ -L "$f" && ! -e "$f" ]]; then
        echo "- $f  dangling"
        defect "$f is a symlink to a file that does not exist; nothing loads there (triage 13)"
      elif [[ -L "$f" ]]; then
        echo "- $f  pointer (symlink -> $(readlink "$f"))"
        case "$(basename "$(readlink "$f")")" in
          AGENTS.md)
            defect "$f is a symlink onto AGENTS.md; delete it so Claude Code reads AGENTS.md (triage 34)"
            ;;
          *)
            defect "$f is a symlink that is not AGENTS.md; prefer AGENTS.md and delete this file (triage 1)"
            ;;
        esac
      elif is_import_pointer "$f"; then
        if [[ ! -f "$(import_path "$f")" ]]; then
          defect "$f import target missing or not a file: $(pointer_target "$f") (triage 13)"
        fi
        if is_agents_pointer "$f"; then
          echo "- $f  pointer"
          if [[ -f "$(import_path "$f")" ]]; then
            defect "$f is a leftover Claude bridge; delete it so Claude Code reads AGENTS.md (triage 2)"
          fi
        else
          echo "- $f  pointer (wrong target)"
          defect "$f is an @import that is not AGENTS.md; prefer AGENTS.md and delete this file (triage 1)"
        fi
      elif has_only_inert_import "$f"; then
        echo "- $f  pointer (inert)"
        defect "$f has its @import inside a code span or fence; Claude Code skips it (triage 3)"
      else
        echo "- $f  duplicate (a body where an import belongs)"
        _dir="$(dirname "$f")"
        _sib="$_dir/AGENTS.md"
        [[ "$_dir" == "." ]] && _sib="AGENTS.md"
        if grep -qiE '\b(read|follow|see|consult)\b' "$f" && grep -q 'AGENTS.md' "$f"; then
          defect "$f is a prose-read of AGENTS.md, not an @import; delete it so Claude Code reads AGENTS.md (triage 1)"
        elif [[ -e "$_sib" ]]; then
          defect "$f carries a body; Claude Code reads it instead of AGENTS.md, Grok loads both, OpenCode never opens it (triage 1)"
        else
          defect "$f carries a body; make AGENTS.md the home and delete this file (triage 1)"
        fi
        unset _dir _sib
      fi
      ;;
    AGENTS.md | AGENTS.override.md | AGENT.md | Agents.md)
      echo "- $f  canonical"
      ;;
    CONTEXT.md | MEMORY.md)
      if [[ "$(basename "$f")" == "MEMORY.md" ]]; then
        echo "- $f  auto-memory (not a project load path)"
        defect "$f is auto-memory; it is not a project load path for any of the eight (triage 31)"
      elif [[ -L "$f" ]] || is_import_pointer "$f"; then
        echo "- $f  pointer"
      else
        echo "- $f  duplicate (a second handbook)"
        defect "$f is another copy of the handbook; leave a one-line pointer or delete it (triage 32)"
      fi
      ;;
  esac
done <<< "$CONTEXT_FILES"

for p in GEMINI.md .github/copilot-instructions.md; do
  [[ -f "$p" ]] || continue
  if [[ -L "$p" ]] || is_import_pointer "$p"; then
    echo "- $p  pointer"
  else
    echo "- $p  duplicate (a second handbook for one tool)"
    defect "$p is another copy of the handbook; leave a one-line pointer or delete it (triage 12)"
  fi
done

if [[ -f .cursorrules ]]; then
  defect ".cursorrules is legacy; move unique rules into AGENTS.md or .cursor/rules, then delete it (triage 12)"
fi
if [[ -f .windsurfrules ]]; then
  defect ".windsurfrules is legacy; leave a pointer or delete it, never a second essay (triage 12)"
fi
echo

echo "## defects"

# A tool tree is exempt from being a project handbook, except `.claude/AGENTS.md`,
# which Claude Code reads from v2.1.277 the same way it reads `.claude/CLAUDE.md`.
is_in_tool_tree() {
  local dir
  for dir in "${TREES[@]}"; do
    case "/$1" in */"$dir"/*) return 0 ;; esac
  done
  return 1
}

is_claude_agents_file() {
  case "$1" in
    .claude/AGENTS.md | */.claude/AGENTS.md) return 0 ;;
  esac
  return 1
}

while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  case "$(basename "$f")" in AGENTS.md | AGENT.md | Agents.md) ;; *) continue ;; esac
  is_in_tool_tree "$f" || continue
  is_claude_agents_file "$f" && continue
  defect "$f is on no tool's load path; Claude Code reads AGENTS.md or .claude/AGENTS.md (triage 7)"
done <<< "$CONTEXT_FILES"

while IFS= read -r f; do
  [[ "$(basename "$f")" == "CLAUDE.md" ]] || continue
  case "$f" in .claude/CLAUDE.md | */.claude/CLAUDE.md) continue ;; esac
  dir="$(dirname "$f")"
  other="$dir/.claude/CLAUDE.md"
  [[ "$dir" == "." ]] && other=".claude/CLAUDE.md"
  if [[ -e "$other" ]]; then
    defect "both $f and $other load; Claude Code concatenates them (triage 29)"
  fi
done <<< "$CONTEXT_FILES"

while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  case "$(basename "$f")" in AGENT.md | Agents.md) ;; *) continue ;; esac
  dir="$(dirname "$f")"
  sibling="$dir/AGENTS.md"
  [[ "$dir" == "." ]] && sibling="AGENTS.md"
  if [[ -e "$sibling" ]] && ! same_inode "$f" "$sibling"; then
    defect "$f sits beside $sibling; Grok loads every recognized name (triage 30)"
  elif [[ ! -e "$sibling" ]]; then
    defect "$f is a Grok-only name; rename it to AGENTS.md (triage 30)"
  fi
done <<< "$CONTEXT_FILES"

while IFS= read -r f; do
  [[ "$(basename "$f")" == "Claude.md" ]] || continue
  dir="$(dirname "$f")"
  sibling="$dir/CLAUDE.md"
  [[ "$dir" == "." ]] && sibling="CLAUDE.md"
  if [[ -e "$sibling" ]] && ! same_inode "$f" "$sibling"; then
    defect "$f sits beside $sibling; Grok loads every recognized name (triage 30)"
  elif [[ ! -e "$sibling" ]]; then
    defect "$f is a Grok-only name; rename it to AGENTS.md (triage 30)"
  fi
done <<< "$CONTEXT_FILES"

# `find -L` on the tree walks: a rules directory that is itself a symlink would
# otherwise make every check inside it pass by finding nothing.
while IFS= read -r rules; do
  [[ -n "$rules" ]] || continue
  base="${rules%/*/rules}"
  [[ "$base" != "$rules" ]] || base="."
  tool="$(basename "$(dirname "$rules")")"

  if [[ "$tool" == ".cursor" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      defect "$f is .md; Cursor reads .mdc only, and Grok reads .md only, in this directory (triage 4)"
    done <<< "$(find -L "$rules" -type f -name '*.md' | sort || true)"
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      defect "$f sets alwaysApply: true; check it against AGENTS.md duplication (triage 17)"
    done <<< "$(grep -rlE '^alwaysApply:[[:space:]]*true' "$rules" 2> /dev/null || true)"
  fi

  # Without `paths` a Claude rule loads in every session at the same cost as the
  # root file, which is the budget the root cap exists to protect.
  if [[ "$tool" == ".claude" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      frontmatter_of "$f" | grep -qE '^paths:' ||
        defect "$f has no paths frontmatter; it loads every session — check it against AGENTS.md (triage 17)"
    done <<< "$(find -L "$rules" -type f -name '*.md' | sort || true)"

    # Grok reads *.md under all three rules trees and never a .mdc, so a .md twin
    # is a second load and a .mdc twin is the paired adapter this skill endorses.
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      rel="${f#"$rules"/}"
      stem="${rel%.md}"
      for twin in "$base/.cursor/rules/$stem.md" "$base/.grok/rules/$stem.md"; do
        [[ -f "$twin" ]] || continue
        is_import_pointer "$twin" && continue
        defect "$twin repeats $f as .md; Grok reads both trees in one pass (triage 5)"
      done
      mdc="$base/.cursor/rules/${stem}.mdc"
      [[ -f "$mdc" ]] || continue
      if is_import_pointer "$mdc"; then
        echo "- $mdc  pointer (bridge into $f)"
      elif [[ "$(body_digest "$mdc")" == "$(body_digest "$f")" ]]; then
        echo "- $mdc  paired adapter (body matches $f)"
      else
        defect "$mdc and $f are a paired adapter whose bodies have drifted (triage 26)"
      fi
    done <<< "$(find -L "$rules" -type f -name '*.md' | sort || true)"
  fi
done <<< "$RULE_DIRS"

# `find -path` matches `/` with a plain `*`, so a `**` segment collapses to one
# `*` rather than expanding. Brace alternation has no equivalent and is skipped.
# A glob is probed from the repo root and from the tree's own base, because which
# of the two a nested rules directory resolves against is tool-dependent.
check_globs() {
  local file="$1" base="$2" pattern probe hits cite
  while IFS= read -r pattern; do
    [[ -n "$pattern" ]] || continue
    case "$pattern" in *[{}]*) continue ;; esac
    probe="$(printf '%s' "$pattern" | sed -e 's|\*\*/|*|g' -e 's|\*\*|*|g')"
    hits="$(find . "${PRUNE_ARGS[@]}" \
      \( -path "./$probe" -o -path "./$base/$probe" \) -print 2> /dev/null | head -1 || true)"
    cite=8
    [[ "$file" == *.instructions.md ]] && cite=33
    [[ -n "$hits" ]] ||
      defect "$file scopes on '$pattern', which matches no file here (triage $cite)"
  done <<< "$(frontmatter_of "$file" | awk '
      # `paths: ["a", "b"]` is the YAML flow list, as valid as the block form.
      # The brackets have to go before the comma split, or the first and last
      # pattern reach find with one attached and match nothing.
      /^(paths|globs|applyTo):[[:space:]]*[^[:space:]]/ {
        sub(/^(paths|globs|applyTo):[[:space:]]*/, "")
        sub(/^\[/, ""); sub(/\][[:space:]]*$/, "")
        print; inlist = 0; next
      }
      /^(paths|globs|applyTo):[[:space:]]*$/ { inlist = 1; next }
      inlist && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/, ""); print; next }
      inlist && /^[^[:space:]]/ { inlist = 0 }' |
    tr ',' '\n' |
    sed -E -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"(.*)"$/\1/' -e "s/^'(.*)'\$/\\1/" |
    grep -v '^$' || true)"
}

while IFS= read -r rules; do
  [[ -n "$rules" ]] || continue
  base="${rules%/*/rules}"
  [[ "$base" != "$rules" ]] || base="."
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    check_globs "$f" "$base"
  done <<< "$(find -L "$rules" -type f \( -name '*.md' -o -name '*.mdc' \) | sort || true)"
done <<< "$RULE_DIRS"

if [[ -d .github/instructions ]]; then
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    check_globs "$f" "."
  done <<< "$(find -L .github/instructions -type f -name '*.instructions.md' | sort || true)"
fi

# `instructions` exists for a doc discovery cannot reach. Naming a file that
# already auto-loads counts that body twice in one session.
for cfg in opencode.json opencode.jsonc .opencode/opencode.json; do
  [[ -f "$cfg" ]] || continue
  grep -Eq '"instructions"' "$cfg" || continue
  if grep -Eq 'AGENTS\.md|CLAUDE\.md' "$cfg"; then
    echo "- $cfg  overlap"
    defect "$cfg lists a file that already auto-loads; overlap (triage 11)"
  fi
done

# A surface behind .gitignore exists on one machine and for nobody else, CI
# included. CLAUDE.local.md is exempt because being ignored is its whole point.
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    [[ "$(basename "$f")" == "CLAUDE.local.md" ]] && continue
    [[ "$(basename "$f")" == "MEMORY.md" ]] && continue
    if git check-ignore -q "$f" 2> /dev/null; then
      defect "$f is gitignored; the rule exists for one machine and not for CI (triage 10)"
    fi
  done <<< "$CONTEXT_FILES"
fi

for d in .claude/skills .agents/skills; do
  [[ -d "$d" ]] || continue
  while IFS= read -r link; do
    [[ -n "$link" ]] || continue
    defect "$link is a dangling symlink; the skill it names never loads (triage 25)"
  done <<< "$(find "$d" -maxdepth 1 -type l ! -exec test -e {} \; -print 2> /dev/null || true)"
done

# A skill package ships a compact always-on adapter for hosts without skill
# support. Copied into a tool-native rules tree under the same name, it is a
# second body in every tool that already discovers the skill.
seen_skills=$'\n'
for skill_root in .agents/skills .claude/skills; do
  [[ -d "$skill_root" ]] || continue
  while IFS= read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    [[ -f "$skill_dir/SKILL.md" ]] || continue
    name="$(basename "$skill_dir")"
    [[ "$seen_skills" == *$'\n'"$name"$'\n'* ]] && continue
    seen_skills="$seen_skills$name"$'\n'
    while IFS= read -r rule; do
      [[ -n "$rule" ]] || continue
      defect "$rule is a per-tool copy of the $name skill; keep the skill, delete the adapter (triage 35)"
    done <<< "$(find . "${PRUNE_ARGS[@]}" -type f \( -name "${name}.md" -o -name "${name}.mdc" \) \( -path '*/.cursor/rules/*' -o -path '*/.claude/rules/*' -o -path '*/.grok/rules/*' -o -path '*/.windsurf/rules/*' -o -path '*/.kiro/steering/*' -o -path '*/.qoder/rules/*' -o -path '*/.clinerules/*' \) -print 2> /dev/null | sed 's|^\./||' | sort || true)"
  done <<< "$(find "$skill_root" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -print 2> /dev/null | sort || true)"
done

# Two bodies that normalise equal are one body too many. Pointers are excluded
# because a boundary tree is supposed to repeat `@AGENTS.md` in every directory.
DIGESTS=""
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  [[ -L "$f" ]] && continue
  is_import_pointer "$f" && continue
  digest="$(body_digest "$f")"
  prev="$(printf '%s' "$DIGESTS" | sed -nE "s/^$digest (.*)$/\1/p" | head -1)"
  if [[ -n "$prev" ]]; then
    defect "$f and $prev have the same body; one of them is a duplicate (triage 16)"
  else
    DIGESTS="$DIGESTS$digest $f"$'\n'
  fi
done <<< "$CONTEXT_FILES"
echo

echo "## budgets"
# The root cap belongs to whichever file carries the root body. Prefer
# AGENTS.md. A CLAUDE.md with a body is counted only when there is no AGENTS.md.
ROOT_BODY=""
if [[ -f AGENTS.md ]]; then
  ROOT_BODY="AGENTS.md"
elif [[ -f CLAUDE.md ]] && ! is_import_pointer CLAUDE.md; then
  ROOT_BODY="CLAUDE.md"
fi
if [[ -n "$ROOT_BODY" ]]; then
  n="$(line_count "$ROOT_BODY")"
  echo "- $ROOT_BODY  $n lines (cap $ROOT_LINE_CAP)"
  if ((n > ROOT_LINE_CAP)); then
    defect "$ROOT_BODY is $n lines, over the $ROOT_LINE_CAP cap (triage 15)"
  fi
fi

# A symlink is measured through its target somewhere else in this walk, and a
# pointer is one line by definition, so neither is weighed here.
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  [[ "$f" == "$ROOT_BODY" ]] && continue
  [[ -L "$f" ]] && continue
  is_import_pointer "$f" && continue
  n="$(line_count "$f")"
  if ((n > ANY_LINE_CAP)); then
    defect "$f is $n lines, over the $ANY_LINE_CAP cap (triage 15)"
  fi
done <<< "$CONTEXT_FILES"

while IFS= read -r rules; do
  [[ -n "$rules" ]] || continue
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    n="$(line_count "$f")"
    if ((n > ANY_LINE_CAP)); then
      defect "$f is $n lines, over the $ANY_LINE_CAP cap (triage 15)"
    fi
  done <<< "$(find -L "$rules" -type f \( -name '*.md' -o -name '*.mdc' \) | sort || true)"
done <<< "$RULE_DIRS"

# Codex measures its cap on the whole root-to-cwd chain, so the number that
# matters is the largest boundary total and never the root file alone.
worst_dir=""
worst_total=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  case "$(basename "$f")" in
    AGENTS.md | AGENTS.override.md) ;;
    *) continue ;;
  esac
  dir="$(dirname "$f")"
  rel="${dir#./}"
  [[ "$rel" == "." ]] && rel=""
  parts=()
  if [[ -n "$rel" ]]; then IFS='/' read -r -a parts <<< "$rel"; fi
  total=0
  probe="."
  for part in "" "${parts[@]+"${parts[@]}"}"; do
    [[ -n "$part" ]] && probe="$probe/$part"
    for name in AGENTS.override.md AGENTS.md; do
      if [[ -f "$probe/$name" ]]; then
        total=$((total + $(byte_count "$probe/$name")))
        break
      fi
    done
  done
  if ((total > worst_total)); then
    worst_total=$total
    worst_dir="$rel"
    [[ -n "$worst_dir" ]] || worst_dir="the repo root"
  fi
done <<< "$CONTEXT_FILES"
if ((worst_total > 0)); then
  echo "- worst chain  $worst_dir  $worst_total bytes (cap $CODEX_CHAIN_CAP)"
  if ((worst_total >= CODEX_CHAIN_CAP)); then
    defect "the chain at $worst_dir is $worst_total bytes; Codex stops adding nested files (triage 14)"
  fi
fi

ws_total=0
ws_seen=0
while IFS= read -r rules; do
  [[ -n "$rules" ]] || continue
  case "$(basename "$(dirname "$rules")")" in .windsurf | .devin) ;; *) continue ;; esac
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    ws_seen=1
    c="$(char_count "$f")"
    ws_total=$((ws_total + c))
    if ((c >= WINDSURF_FILE_CAP)); then
      defect "$f is $c characters, at or over the $WINDSURF_FILE_CAP Windsurf cap (triage 18)"
    fi
  done <<< "$(find -L "$rules" -type f -name '*.md' | sort || true)"
done <<< "$RULE_DIRS"
# No documented cap on the tree as a whole, so the total is information only.
((ws_seen)) && echo "- windsurf rules  $ws_total characters"
echo

echo "## summary"
if ((EMPTY_REPO)); then
  echo "note: no context file; create one only for a concrete hazard; see references/prescriptions.md"
fi
echo "$DEFECTS mechanical defects. Next: scripts/vitals.py for the per-line reading, then references/triage.md."
if ((STRICT)) && ((DEFECTS)); then
  exit 1
fi
exit 0
