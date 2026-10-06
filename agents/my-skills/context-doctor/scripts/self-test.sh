#!/usr/bin/env bash
# Contract tests for context-doctor: the skill package itself, intake.sh and
# vitals.py against fixtures built to carry one instance of each defect and each
# of the seven states that references/triage.md names.
#
# The package half exists because this skill preaches budgets, dead pointers and
# single-sourcing at other repos. A skill that breaks its own laws is the defect
# it was written to find.
#
# Every emitter needs both a fixture that fires it and a clean fixture that does
# not: an assertion suite with no negative case passes just as well against a
# check that reports everything.
#
# Fixtures verify scanner behavior and selected preservation contracts. They do
# not run an agent and cannot establish autonomous minimization performance.
#
# Usage: self-test.sh
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INTAKE="$SKILL_DIR/scripts/intake.sh"
VITALS="$SKILL_DIR/scripts/vitals.py"
PASS=0
FAIL=0
failures=()

ok() {
  PASS=$((PASS + 1))
  echo "PASS  $1"
}

no() {
  FAIL=$((FAIL + 1))
  failures+=("$1")
  echo "FAIL  $1"
}

assert() {
  local name="$1"
  shift
  if "$@"; then ok "$name"; else no "$name"; fi
}

assert_eq() {
  local name="$1" got="$2" want="$3"
  if [[ "$got" == "$want" ]]; then
    ok "$name"
  else
    no "$name"
    echo "      got:  $got"
    echo "      want: $want"
  fi
}

assert_match() {
  local name="$1" hay="$2" re="$3"
  if grep -qE "$re" <<< "$hay"; then ok "$name"; else no "$name"; fi
}

assert_no_match() {
  local name="$1" hay="$2" re="$3"
  if grep -qE "$re" <<< "$hay"; then no "$name"; else ok "$name"; fi
}

frontmatter_of() {
  awk 'BEGIN { n = 0 }
    NR == 1 && $0 == "---" { n = 1; next }
    n == 1 && $0 == "---" { exit }
    n == 1 { print }' "$1"
}

# .git is excluded because a read of a real work tree refreshes .git/index, which
# would make the read-only snapshot flap for a reason that is not a write.
tree_digest() {
  find "$1" -path '*/.git' -prune -o -type f -exec cksum {} + 2> /dev/null | sort
}

# $1 = fixture, $2 = the label the report uses, rest = the command to run.
# Proves the headline read-only contract for whichever script is under test.
run_readonly_cmd() {
  local fixture="$1" label="$2" before after out
  shift 2
  before="$(tree_digest "$fixture")"
  set +e
  out="$("$@" 2>&1)"
  set -e
  after="$(tree_digest "$fixture")"
  if [[ "$before" == "$after" ]]; then
    ok "$label left $(basename "$fixture") untouched"
  else
    no "$label left $(basename "$fixture") untouched"
  fi
  READONLY_OUTPUT="$out"
}

# $1 = fixture, rest = intake args.
run_readonly() {
  local fixture="$1"
  shift
  run_readonly_cmd "$fixture" intake bash "$INTAKE" "$@"
}

# One expression evaluated against a whole vitals --json report. python3 is the
# script's own runtime, so reading its output costs the suite no dependency.
json_probe() {
  local report="$1" expr="$2"
  printf '%s' "$report" |
    python3 -c 'import json,sys; r = json.load(sys.stdin); print(eval(sys.argv[1]))' "$expr"
}

# The same, narrowed to one file's entry, so an assertion reads as the report does.
json_file_probe() {
  local report="$1" path="$2" expr="$3"
  printf '%s' "$report" |
    python3 -c 'import json,sys; e = [f for f in json.load(sys.stdin)["files"] if f["path"] == sys.argv[1]][0]; print(eval(sys.argv[2]))' \
      "$path" "$expr"
}

echo "== package =="

assert "SKILL.md exists" test -f "$SKILL_DIR/SKILL.md"
assert "intake.sh is executable" test -x "$INTAKE"
assert "vitals.py is executable" test -x "$VITALS"
assert "self-test.sh is executable" test -x "$SKILL_DIR/scripts/self-test.sh"

# Gated, so a missing SKILL.md still reaches the summary instead of aborting the
# suite under set -e with an awk error and no failure list.
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
  SKILL_FM="$(frontmatter_of "$SKILL_DIR/SKILL.md")"

  NAME="$(sed -nE 's/^name:[[:space:]]*//p' <<< "$SKILL_FM")"
  assert_eq "frontmatter name matches the directory" "$NAME" "$(basename "$SKILL_DIR")"

  DESC="$(sed -nE 's/^description:[[:space:]]*//p' <<< "$SKILL_FM")"
  assert "description is present" test -n "$DESC"
  # An unquoted YAML scalar carrying `: ` or an angle bracket fails to parse, and
  # a skill whose frontmatter fails to parse is silently absent in every tool.
  if [[ "$DESC" == '"'* ]]; then
    last="$(printf '%s' "$DESC" | tail -c 1)"
    assert "description is a closed quoted scalar" test "${DESC:0:1}${last}" = '""'
  else
    assert_no_match "unquoted description has no colon-space" "$DESC" ': '
  fi
  assert_no_match "description has no angle brackets" "$DESC" '[<>]'
  assert_match "description names agent-context Markdown" "$DESC" 'agent-context Markdown'
  assert_match "frontmatter starts the skill only by name" "$SKILL_FM" \
    '^disable-model-invocation: true'
  assert_match "argument-hint includes checkup" "$SKILL_FM" 'checkup'
  assert "SKILL.md entry point stays within 800 words" \
    test "$(wc -w < "$SKILL_DIR/SKILL.md" | tr -d ' ')" -le 800

else
  no "frontmatter checks skipped: SKILL.md missing"
fi

# Codex expresses disable-model-invocation as its own key, and setting one
# without the other is a skill that auto-activates in three tools and hides here.
assert "agents/openai.yaml exists" test -f "$SKILL_DIR/agents/openai.yaml"
assert_match "openai.yaml denies implicit invocation" \
  "$(cat "$SKILL_DIR/agents/openai.yaml")" 'allow_implicit_invocation: false'
# Grok promotes metadata.short-description and Codex reads the yaml; neither
# falls back to the other, so a drift between them is two display strings.
OPENAI_SD="$(sed -nE 's/^[[:space:]]*short_description:[[:space:]]*//p' \
  "$SKILL_DIR/agents/openai.yaml" | sed -E 's/^"(.*)"$/\1/')"
SKILL_SD="$(frontmatter_of "$SKILL_DIR/SKILL.md" |
  sed -nE 's/^[[:space:]]*short-description:[[:space:]]*//p' | sed -E 's/^"(.*)"$/\1/')"
assert_eq "openai.yaml short_description matches the skill metadata" "$OPENAI_SD" "$SKILL_SD"

echo "== house style =="

md_files=()
while IFS= read -r f; do md_files+=("$f"); done < <(
  find "$SKILL_DIR" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.template' \) | sort
)
assert "markdown files found" test "${#md_files[@]}" -gt 0

STYLE_TMP="$(mktemp)"

# Custom skills in this library carry no tables, no nested lists and no
# horizontal rules, and every fence names a language. Line length is not
# capped: wrapping to a column is the defect references/triage.md forbids.
# Nothing else in the repo looks inside a skill, so it is enforced here.
style_fail=""
for f in "${md_files[@]}"; do
  rel="${f#"$SKILL_DIR"/}"
  awk '
    BEGIN { n = 0 }
    NR == 1 && $0 == "---" { n = 1; next }
    n == 1 && $0 == "---" { n = 2; next }
    n == 1 { next }
    /^[[:space:]]*(```|~~~)/ {
      if (!fence) { fence = 1; if ($0 !~ /^[[:space:]]*(```|~~~)[A-Za-z]/) bad = "bare-fence" }
      else { fence = 0 }
      next
    }
    fence { next }
    /^\|/ { bad = "table" }
    /^(  +)([-*]|[0-9]+\.) / { bad = "nested-list" }
    /^(---|\*\*\*|___)[[:space:]]*$/ { bad = "hrule" }
    END { if (bad) { print bad; exit 1 } }' "$f" > "$STYLE_TMP" ||
    style_fail="$style_fail $rel:$(cat "$STYLE_TMP")"
done
rm -f "$STYLE_TMP"
assert_eq "no tables, nested lists, hrules or bare fences" "$style_fail" ""

echo "== single source =="

# The skill deletes dead pointers in other repos. Its own have to resolve.
dead=""
for f in "${md_files[@]}"; do
  # shellcheck disable=SC2016  # the backticks below are markdown syntax to match, not a subshell
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    [[ -e "$SKILL_DIR/$p" ]] || dead="$dead ${f#"$SKILL_DIR"/}->$p"
  done < <(grep -oE '`(references|assets|scripts|examples)/[A-Za-z0-9._/-]+`' "$f" | tr -d '`' | sort -u)
done
assert_eq "every references, assets and scripts path resolves" "$dead" ""

TRIAGE="$(cat "$SKILL_DIR/references/triage.md")"
assert "prompts.md exists" test -f "$SKILL_DIR/examples/prompts.md"
assert_match "prompts.md offers the checkup invocation" \
  "$(cat "$SKILL_DIR/examples/prompts.md")" 'checkup'

# Each triage number the script cites has to exist as a numbered defect. The
# acceptance gate restarts at 1, so it is cut off first.
TRIAGE_DEFECTS="$(awk '/^## Wiring defects/ { s = 1; next } s && /^## Acceptance/ { exit } s { print }' \
  "$SKILL_DIR/references/triage.md")"
missing_cites=""
while IFS= read -r n; do
  [[ -n "$n" ]] || continue
  grep -qE "^$n\. " <<< "$TRIAGE_DEFECTS" || missing_cites="$missing_cites $n"
done < <(grep -oE 'triage [0-9]+' "$INTAKE" | awk '{ print $2 }' | sort -un)
assert_eq "every triage number intake.sh cites exists" "$missing_cites" ""

# The two scripts and the prose have to agree on a cap, or a repair passes one
# gate and fails the next.
assert_eq "intake Codex cap is 32768" \
  "$(sed -nE 's/^CODEX_CHAIN_CAP=//p' "$INTAKE")" "32768"
assert_eq "intake root cap is 60" "$(sed -nE 's/^ROOT_LINE_CAP=//p' "$INTAKE")" "60"
assert_eq "intake any-file cap is 200" "$(sed -nE 's/^ANY_LINE_CAP=//p' "$INTAKE")" "200"
assert_eq "vitals root cap is 60" \
  "$(sed -nE 's/^ROOT_LINE_CAP = //p' "$VITALS")" "60"
assert_eq "vitals any-file cap is 200" \
  "$(sed -nE 's/^ANY_LINE_CAP = //p' "$VITALS")" "200"
# The destination budgets are stated as numbers in triage.md as well, so a
# script that drifts from the prose lets a repair pass one gate and fail another.
assert_eq "vitals root pointer cap is 5" \
  "$(sed -nE 's/^ROOT_POINTER_CAP = //p' "$VITALS")" "5"
assert_eq "vitals any-file pointer cap is 12" \
  "$(sed -nE 's/^ANY_POINTER_CAP = //p' "$VITALS")" "12"
assert_eq "vitals amplification ratio is 8" \
  "$(sed -nE 's/^AMPLIFY_RATIO = //p' "$VITALS")" "8"
assert_match "triage states the five-destination root budget" "$TRIAGE" \
  'at most five in a root file'
assert_match "triage states the twelve-destination file budget" "$TRIAGE" \
  'at most twelve in any file'
assert_match "triage states the eightfold amplification cap" "$TRIAGE" \
  'eight times a file'

# vitals.py runs wherever python3 does, on a checkout nobody owns, so an install
# step is not available to it.
nonstdlib=""
while IFS= read -r mod; do
  [[ -n "$mod" ]] || continue
  # shellcheck disable=SC2194  # the stdlib list is a literal haystack, not a variable
  case " argparse json math os re sys pathlib collections " in
    *" $mod "*) ;;
    *) nonstdlib="$nonstdlib $mod" ;;
  esac
done < <(grep -E '^import |^from ' "$VITALS" | awk '{ print $2 }' | sort -u)
assert_eq "vitals imports the standard library alone" "$nonstdlib" ""
assert_eq "vitals declares a python3 shebang" "$(head -1 "$VITALS")" "#!/usr/bin/env python3"

echo "== templates =="

assert "CLAUDE.md.template is gone" test ! -e "$SKILL_DIR/assets/CLAUDE.md.template"

body_after_frontmatter() {
  awk 'BEGIN { n = 0 }
    /^---$/ { n++; next }
    n >= 2 { print }' "$1"
}
cb="$(body_after_frontmatter "$SKILL_DIR/assets/claude-rule.template.md")"
kb="$(body_after_frontmatter "$SKILL_DIR/assets/cursor-rule.template.mdc")"
assert "paired rule template bodies are non-empty" test -n "$cb"
assert_eq "paired rule template bodies match" "$cb" "$kb"

assert "claude rule template scopes with paths" \
  grep -qE '^paths:' "$SKILL_DIR/assets/claude-rule.template.md"
assert "cursor rule template sets alwaysApply false" \
  grep -qE '^alwaysApply:[[:space:]]*false' "$SKILL_DIR/assets/cursor-rule.template.mdc"
assert "cursor rule template declares globs" \
  grep -qE '^globs:' "$SKILL_DIR/assets/cursor-rule.template.mdc"
assert "AGENTS template uses numbered rules" \
  grep -qE '^1\. ' "$SKILL_DIR/assets/AGENTS.md.template"
assert "AGENTS template contains at most five lines" \
  test "$(grep -c '' "$SKILL_DIR/assets/AGENTS.md.template")" -le 5

echo "== intake: argument handling =="

set +e
out="$(bash "$INTAKE" "/tmp/context-doctor-missing-$$" 2>&1)"
ec=$?
set -e
assert_eq "missing root exits 2" "$ec" "2"
assert_match "missing root names the path" "$out" 'not a directory'

set +e
bash "$INTAKE" --nope . > /dev/null 2>&1
ec=$?
set -e
assert_eq "unknown option exits 2" "$ec" "2"

set +e
out="$(bash "$INTAKE" --help 2>&1)"
ec=$?
set -e
assert_eq "--help exits 0" "$ec" "0"
assert_match "--help prints usage" "$out" '^Usage: intake\.sh'

CLEAN="$(mktemp -d)"
DIRTY="$(mktemp -d)"
BIG="$(mktemp -d)"
IGNORED="$(mktemp -d)"
DUPES="$(mktemp -d)"
OV="$(mktemp -d)"
BARE="$(mktemp -d)"
BLOAT="$(mktemp -d)"
TREATED="$(mktemp -d)"
SCAFFOLD="$(mktemp -d)"
CONTRA="$(mktemp -d)"
REDIR="$(mktemp -d)"
MAP="$(mktemp -d)"
POINTERS="$(mktemp -d)"
trap 'rm -rf "$CLEAN" "$DIRTY" "$BIG" "$IGNORED" "$DUPES" "$OV" "$BARE" "$BLOAT" "$TREATED" "$SCAFFOLD" "$CONTRA" "$REDIR" "$MAP" "$POINTERS"' EXIT

echo "== read-only assertion =="

readonly_rejects_mutation() {
  local PASS=0 FAIL=0
  local failures=()
  run_readonly_cmd "$POINTERS" mutation bash -c 'printf changed > "$1/probe"' _ "$POINTERS" > /dev/null
  [[ "$FAIL" == 1 && "${#failures[@]}" == 1 ]]
}
assert "the read-only assertion records a mutating command as a failure" readonly_rejects_mutation
rm -f "$POINTERS/probe"

echo "== intake: clean fixture =="

# A full correct harness, not a minimal one: every check in the script has to
# have something here it could wrongly fire on. Nested AGENTS.md files carry
# only local differences. The manifest, CI, lint and hook facts matter because
# vitals.py and triage.md read them as enforcement.
mkdir -p "$CLEAN/packages/api" "$CLEAN/.claude/rules/deep" "$CLEAN/.cursor/rules/deep" \
  "$CLEAN/.claude/skills" "$CLEAN/.claude/hooks" "$CLEAN/.agents/skills/real" \
  "$CLEAN/.windsurf/rules" "$CLEAN/.github/workflows" "$CLEAN/src" "$CLEAN/docs"
printf '%s\n' '# AGENTS.md' '1. Use pnpm.' 'Read .claude/rules/ before editing src/.' > "$CLEAN/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$CLEAN/GEMINI.md"
printf '%s\n' '# api' '1. Run tests from this package.' > "$CLEAN/packages/api/AGENTS.md"
printf '%s\n' 'export const a = 1' > "$CLEAN/src/a.ts"
printf '%s\n' '# deploy' > "$CLEAN/docs/deploy.md"
printf '%s\n' '## Rules' '1. Validate at the boundary.' > "$CLEAN/body.txt"
{
  printf '%s\n' '---' 'paths:' '  - "src/**/*.ts"' '---'
  cat "$CLEAN/body.txt"
} > "$CLEAN/.claude/rules/api.md"
{
  printf '%s\n' '---' 'description: API rules' 'globs: src/**/*.ts' 'alwaysApply: false' '---'
  cat "$CLEAN/body.txt"
} > "$CLEAN/.cursor/rules/api.mdc"
{
  printf '%s\n' '---' 'paths:' '  - "src/**/*.ts"' '---'
  cat "$CLEAN/body.txt"
} > "$CLEAN/.claude/rules/deep/nested.md"
{
  printf '%s\n' '---' 'description: nested API rules' 'globs: src/**/*.ts' 'alwaysApply: false' '---'
  cat "$CLEAN/body.txt"
} > "$CLEAN/.cursor/rules/deep/nested.mdc"
rm -f "$CLEAN/body.txt"
printf '%s\n' '---' 'name: real' '---' > "$CLEAN/.agents/skills/real/SKILL.md"
ln -s ../../.agents/skills/real "$CLEAN/.claude/skills/real"
printf '%s\n' '# small windsurf rule' > "$CLEAN/.windsurf/rules/small.md"
printf '%s\n' '{"instructions":["docs/deploy.md"]}' > "$CLEAN/opencode.json"
printf '%s\n' '{"name":"x","scripts":{"test":"vitest run","lint":"eslint ."},"packageManager":"pnpm@9.0.0"}' \
  > "$CLEAN/package.json"
printf '%s\n' 'lockfileVersion: "9.0"' > "$CLEAN/pnpm-lock.yaml"
printf '%s\n' '{}' > "$CLEAN/.prettierrc"
printf '%s\n' 'name: CI' 'on: push' > "$CLEAN/.github/workflows/ci.yml"
printf '%s\n' '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash .claude/hooks/test.sh"}]}]}}' \
  > "$CLEAN/.claude/settings.json"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$CLEAN/.claude/hooks/test.sh"

run_readonly "$CLEAN" "$CLEAN"
clean_out="$READONLY_OUTPUT"
assert_no_match "clean fixture has no CLAUDE.md" "$clean_out" '^- CLAUDE\.md'
assert_match "clean fixture reports zero defects" "$clean_out" '^0 mechanical defects'
assert_no_match "repeated import lines are not a duplicate" "$clean_out" 'same body'
assert_match "an md and mdc pair is a paired adapter" "$clean_out" 'api\.mdc  paired adapter'
assert_match "a nested md and mdc pair is a paired adapter" "$clean_out" \
  'deep/nested\.mdc  paired adapter'
assert_match "lists the discovered rules trees" "$clean_out" '^- \.claude/rules  \([0-9]+ files\)'
assert_match "a skill directory collapses to one line" "$clean_out" \
  '^- \.agents/skills/real/  \([0-9]+ files\)$'
assert_no_match "a skill body is not listed file by file" "$clean_out" \
  '^- \.agents/skills/real/SKILL\.md'
assert_no_match "no warning when run at the repo root" "$clean_out" '^warning: not at the repo root'
assert_match "a stat line carries a token estimate" "$clean_out" \
  '^- AGENTS\.md  \([0-9]+ lines, [0-9]+ bytes, ~[0-9]+ tokens\)$'

# The report's own sections are what a model reads, so each fact is anchored on
# its block rather than on a string that could appear anywhere in the output.
manifests_block="$(awk '/^## manifests/, /^## ci/' <<< "$clean_out")"
assert_match "the manifests section reads the scripts and the package manager" "$manifests_block" \
  '^- package\.json: scripts: lint test; packageManager: pnpm@9\.0\.0$'
assert_match "the manifests section names the lockfile" "$manifests_block" \
  '^- pnpm-lock\.yaml: lockfile, package manager pnpm$'
ci_block="$(awk '/^## ci/, /^## enforcement/' <<< "$clean_out")"
assert_match "the ci section names the workflow" "$ci_block" '^- \.github/workflows/ci\.yml: CI$'
lint_block="$(awk '/^### lint and format/, /^### hooks/' <<< "$clean_out")"
assert_match "the enforcement section names the formatter" "$lint_block" '^- prettier: '
hooks_block="$(awk '/^### hooks/, /^## files/' <<< "$clean_out")"
assert_match "the hooks section names the event and the script" "$hooks_block" \
  'PreToolUse: bash \.claude/hooks/test\.sh'

# The loaded set is the ground truth the whole consultation rests on: five tools,
# always in the same order, each one resolving the same tree its own way.
loaded_block="$(awk '/^## loaded set/, /^## classify/' <<< "$clean_out")"
clean_tools="$(sed -nE 's/^- (claude-code|codex|cursor|grok|opencode)  .*/\1/p' <<< "$loaded_block" |
  tr '\n' ' ' | sed 's/ $//')"
assert_eq "the loaded set names five tools in order" "$clean_tools" \
  "claude-code codex cursor grok opencode"
assert_match "claude-code loads AGENTS.md and lists its scoped rules" "$loaded_block" \
  '^- claude-code  AGENTS\.md, \.claude/rules/api\.md \(scoped\), \.claude/rules/deep/nested\.md \(scoped\)  [0-9]+ bytes always-on$'
assert_match "codex holds the handbook alone" "$loaded_block" \
  '^- codex  AGENTS\.md  [0-9]+ bytes always-on$'

set +e
bash "$INTAKE" --strict "$CLEAN" > /dev/null 2>&1
ec=$?
set -e
assert_eq "--strict on a clean fixture exits 0" "$ec" "0"

set +e
out="$(cd "$CLEAN" && bash "$INTAKE" 2>&1)"
ec=$?
set -e
assert_eq "no argument defaults to the working directory" "$ec" "0"
assert_match "no-argument run produces the same verdict" "$out" '^0 mechanical defects'

echo "== intake: defective fixture =="

mkdir -p "$DIRTY/.claude/rules" "$DIRTY/.cursor/rules" "$DIRTY/.claude/skills" \
  "$DIRTY/.grok/rules" "$DIRTY/packages/api/.claude" "$DIRTY/packages/api/.cursor/rules" \
  "$DIRTY/packages/web/.claude/rules/deep" "$DIRTY/packages/web/.cursor/rules/deep" \
  "$DIRTY/.windsurf/rules" "$DIRTY/src" "$DIRTY/node_modules/pkg" \
  "$DIRTY/.github/instructions" "$DIRTY/.agents/skills/real"
printf '%s\n' '# AGENTS.md' '1. Use pnpm.' > "$DIRTY/AGENTS.md"
printf '%s\n' 'a full copy of the rules, which must be flagged' > "$DIRTY/CLAUDE.md"
printf '%s\n' '# an alternate handbook name' > "$DIRTY/AGENT.md"
printf '%s\n' 'a long unique gemini essay that is not a pointer' > "$DIRTY/GEMINI.md"
printf '%s\n' 'a third copilot essay' > "$DIRTY/.github/copilot-instructions.md"
printf '%s\n' 'legacy cursor rules dump' > "$DIRTY/.cursorrules"
printf '%s\n' 'legacy windsurf rules dump' > "$DIRTY/.windsurfrules"
printf '%s\n' '@AGENTS.md' > "$DIRTY/.claude/CLAUDE.md"
printf '%s\n' 'a ninth handbook name' > "$DIRTY/CONTEXT.md"
printf '%s\n' '# copied auto-memory' > "$DIRTY/MEMORY.md"
printf '%s\n' '---' 'applyTo: "copilot/no-such/**/*.rb"' '---' '1. Copilot scoped.' \
  > "$DIRTY/.github/instructions/api.instructions.md"
printf '%s\n' '# overlay with no CLAUDE.md beside it' > "$DIRTY/packages/api/AGENTS.md"
printf '%s\n' '# a per-directory replacement' > "$DIRTY/packages/api/AGENTS.override.md"
printf '%s\n' '# dual Claude Code handbook' > "$DIRTY/.claude/AGENTS.md"
printf '%s\n' '# nested dual Claude Code handbook' > "$DIRTY/packages/api/.claude/AGENTS.md"
printf '%s\n' '# a file on no load path' > "$DIRTY/.agents/AGENTS.md"
printf '%s\n' '# vendored, must be pruned' > "$DIRTY/node_modules/pkg/AGENTS.md"
printf '%s\n' 'export const a = 1' > "$DIRTY/src/a.ts"
printf '%s\n' '---' 'paths:' '  - "does/not/exist/**/*.ts"' '---' '## Rules' '1. A' \
  > "$DIRTY/.claude/rules/api.md"
printf '%s\n' '---' 'paths:' "  - 'src/**/*.ts'" '---' '## Rules' '1. B' \
  > "$DIRTY/.claude/rules/live.md"
printf '%s\n' '---' 'description: no scoping key at all' '---' '## Rules' '1. C' \
  > "$DIRTY/.claude/rules/nopaths.md"
printf '%s\n' '---' 'globs: "also/missing/**/*.ts"' '---' '## Rules' '1. D' \
  > "$DIRTY/.grok/rules/dead.md"
printf '%s\n' '---' 'alwaysApply: true' '---' '## Rules' '1. A' > "$DIRTY/.cursor/rules/api.mdc"
printf '%s\n' '# ignored by cursor, read by grok' > "$DIRTY/.cursor/rules/notes.md"
# A nested tree, to prove discovery is not anchored at the repo root.
printf '%s\n' '# nested and ignored by cursor' > "$DIRTY/packages/api/.cursor/rules/deep.md"
# One body as *.md in two trees, which is what Grok really loads twice.
printf '%s\n' '---' 'paths:' '  - "src/**/*.ts"' '---' '## Rules' '1. Shared body.' \
  > "$DIRTY/packages/web/.claude/rules/dup.md"
printf '%s\n' '---' 'globs: src/**/*.ts' '---' '## Rules' '1. Shared body.' \
  > "$DIRTY/packages/web/.cursor/rules/dup.md"
printf '%s\n' '---' 'paths:' '  - "src/**/*.ts"' '---' '## Rules' '1. Nested.' \
  > "$DIRTY/packages/web/.claude/rules/deep/nest.md"
printf '%s\n' '---' 'globs: src/**/*.ts' 'alwaysApply: false' '---' '## Rules' '1. Drifted nest.' \
  > "$DIRTY/packages/web/.cursor/rules/deep/nest.mdc"
printf '%s\n' '{"instructions":["AGENTS.md","CLAUDE.md"]}' > "$DIRTY/opencode.jsonc"
ln -s ../../nowhere/skill "$DIRTY/.claude/skills/ghost"
printf '%s\n' '---' 'name: real' '---' '# skill body' > "$DIRTY/.agents/skills/real/SKILL.md"
printf '%s\n' '---' 'globs: src/**/*.ts' 'alwaysApply: false' '---' '## Rules' '1. Adapter dump.' \
  > "$DIRTY/.cursor/rules/real.mdc"
mkdir -p "$DIRTY/packages/cli"
printf '%s\n' '# cli' '1. This package builds a binary.' > "$DIRTY/packages/cli/AGENTS.md"
ln -s AGENTS.md "$DIRTY/packages/cli/CLAUDE.md"
ln -s ../../gone/AGENTS.md "$DIRTY/packages/web/CLAUDE.md"
awk 'BEGIN { for (i = 0; i < 400; i++) { s = ""; for (j = 0; j < 40; j++) s = s "x"; print s } }' \
  > "$DIRTY/.windsurf/rules/huge.md"
# A rules directory that is itself a symlink is a real tree the tools read.
mkdir -p "$DIRTY/packages/link/shared-rules" "$DIRTY/packages/link/.claude"
printf '%s\n' '---' 'description: reached through a symlinked tree' '---' '## Rules' '1. E' \
  > "$DIRTY/packages/link/shared-rules/linked.md"
ln -s ../shared-rules "$DIRTY/packages/link/.claude/rules"
# Codex reads an override in place of AGENTS.md; Claude Code reads neither.
mkdir -p "$DIRTY/packages/ovr"
printf '%s\n' '# override only' > "$DIRTY/packages/ovr/AGENTS.override.md"

run_readonly "$DIRTY" "$DIRTY"
dirty_out="$READONLY_OUTPUT"

assert_match "flags CLAUDE.md as a body" "$dirty_out" 'CLAUDE\.md  duplicate'
assert_match "names Claude Code hiding AGENTS.md" "$dirty_out" \
  'defect:.*Claude Code reads it instead of AGENTS.md'
assert_match "flags GEMINI.md as another copy" "$dirty_out" 'defect:.*GEMINI\.md'
assert_match "flags copilot-instructions as another copy" "$dirty_out" 'defect:.*copilot-instructions\.md'
assert_match "flags .cursorrules as legacy" "$dirty_out" 'defect:.*\.cursorrules'
assert_match "flags .windsurfrules as legacy" "$dirty_out" 'defect:.*\.windsurfrules'
assert_no_match "does not demand a CLAUDE.md beside AGENTS.md" "$dirty_out" \
  'has no CLAUDE\.md beside it'
assert_no_match "does not demand a CLAUDE.md inside a dot-directory" "$dirty_out" \
  'defect: \.claude/AGENTS\.md has no CLAUDE\.md'
assert_match "flags .agents/AGENTS.md as unread" "$dirty_out" 'defect: \.agents/AGENTS\.md is on no'
assert_no_match "does not flag .claude/AGENTS.md as unread" "$dirty_out" \
  'defect: \.claude/AGENTS\.md is on no'
assert_match "flags .md inside .cursor/rules" "$dirty_out" 'defect: \.cursor/rules/notes\.md is \.md'
assert_match "flags a nested .md inside .cursor/rules" "$dirty_out" \
  'defect: packages/api/\.cursor/rules/deep\.md is \.md'
assert_match "flags alwaysApply true" "$dirty_out" 'defect:.*alwaysApply'
assert_match "flags a claude rule with no paths" "$dirty_out" 'defect:.*nopaths\.md has no paths'
assert_match "flags the glob that matches nothing" "$dirty_out" "defect:.*does/not/exist"
assert_match "flags a dead glob in a .grok rule" "$dirty_out" 'defect:.*also/missing'
assert_no_match "leaves a single-quoted glob that matches alone" "$dirty_out" "defect:.*'src/\*\*/\*\.ts'"
assert_match "flags one body as .md in two rules trees" "$dirty_out" \
  'defect: packages/web/\.cursor/rules/dup\.md repeats'
assert_match "flags the opencode overlap" "$dirty_out" 'defect:.*opencode\.jsonc'
assert_match "flags the dangling skill link" "$dirty_out" 'defect:.*ghost is a dangling'
assert_match "flags a same-named rule as a skill-adapter dump" "$dirty_out" \
  'defect: .cursor/rules/real.mdc is a per-tool copy of the real skill'
assert_match "flags the windsurf rule over its cap" "$dirty_out" 'defect:.*huge\.md is 16400 characters'
assert_match "follows a symlinked rules directory" "$dirty_out" \
  'defect: packages/link/\.claude/rules/linked\.md has no paths'
assert_no_match "does not demand a CLAUDE.md beside an override" "$dirty_out" \
  'defect: packages/ovr/AGENTS\.override\.md has no CLAUDE\.md'
assert_match "treats a symlinked CLAUDE.md as a pointer" "$dirty_out" \
  'packages/cli/CLAUDE\.md  pointer \(symlink'
assert_match "flags a CLAUDE.md symlink onto AGENTS.md" "$dirty_out" \
  'defect: packages/cli/CLAUDE.md is a symlink onto AGENTS.md; delete it'
assert_match "flags dual CLAUDE.md entry" "$dirty_out" \
  'defect: both CLAUDE.md and .claude/CLAUDE.md load'
assert_match "flags a leftover .claude/CLAUDE.md pointer" "$dirty_out" \
  'defect: .claude/CLAUDE.md is a leftover Claude bridge'
assert_no_match "intake defines helpers before it calls them" "$dirty_out" \
  'command not found'
assert_match "flags AGENT.md beside AGENTS.md" "$dirty_out" \
  'defect: AGENT.md sits beside AGENTS.md'
assert_match "flags CONTEXT.md as a second handbook" "$dirty_out" \
  'defect: CONTEXT.md is another copy'
assert_match "flags a committed MEMORY.md" "$dirty_out" \
  'defect: MEMORY.md is auto-memory'
assert_match "flags a dead applyTo glob" "$dirty_out" \
  "defect:.*copilot/no-such.*triage 33"
assert_match "flags a dangling context symlink" "$dirty_out" \
  'defect: packages/web/CLAUDE.md is a symlink to a file that does not exist'
assert_no_match "prunes a vendored AGENTS.md" "$dirty_out" 'node_modules'
assert_no_match "does not report zero defects" "$dirty_out" '^0 mechanical defects'

# The listing sections are load-bearing for the human reading the report, so each
# is anchored on its own block rather than on a string that appears anywhere.
nested_block="$(awk '/^## nested/, /^## rules trees/' <<< "$dirty_out")"
assert_match "the nested section lists the package file with its size" "$nested_block" \
  '^- packages/api/AGENTS\.md  \([0-9]+ lines, [0-9]+ bytes, ~[0-9]+ tokens\)$'
assert_match "the nested section lists AGENTS.override.md" "$nested_block" \
  '^- packages/api/AGENTS\.override\.md  \('
assert_match "the nested section lists AGENT.md" "$nested_block" '^- AGENT\.md  \('
files_block="$(awk '/^## files/, /^## trees/' <<< "$dirty_out")"
assert_match "the files section lists the root handbook" "$files_block" \
  '^- AGENTS\.md  \([0-9]+ lines, [0-9]+ bytes, ~[0-9]+ tokens\)$'
trees_block="$(awk '/^## trees/, /^## nested/' <<< "$dirty_out")"
assert_match "the trees section names a symlink rather than following it" "$trees_block" \
  '^- \.claude/skills/ghost  -> \.\./\.\./nowhere/skill  \(dangling\)$'

set +e
bash "$INTAKE" --strict "$DIRTY" > /dev/null 2>&1
ec=$?
set -e
assert_eq "--strict on a defective fixture exits 1" "$ec" "1"

set +e
bash "$INTAKE" "$DIRTY" --strict > /dev/null 2>&1
ec=$?
set -e
assert_eq "a flag after the path is rejected rather than dropped" "$ec" "2"

# An import inside a code span looks right and imports nothing, so it needs its
# own case beside the fenced form.
# shellcheck disable=SC2016  # backticks are the markdown being written, not a subshell
printf '%s\n' '`@AGENTS.md`' > "$DIRTY/CLAUDE.md"
set +e
span_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "flags an import inside a code span" "$span_out" 'defect:.*inside a code span or fence'

printf '%s\n' '```text' '@AGENTS.md' '```' > "$DIRTY/CLAUDE.md"
set +e
fenced_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "flags a fenced import" "$fenced_out" 'defect:.*inside a code span or fence'

# An inert import wrapped in real prose is a body, not an inert pointer.
# shellcheck disable=SC2016  # backticks are the markdown being written, not a subshell
printf '%s\n' '`@AGENTS.md`' '' 'plus a paragraph of unique rules' > "$DIRTY/CLAUDE.md"
set +e
mixed_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "an import beside prose is still a body" "$mixed_out" 'CLAUDE\.md  duplicate'

printf '%s\n' '@README.md' > "$DIRTY/CLAUDE.md"
set +e
wrong_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "CLAUDE.md that imports a file other than AGENTS.md is a defect" "$wrong_out" \
  'defect: CLAUDE.md is an @import that is not AGENTS.md'
printf '%s\n' '@./AGENTS.md' > "$DIRTY/CLAUDE.md"
set +e
dot_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "CLAUDE.md pointing at ./AGENTS.md is a leftover bridge" "$dot_out" \
  'defect: CLAUDE.md is a leftover Claude bridge'
assert_no_match "./AGENTS.md is not a wrong-target import" "$dot_out" \
  'defect: CLAUDE.md is an @import that is not AGENTS.md'

printf '%s\n' 'Read and follow AGENTS.md before any work.' > "$DIRTY/CLAUDE.md"
set +e
prose_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "prose-read of AGENTS.md is not an import" "$prose_out" \
  'prose-read of AGENTS.md, not an @import'

# A stub bridge is the correct way to reach a second tool and must not be
# reported as a mirror.
printf '%s\n' '@AGENTS.md' > "$DIRTY/CLAUDE.md"
printf '%s\n' '---' 'globs: src/**/*.ts' 'alwaysApply: false' '---' '' \
  '@.claude/rules/api.md' > "$DIRTY/.cursor/rules/api.mdc"
set +e
bridge_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "accepts a stub bridge as a pointer" "$bridge_out" 'api\.mdc  pointer \(bridge'
assert_no_match "does not call a bridge a duplicate" "$bridge_out" 'defect:.*api\.mdc repeats'

# A paired adapter whose bodies drifted is the mirror defect that does apply to
# an .mdc twin.
printf '%s\n' '---' 'globs: src/**/*.ts' 'alwaysApply: false' '---' '## Rules' '1. Drifted.' \
  > "$DIRTY/.cursor/rules/api.mdc"
set +e
drift_out="$(bash "$INTAKE" "$DIRTY" 2>&1)"
set -e
assert_match "flags a drifted paired adapter" "$drift_out" 'defect:.*bodies have drifted'
assert_match "flags a nested drifted paired adapter" "$dirty_out" \
  'defect: packages/web/.cursor/rules/deep/nest.mdc and packages/web/.claude/rules/deep/nest.md are a paired adapter whose bodies have drifted'

echo "== intake: duplicates and normalisation =="

# body_digest normalises CRLF, trailing spaces and blank lines. Two files that
# differ only in those ways are one body written twice.
mkdir -p "$DUPES/a" "$DUPES/b"
printf '%s\n' '# shared' '1. One rule, two homes.' > "$DUPES/a/AGENTS.md"
printf '%s\r\n' '# shared' '1. One rule, two homes.   ' '' > "$DUPES/b/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$DUPES/a/CLAUDE.md"
printf '%s\n' '@AGENTS.md' > "$DUPES/b/CLAUDE.md"
set +e
dupes_out="$(bash "$INTAKE" "$DUPES" 2>&1)"
set -e
assert_match "flags two files with the same normalised body" "$dupes_out" \
  'defect:.*have the same body'
assert_no_match "CRLF frontmatter does not become a false defect" "$dupes_out" 'has no paths'

echo "== intake: budgets and git =="

# 250 lines of 138 bytes, written with no trailing newline: over the 60-line
# root cap and over the 32 KiB chain cap at once, and proving line_count counts
# the last line that `wc -l` would drop. The nested file is over the wider cap
# every other context file is measured against.
awk 'BEGIN {
  for (i = 0; i < 250; i++) {
    s = ""
    for (j = 0; j < 138; j++) s = s "x"
    printf "%s%s", (i ? "\n" : ""), s
  }
}' > "$BIG/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$BIG/CLAUDE.md"
mkdir -p "$BIG/pkg"
awk 'BEGIN { for (i = 1; i <= 210; i++) printf "%d. Keep helper %d under review.\n", i, i }' \
  > "$BIG/pkg/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$BIG/pkg/CLAUDE.md"
set +e
big_out="$(bash "$INTAKE" "$BIG" 2>&1)"
set -e
assert_match "flags a chain over the Codex cap" "$big_out" \
  'defect:.*Codex stops adding nested files'
assert_match "counts the last line of a file with no trailing newline" "$big_out" \
  'defect: AGENTS\.md is 250 lines, over the 60 cap'
assert_match "measures a nested file against the wider cap" "$big_out" \
  'defect: pkg/AGENTS\.md is 210 lines, over the 200 cap'
assert_match "prints the root budget line" "$big_out" '^- AGENTS\.md  250 lines \(cap 60\)$'

mkdir -p "$OV/pkg"
printf '%s' 'root' > "$OV/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$OV/CLAUDE.md"
printf '%s' 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' > "$OV/pkg/AGENTS.md"
printf '%s' 'override-here' > "$OV/pkg/AGENTS.override.md"
printf '%s\n' '@AGENTS.md' > "$OV/pkg/CLAUDE.md"
set +e
ov_out="$(bash "$INTAKE" "$OV" 2>&1)"
set -e
assert_match "override replaces AGENTS.md in the chain total" "$ov_out" \
  'worst chain  pkg  17 bytes'

# A gitignored surface loads for its author and for nobody else, which only a
# real work tree can demonstrate.
git -C "$IGNORED" init -q
printf '%s\n' '# AGENTS.md' '1. Use pnpm.' > "$IGNORED/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$IGNORED/CLAUDE.md"
printf '%s\n' 'personal overrides' > "$IGNORED/CLAUDE.local.md"
mkdir -p "$IGNORED/local"
printf '%s\n' '# private overlay' > "$IGNORED/local/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$IGNORED/local/CLAUDE.md"
printf '%s\n' 'local/' 'CLAUDE.local.md' > "$IGNORED/.gitignore"
run_readonly "$IGNORED" "$IGNORED"
ignored_out="$READONLY_OUTPUT"
assert_match "flags a gitignored surface" "$ignored_out" 'defect: local/AGENTS\.md is gitignored'
assert_no_match "does not flag a tracked surface as ignored" "$ignored_out" \
  'defect: AGENTS\.md is gitignored'
assert_no_match "exempts CLAUDE.local.md from the gitignore check" "$ignored_out" \
  'defect: CLAUDE\.local\.md is gitignored'
assert_no_match "a CLAUDE.local.md body is not a missing import" "$ignored_out" \
  'defect: CLAUDE\.local\.md carries a body'

set +e
sub_out="$(bash "$INTAKE" "$IGNORED/local" 2>&1)"
set -e
assert_match "warns when run below the repo root" "$sub_out" '^warning: not at the repo root'

echo "== intake: empty repo =="

# A repo with a manifest and no context surface at all: the one case where the
# skill creates context only when a concrete hazard requires it.
printf '%s\n' '{"name":"x","scripts":{"test":"vitest run"}}' > "$BARE/package.json"
run_readonly "$BARE" "$BARE"
bare_out="$READONLY_OUTPUT"
bare_files="$(awk '/^## files/, /^## trees/' <<< "$bare_out")"
assert_match "an empty repo lists no context file" "$bare_files" '^- none$'
assert_match "an empty repo does not require scaffolding" "$bare_out" \
  '^note: no context file; create one only for a concrete hazard; see references/prescriptions\.md$'
assert_match "an empty repo has no mechanical defect" "$bare_out" '^0 mechanical defects'
bare_loaded="$(awk '/^## loaded set/, /^## classify/' <<< "$bare_out")"
assert_eq "every tool loads nothing" \
  "$(grep -cE '^- (claude-code|codex|cursor|grok|opencode)  nothing$' <<< "$bare_loaded")" "5"

set +e
bash "$INTAKE" --strict "$BARE" > /dev/null 2>&1
ec=$?
set -e
assert_eq "--strict on an empty repo exits 0" "$ec" "0"

echo "== intake: AGENTS.md alone =="

# Claude Code v2.1.277 reads AGENTS.md when no CLAUDE.md is on the path, so a
# repo that already has the portable handbook must not be told to add a bridge.
printf '%s\n' '# AGENTS.md' '1. Use pnpm.' > "$BARE/AGENTS.md"
run_readonly "$BARE" "$BARE"
agents_only_out="$READONLY_OUTPUT"
assert_match "AGENTS.md alone reports zero defects" "$agents_only_out" '^0 mechanical defects'
assert_no_match "AGENTS.md alone is not a missing Claude bridge" "$agents_only_out" \
  'has no CLAUDE\.md beside it'
agents_only_loaded="$(awk '/^## loaded set/, /^## classify/' <<< "$agents_only_out")"
assert_match "claude-code loads AGENTS.md when there is no CLAUDE.md" "$agents_only_loaded" \
  '^- claude-code  AGENTS\.md  [0-9]+ bytes always-on$'
assert_match "codex still holds the handbook alone" "$agents_only_loaded" \
  '^- codex  AGENTS\.md  [0-9]+ bytes always-on$'
set +e
bash "$INTAKE" --strict "$BARE" > /dev/null 2>&1
ec=$?
set -e
assert_eq "--strict on AGENTS.md alone exits 0" "$ec" "0"
rm -f "$BARE/AGENTS.md"

echo "== vitals: argument handling =="

set +e
out="$(python3 "$VITALS" "/tmp/context-doctor-missing-$$" 2>&1)"
ec=$?
set -e
assert_eq "vitals on a missing root exits 2" "$ec" "2"
assert_match "vitals names the missing path" "$out" 'not a directory: /tmp/context-doctor-missing'

set +e
python3 "$VITALS" --nope . > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals rejects an unknown flag" "$ec" "2"

set +e
python3 "$VITALS" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals requires a repo root" "$ec" "2"

echo "== scanner fixtures: bloated and valid layouts =="

# The before: one root file carrying every state at once, on a repo whose
# manifest, pin and formatter answer half of it already. Each line below is the
# one instance of its state, and the padding is inert on purpose — a fixture
# where everything fires proves nothing about what fires.
mkdir -p "$BLOAT/src" "$BLOAT/docs" "$BLOAT/tests" "$BLOAT/packages/api"
printf '%s\n' 'export const a = 1' > "$BLOAT/src/a.ts"
printf '%s\n' '# notes' > "$BLOAT/docs/notes.md"
printf '%s\n' 'export const t = 1' > "$BLOAT/tests/a.test.ts"
printf '%s\n' 'export const api = 1' > "$BLOAT/packages/api/index.ts"
printf '%s\n' '{"name":"x","scripts":{"test":"vitest run","lint":"eslint .","build":"tsc -p ."}}' \
  > "$BLOAT/package.json"
printf '%s\n' '18' > "$BLOAT/.nvmrc"
printf '%s\n' '{}' > "$BLOAT/.prettierrc"
# shellcheck disable=SC2016  # backticks are the markdown being written, not a subshell
{
  printf '%s\n' '# CLAUDE.md' ''
  printf '%s\n' '## Project structure' ''
  printf '%s\n' '- src/ — sources' '- docs/ — documentation' '- tests/ — the test suite' \
    '- packages/ — workspace packages' '- packages/api/ — the API package' \
    '├── src/ — where the modules live' ''
  printf '%s\n' '## Tech stack' ''
  printf '%s\n' '- Node 20 and TypeScript 5.' '- React 18 on the front end.' ''
  printf '%s\n' '## Commands' ''
  printf '%s\n' '- Test: npm run test' '- Lint: npm run lint' '- Deploy: npm run deploy' ''
  printf '%s\n' '## Critical rules' ''
  printf '%s\n' '1. Use 2 spaces for indentation and single quotes.' \
    '2. Run prettier before every commit.' \
    '3. Always run npm test before committing.' \
    '4. Ask before changing a public response shape in `packages/api/`.' ''
  printf '%s\n' '## Reference' ''
  printf '%s\n' 'See `scripts/gone.sh` for details.' ''
  printf '%s\n' '## Release procedure' ''
  printf '%s\n' '1. Update the changelog with the new version.' \
    '2. Bump the version in package.json.' \
    '3. Build the bundle from a clean tree.' \
    '4. Publish the package to the registry.' \
    '5. Tag the commit with the version.' \
    '6. Push the tag to the remote.' ''
  printf '%s\n' '## Notes' ''
  awk 'BEGIN { for (i = 1; i <= 256; i++) printf "%d. Keep helper %d under review.\n", i, i }'
} > "$BLOAT/CLAUDE.md"

run_readonly_cmd "$BLOAT" vitals python3 "$VITALS" "$BLOAT"
bloat_vitals="$READONLY_OUTPUT"
run_readonly_cmd "$BLOAT" intake bash "$INTAKE" "$BLOAT"
bloat_intake="$READONLY_OUTPUT"

assert_match "vitals counts the root file's lines" "$bloat_vitals" \
  '^- CLAUDE\.md  300 lines  ~[0-9]+ tokens  root$'
assert_match "one file carries all five unhealthy states" "$bloat_vitals" \
  '^  diagnosis: bloated, derivable, redundant, stale, misplaced$'
assert_match "a directory tour is derivable" "$bloat_vitals" \
  '^  - L5 derivable: - src/ — sources  \(section Project structure'
assert_match "a command that restates the manifest is derivable" "$bloat_vitals" \
  '^  - L19 derivable: - Test: npm run test  \(listed in package\.json\)$'
assert_match "a style rule the formatter owns is enforced" "$bloat_vitals" \
  '^  - L25 enforced: .*\(owned by prettier'
assert_match "a version the pin contradicts is stale" "$bloat_vitals" \
  '^  - L14 stale: .*\(repo pins 18 \(\.nvmrc\)\)$'
assert_match "a script that does not exist is stale" "$bloat_vitals" \
  '^  - L21 stale: .*\(npm has no script deploy\)$'
assert_match "a path that does not exist is stale" "$bloat_vitals" \
  '^  - L32 stale: .*\(path does not exist\)$'
assert_match "an always with no hook is misplaced" "$bloat_vitals" \
  '^  - L27 misplaced/hook: '
assert_match "a rule about a subtree is misplaced" "$bloat_vitals" \
  '^  - L28 misplaced/rule: '
assert_match "a numbered procedure is misplaced" "$bloat_vitals" \
  '^  - L34 misplaced/skill: .*6-step procedure'

bloat_json="$(python3 "$VITALS" --json "$BLOAT")"
assert_eq "the root file is reported as the root" \
  "$(json_file_probe "$bloat_json" CLAUDE.md 'e["root"]')" "True"
assert_eq "at least five derivable lines" \
  "$(json_file_probe "$bloat_json" CLAUDE.md 'len(e["derivable"]) >= 5')" "True"
assert_eq "at least one enforced line" \
  "$(json_file_probe "$bloat_json" CLAUDE.md 'len(e["enforced"]) >= 1')" "True"
assert_eq "at least two stale lines" \
  "$(json_file_probe "$bloat_json" CLAUDE.md 'len(e["stale"]) >= 2')" "True"
for kind in hook skill rule; do
  assert_eq "a misplaced finding of kind $kind" \
    "$(json_file_probe "$bloat_json" CLAUDE.md "\"$kind\" in [m.get(\"kind\") for m in e[\"misplaced\"]]")" \
    "True"
done
assert_eq "the summary counts one bloated file" \
  "$(json_probe "$bloat_json" 'r["summary"]["bloated"]')" "1"

set +e
python3 "$VITALS" --strict "$BLOAT" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict on the before state exits 1" "$ec" "1"

assert_match "intake measures the root body against the root cap" "$bloat_intake" \
  'defect: CLAUDE\.md is 300 lines, over the 60 cap \(triage 15\)'
# With no AGENTS.md beside it the body is not a second copy of anything; it is
# the root file, in the one place OpenCode will not look for it.
assert_match "intake sends the body to AGENTS.md" "$bloat_intake" \
  'defect: CLAUDE\.md carries a body; make AGENTS\.md the home'

# This independent valid layout exercises scoping and adapters. It is not a
# reduction of BLOAT and cannot establish that a treatment preserved behavior.
mkdir -p "$TREATED/src/generated" "$TREATED/docs" "$TREATED/tests" "$TREATED/packages/api" \
  "$TREATED/.claude/rules" "$TREATED/.claude/hooks" "$TREATED/.cursor/rules"
printf '%s\n' 'export const a = 1' > "$TREATED/src/a.ts"
printf '%s\n' 'export const g = 1' > "$TREATED/src/generated/index.ts"
printf '%s\n' '# notes' > "$TREATED/docs/notes.md"
printf '%s\n' 'export const t = 1' > "$TREATED/tests/a.test.ts"
printf '%s\n' 'export const api = 1' > "$TREATED/packages/api/index.ts"
printf '%s\n' '{"name":"x","scripts":{"vitest":"vitest run","build":"tsc -p ."},"packageManager":"pnpm@9.0.0"}' \
  > "$TREATED/package.json"
printf '%s\n' 'lockfileVersion: "9.0"' > "$TREATED/pnpm-lock.yaml"
# A formatter beside a root file that carries no style prose: the treated repo
# has to stay healthy next to the tool that would own half the before state.
printf '%s\n' '{}' > "$TREATED/.prettierrc"
# shellcheck disable=SC2016  # backticks are the markdown being written, not a subshell
{
  printf '%s\n' '# AGENTS.md' ''
  printf '%s\n' '## Critical rules' ''
  printf '%s\n' '1. Use pnpm. Never npm or yarn.'
  printf '%s\n' '2. Never edit `src/generated/`; run `pnpm run build` and keep the diff.' ''
  printf '%s\n' '## Where to look' ''
  printf '%s\n' '1. API rules → `packages/api/AGENTS.md`'
  printf '%s\n' '2. Route rules → `.claude/rules/api.md`'
} > "$TREATED/AGENTS.md"
printf '%s\n' '# api' "1. Run this package's tests with \`pnpm vitest run\`." \
  > "$TREATED/packages/api/AGENTS.md"
printf '%s\n' '## Rules' '' '1. Validate route input at the boundary before the handler.' \
  > "$TREATED/body.txt"
{
  # The YAML flow list, so the scoping key is proven in both spellings; the
  # contradictions fixture below keeps the block form.
  printf '%s\n' '---' 'paths: ["packages/api/**/*.ts"]' '---' ''
  cat "$TREATED/body.txt"
} > "$TREATED/.claude/rules/api.md"
{
  printf '%s\n' '---' 'description: API route conventions' 'globs: packages/api/**/*.ts' \
    'alwaysApply: false' '---' ''
  cat "$TREATED/body.txt"
} > "$TREATED/.cursor/rules/api.mdc"
rm -f "$TREATED/body.txt"
printf '%s\n' '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash .claude/hooks/test.sh"}]}]}}' \
  > "$TREATED/.claude/settings.json"
printf '%s\n' '#!/usr/bin/env bash' 'pnpm test' > "$TREATED/.claude/hooks/test.sh"

treated_vitals="$(python3 "$VITALS" "$TREATED")"
treated_json="$(python3 "$VITALS" --json "$TREATED")"
treated_intake="$(bash "$INTAKE" "$TREATED")"

# (a) the root file is under the cap the skill enforces everywhere else.
assert_match "the valid-layout root file is inside the 60-line cap" "$treated_intake" \
  '^- AGENTS\.md  ([1-9]|[1-5][0-9]|60) lines \(cap 60\)$'
assert_no_match "the valid-layout root file raises no budget defect" "$treated_intake" \
  'defect: AGENTS\.md is [0-9]+ lines'
# (b) nothing survives that the tree, the manifest or the lockfile already says.
assert_eq "no derivable line appears in the valid layout" \
  "$(json_probe "$treated_json" 'sum(len(f["derivable"]) for f in r["files"])')" "0"
# (c) the scanner recognizes enforcement already configured in this layout.
assert_eq "no always is left in prose" \
  "$(json_probe "$treated_json" 'sum(1 for f in r["files"] for m in f["misplaced"] if m.get("kind") == "hook")')" \
  "0"
treated_hooks="$(awk '/^### hooks/, /^## files/' <<< "$treated_intake")"
assert_match "the valid layout registers its existing hook" "$treated_hooks" \
  'PreToolUse: bash \.claude/hooks/test\.sh'
# (d) a nested file narrows the root; it never contradicts it.
assert_eq "no instruction contradicts another" \
  "$(json_probe "$treated_json" 'r["summary"]["contradictions"]')" "0"
# (e) `/context` is a user-run UI command, so the scriptable proxy for it is the
# loaded set intake computes from the tool matrix: what each of the five holds
# in this fixture, with the byte totals stripped so the shape is the subject.
treated_loaded="$(awk '/^## loaded set/, /^## classify/' <<< "$treated_intake" |
  grep -E '^- (claude-code|codex|cursor|grok|opencode)  ' |
  sed -E 's/  [0-9]+ bytes always-on$//')"
assert_eq "the loaded set matches the prescribed set" "$treated_loaded" "$(printf '%s\n' \
  '- claude-code  AGENTS.md, .claude/rules/api.md (scoped)' \
  '- codex  AGENTS.md' \
  '- cursor  AGENTS.md, .cursor/rules/api.mdc (scoped)' \
  '- grok  AGENTS.md, .claude/rules/api.md' \
  '- opencode  AGENTS.md')"

assert_eq "every valid-layout file is healthy" \
  "$(json_probe "$treated_json" 'all(f["diagnosis"] == ["healthy"] for f in r["files"])')" "True"
assert_no_match "the valid-layout report names no unhealthy state" "$treated_vitals" \
  '^  diagnosis: (bloated|derivable|redundant|stale|misplaced)'

set +e
python3 "$VITALS" --strict "$TREATED" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict on the valid layout exits 0" "$ec" "0"
set +e
bash "$INTAKE" --strict "$TREATED" > /dev/null 2>&1
ec=$?
set -e
assert_eq "intake --strict on the valid layout exits 0" "$ec" "0"

echo "== eval: empty =="

# The generated-file hazard must survive even with a manifest and task runner
# present; the scaffold should not manufacture any other instruction.
mkdir -p "$SCAFFOLD/src/schema/generated"
printf '%s\n' '[project]' 'name = "buildlog"' 'requires-python = ">=3.12"' > "$SCAFFOLD/pyproject.toml"
printf '%s\n' 'MODELS = {}' > "$SCAFFOLD/src/schema/generated/models.py"
printf '%s\n' 'codegen:' '    uv run python -m tools.codegen' > "$SCAFFOLD/justfile"

empty_vitals="$(python3 "$VITALS" "$SCAFFOLD")"
empty_json="$(python3 "$VITALS" --json "$SCAFFOLD")"
assert_match "vitals makes scaffolding conditional" "$empty_vitals" \
  '^no context file; create one only for a concrete hazard; see references/prescriptions\.md$'
assert_match "vitals counts no file and no healthy file" "$empty_vitals" '^0 files, 0 healthy;'
assert_eq "the json marks the repo absent" "$(json_probe "$empty_json" 'r["absent"]')" "True"

set +e
python3 "$VITALS" --strict "$SCAFFOLD" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict on a repo with no surface exits 0" "$ec" "0"

empty_intake="$(bash "$INTAKE" "$SCAFFOLD")"
empty_files="$(awk '/^## files/, /^## trees/' <<< "$empty_intake")"
assert_match "intake lists no context file" "$empty_files" '^- none$'
assert_match "intake makes scaffolding conditional" "$empty_intake" \
  '^note: no context file; create one only for a concrete hazard; see references/prescriptions\.md$'
assert_match "intake finds no mechanical defect" "$empty_intake" '^0 mechanical defects'

# Fill the shipped asset so the scaffold cannot hide generic rules behind a
# separate hand-written example that happens to pass the scanners.
python3 - "$SKILL_DIR/assets/AGENTS.md.template" "$SCAFFOLD/AGENTS.md" << 'PY_TEMPLATE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
rule = "Never edit `src/schema/generated/`; run `just codegen`."
start = source.index("<")
end = source.index(">", start) + 1
Path(sys.argv[2]).write_text(source[:start] + rule + source[end:])
PY_TEMPLATE
assert_eq "one justified rule produces one instruction" \
  "$(grep -cE '^[0-9]+\. ' "$SCAFFOLD/AGENTS.md")" "1"

scaffold_vitals="$(python3 "$VITALS" "$SCAFFOLD")"
scaffold_json="$(python3 "$VITALS" --json "$SCAFFOLD")"
scaffold_intake="$(bash "$INTAKE" "$SCAFFOLD")"
assert "the scaffolded root file is inside the 60-line cap" \
  test "$(grep -c '' "$SCAFFOLD/AGENTS.md")" -le 60
assert_eq "every scaffolded file is healthy" \
  "$(json_probe "$scaffold_json" 'all(f["diagnosis"] == ["healthy"] for f in r["files"])')" "True"
assert_no_match "the scaffold names no unhealthy state" "$scaffold_vitals" \
  '^  diagnosis: (bloated|derivable|redundant|stale|misplaced)'
assert_no_match "the scaffold does not add a CLAUDE.md bridge" "$scaffold_intake" \
  '^- CLAUDE\.md'
scaffold_loaded="$(awk '/^## loaded set/, /^## classify/' <<< "$scaffold_intake")"
assert_match "claude-code loads the scaffolded AGENTS.md" "$scaffold_loaded" \
  '^- claude-code  AGENTS\.md  [0-9]+ bytes always-on$'

set +e
python3 "$VITALS" --strict "$SCAFFOLD" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict on the scaffold exits 0" "$ec" "0"
set +e
bash "$INTAKE" --strict "$SCAFFOLD" > /dev/null 2>&1
ec=$?
set -e
assert_eq "intake --strict on the scaffold exits 0" "$ec" "0"

echo "== eval: redirect =="

# The complaint this skill exists for: a root file that reads short and spends
# long. Every line below is inside the line cap and none of them is derivable,
# enforced or stale, so nothing but the pointer scoring can catch them.
mkdir -p "$REDIR/docs" "$REDIR/.claude/rules" "$REDIR/.claude/skills" "$REDIR/.cursor/rules" \
  "$REDIR/.agents/skills/deploy" "$REDIR/.agents/skills/secret" "$REDIR/.github/workflows" "$REDIR/src"
printf '%s\n' 'name: CI' 'on: push' > "$REDIR/.github/workflows/ci.yml"
printf '%s\n' 'export const a = 1' > "$REDIR/src/a.ts"
printf '%s\n' '# ports' '' 'The dev server listens on 3000.' > "$REDIR/docs/tiny.md"
awk 'BEGIN { print "# big"; for (i = 1; i <= 200; i++)
  print "Paragraph " i " of the domain specification, carried in full on every read." }' \
  > "$REDIR/docs/big.md"
printf '%s\n' '---' 'paths:' '  - "src/**/*.ts"' '---' '' '## Rules' '' \
  '1. Validate at the boundary.' > "$REDIR/.claude/rules/api.md"
printf '%s\n' '---' 'description: API' 'globs: src/**/*.ts' 'alwaysApply: false' '---' '' \
  '## Rules' '' '1. Validate at the boundary.' > "$REDIR/.cursor/rules/api.mdc"
printf '%s\n' '---' 'name: deploy' 'description: Deploy the service.' '---' '# deploy' \
  > "$REDIR/.agents/skills/deploy/SKILL.md"
printf '%s\n' '---' 'name: secret' 'description: Cut a hotfix.' \
  'disable-model-invocation: true' '---' '# secret' > "$REDIR/.agents/skills/secret/SKILL.md"
ln -s ../../.agents/skills/deploy "$REDIR/.claude/skills/deploy"
ln -s ../../.agents/skills/secret "$REDIR/.claude/skills/secret"
printf '%s\n' '{"name":"x","scripts":{"test":"vitest run"},"packageManager":"pnpm@9.0.0"}' \
  > "$REDIR/package.json"
# shellcheck disable=SC2016  # backticks are the markdown being written, not a subshell
{
  printf '%s\n' '# AGENTS.md' ''
  printf '%s\n' '## Critical rules' ''
  printf '%s\n' '1. Use pnpm. Never npm or yarn.' ''
  printf '%s\n' '## Read before guessing' ''
  printf '%s\n' '- Domain rules and flows: `docs/big.md`, then the package spec its nested `AGENTS.md` names.'
  printf '%s\n' '- Read `docs/big.md` before guessing.'
  printf '%s\n' '- The nearest nested `AGENTS.md` overrides `.claude/rules/api.md`, and the `.cursor/rules/api.mdc` beside it is not a second copy.'
  printf '%s\n' '- Port numbers → `docs/tiny.md`.'
  printf '%s\n' '- Cutting a release → `.agents/skills/deploy/SKILL.md`.'
  printf '%s\n' '- Cutting a hotfix → `.agents/skills/secret/SKILL.md`.'
  printf '%s\n' '- CI change → `.github/workflows/ci.yml`.'
} > "$REDIR/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$REDIR/CLAUDE.md"

run_readonly_cmd "$REDIR" vitals python3 "$VITALS" "$REDIR"
redir_vitals="$READONLY_OUTPUT"
redir_json="$(python3 "$VITALS" --json "$REDIR")"

assert_match "a short file over its destination budget is redirect" "$redir_vitals" \
  '^  diagnosis: redirect$'
assert_match "the root file is inside the line cap it fails on spend" "$redir_vitals" \
  '^- AGENTS\.md  1[0-9] lines'
for kind in chain unbounded meta inline listed budget; do
  assert_eq "a redirect finding of kind $kind" \
    "$(json_file_probe "$redir_json" AGENTS.md "\"$kind\" in [m.get(\"kind\") for m in e[\"redirect\"]]")" \
    "True"
done
assert_match "a chain names its destination count and its price" "$redir_vitals" \
  'redirect/chain: .*2 destinations in one line — ~[0-9]+ tokens per hit'
assert_match "an undecidable trigger names what it cannot decide" "$redir_vitals" \
  'redirect/unbounded: .*no trigger a model can decide'
assert_match "a pointer at a small file is carried instead" "$redir_vitals" \
  'redirect/inline: .*docs/tiny\.md carries ~[0-9]+ tokens'
assert_match "the destination budget is measured against the cap" "$redir_vitals" \
  'redirect/budget: .*8 destinations, over the 5 cap'
assert_match "undecidable reading is measured against the file" "$redir_vitals" \
  'redirect/budget: .*tokens of reading it gives no way to skip'
assert_match "the report carries a budget block" "$redir_vitals" \
  '^~[0-9]+ inventoried context tokens; [0-9]+ pointers to ~[0-9]+ induced tokens, ~[0-9]+ of them undecidable$'
# The two lines that earn their place: one map entry at a hidden skill, one at a
# path. A suite that fires on these would push every repo to carry everything.
assert_eq "only one skill line is a repeat of the listing" \
  "$(json_file_probe "$redir_json" AGENTS.md 'sum(1 for m in e["redirect"] if m.get("kind") == "listed")')" \
  "1"
assert_eq "the summary counts one redirect file" \
  "$(json_probe "$redir_json" 'r["summary"]["redirect"]')" "1"

set +e
python3 "$VITALS" --strict "$REDIR" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict on a reading list exits 1" "$ec" "1"

# Only the redundant skill pointer is removed. Skill discovery and shared
# documents must survive a reduction of their callers.
redir_skill_before="$(tree_digest "$REDIR/.agents/skills")"
redir_document_before="$(cksum < "$REDIR/docs/big.md")"
rm -f "$REDIR/docs/tiny.md"
# shellcheck disable=SC2016  # backticks are the markdown being written, not a subshell
{
  printf '%s\n' '# AGENTS.md' ''
  printf '%s\n' '## Critical rules' ''
  printf '%s\n' '1. Use pnpm. Never npm or yarn.'
  printf '%s\n' '2. The dev server listens on 3000.' ''
  printf '%s\n' '## Where to look' ''
  printf '%s\n' '1. Domain rule change → `docs/big.md` (~3675 tokens).'
  printf '%s\n' '2. Cutting a hotfix → `.agents/skills/secret/SKILL.md`.'
  printf '%s\n' '3. CI change → `.github/workflows/ci.yml`.'
} > "$REDIR/AGENTS.md"

assert "removing a listed-skill pointer preserves its discovery link" test -e "$REDIR/.claude/skills/deploy"
assert_eq "removing a skill pointer preserves skill content" "$(tree_digest "$REDIR/.agents/skills")" "$redir_skill_before"
assert_eq "narrowing a document pointer preserves the document" "$(cksum < "$REDIR/docs/big.md")" "$redir_document_before"

treated_redir_json="$(python3 "$VITALS" --json "$REDIR")"
assert_eq "every treated file is healthy" \
  "$(json_probe "$treated_redir_json" 'all(f["diagnosis"] == ["healthy"] for f in r["files"])')" "True"
assert_eq "no undecidable reading survives" \
  "$(json_probe "$treated_redir_json" 'r["summary"]["unbounded_tokens"]')" "0"
assert_eq "the surviving entries are inside the root budget" \
  "$(json_file_probe "$treated_redir_json" AGENTS.md 'e["pointer_count"] <= 5')" "True"
# Progressive disclosure has to survive the treatment, or the only passing repo
# is one that carries every document in its always-on file.
assert_eq "a priced entry at a large document is still allowed" \
  "$(json_file_probe "$treated_redir_json" AGENTS.md 'e["induced_tokens"] > 1000')" "True"

set +e
python3 "$VITALS" --strict "$REDIR" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict after the treatment exits 0" "$ec" "0"

echo "== eval: contradictions =="

# Three disagreements a reader would have to hold in their head at once: a
# package manager, a line limit and a rule the scoped file reverses. Which one
# wins depends on the tool's precedence, which is why none of them may stand.
mkdir -p "$CONTRA/packages/api" "$CONTRA/.claude/rules"
printf '%s\n' '{"name":"x","scripts":{"vitest":"vitest run"},"packageManager":"pnpm@9.0.0"}' \
  > "$CONTRA/package.json"
printf '%s\n' 'export const api = 1' > "$CONTRA/packages/api/x.ts"
# `Wrap at 100 columns` on purpose: the limit reader matches `wrap at` and not
# `wrap lines at`, so the phrasing here is the one the heuristic sees.
printf '%s\n' '1. Use pnpm. Never npm or yarn.' '2. Wrap at 100 columns.' \
  '3. Always run tests from the repo root.' > "$CONTRA/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$CONTRA/CLAUDE.md"
printf '%s\n' '1. Install with npm install.' '2. Max line length 80 columns.' \
  > "$CONTRA/packages/api/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$CONTRA/packages/api/CLAUDE.md"
printf '%s\n' '---' 'paths:' '  - "packages/api/**/*.ts"' '---' '' \
  '1. Never run tests from the repo root.' > "$CONTRA/.claude/rules/api.md"

contra_vitals="$(python3 "$VITALS" "$CONTRA")"
contra_json="$(python3 "$VITALS" --json "$CONTRA")"
contra_block="$(awk '/^## contradictions/, /^## summary/' <<< "$contra_vitals")"
assert_eq "three disagreements are reported" \
  "$(grep -cE '^- [^n]' <<< "$contra_block")" "3"
assert_match "the package manager pair names both files" "$contra_block" \
  '^- AGENTS\.md:1 ".*" vs packages/api/AGENTS\.md:1 ".*"  \(package manager\)$'
assert_match "the line limit pair names its unit and both numbers" "$contra_block" \
  '\(columns limit: 100 vs 80\)$'
assert_match "the scoped rule reversing the root is a pair" "$contra_block" \
  '^- \.claude/rules/api\.md:[0-9]+ ".*" vs AGENTS\.md:3 ".*"  \(opposite verb'
assert_eq "the summary counts at least three contradictions" \
  "$(json_probe "$contra_json" 'r["summary"]["contradictions"] >= 3')" "True"

set +e
python3 "$VITALS" --strict "$CONTRA" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict on a contradicting repo exits 1" "$ec" "1"

contra_intake="$(bash "$INTAKE" "$CONTRA")"
contra_nested="$(awk '/^## nested/, /^## loaded set/' <<< "$contra_intake")"
assert_match "intake lists the nested handbook that disagrees" "$contra_nested" \
  '^- packages/api/AGENTS\.md  \('

# The treatment: the nested file narrows instead of reversing, the root drops the
# limit the linter would own, and the scoped rule says something the root does not.
printf '%s\n' '1. Use pnpm. Never npm or yarn.' '2. Always run tests from the repo root.' \
  > "$CONTRA/AGENTS.md"
printf '%s\n' "1. Run tests from this package: \`pnpm vitest run\`." \
  > "$CONTRA/packages/api/AGENTS.md"
printf '%s\n' '---' 'paths:' '  - "packages/api/**/*.ts"' '---' '' \
  '1. Validate route input at the boundary before the handler.' > "$CONTRA/.claude/rules/api.md"

treated_contra_json="$(python3 "$VITALS" --json "$CONTRA")"
assert_eq "the treatment leaves no contradiction" \
  "$(json_probe "$treated_contra_json" 'r["summary"]["contradictions"]')" "0"
assert_eq "every file that disagreed is healthy" \
  "$(json_probe "$treated_contra_json" 'all(f["diagnosis"] == ["healthy"] for f in r["files"])')" "True"

set +e
python3 "$VITALS" --strict "$CONTRA" > /dev/null 2>&1
ec=$?
set -e
assert_eq "vitals --strict after the treatment exits 0" "$ec" "0"

echo "== eval: map =="

mkdir -p "$MAP/docs"
printf '%s\n' '1. Use pnpm. Never npm or yarn.' \
  '2. Read `docs/setup.md` before installing.' > "$MAP/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$MAP/CLAUDE.md"
printf '%s\n' '1. Install with npm install.' > "$MAP/docs/setup.md"

map_vitals="$(python3 "$VITALS" "$MAP")"
map_json="$(python3 "$VITALS" --json "$MAP")"
assert_match "vitals prints the agentic map" "$map_vitals" '^## map$'
assert_match "map names the CLAUDE.md import" "$map_vitals" \
  'CLAUDE\.md:1  import → AGENTS\.md'
assert_match "map names the prose-read" "$map_vitals" \
  'AGENTS\.md:2  prose-read → docs/setup.md'
assert_eq "json map has an import edge" \
  "$(json_probe "$map_json" 'any(e["kind"]=="import" and e["to"].endswith("AGENTS.md") for e in r["map"])')" \
  "True"
assert_match "a prose-read destination that contradicts is a pair" "$map_vitals" \
  'package manager'

printf '%s\n' 'Read `AGENTS.md` before any work.' > "$MAP/CLAUDE.md"
map_prose="$(python3 "$VITALS" "$MAP")"
assert_match "vitals flags a prose-read that is not an import" "$map_prose" 'prose-import'

echo "== eval: import resolution =="

mkdir -p "$POINTERS/packages/api" "$POINTERS/.claude"
printf '%s\n' '# Root handbook' > "$POINTERS/AGENTS.md"
printf '%s\n' '# API handbook' > "$POINTERS/packages/api/AGENTS.md"
printf '%s\n' '@AGENTS.md' > "$POINTERS/CLAUDE.md"
printf '%s\n' '---' 'description: API bridge' '---' '' '@AGENTS.md' > "$POINTERS/packages/api/CLAUDE.md"
printf '%s\n' '@../AGENTS.md' > "$POINTERS/.claude/CLAUDE.md"
pointer_json="$(python3 "$VITALS" --json "$POINTERS")"
assert_eq "a nested import selects its sibling handbook and actual line" \
  "$(json_probe "$pointer_json" 'any(e["from"] == "packages/api/CLAUDE.md" and e["to"] == "packages/api/AGENTS.md" and e["line"] == 5 for e in r["map"])')" "True"
assert_eq "a parent import resolves against its containing file" \
  "$(json_probe "$pointer_json" 'any(e["from"] == ".claude/CLAUDE.md" and e["to"] == "AGENTS.md" for e in r["map"])')" "True"
assert_eq "valid imports stay healthy" \
  "$(json_probe "$pointer_json" 'all(e["diagnosis"] == ["healthy"] for e in r["files"] if e["pointer"])')" "True"
pointer_intake="$(bash "$INTAKE" "$POINTERS")"
root_bytes="$(wc -c < "$POINTERS/AGENTS.md" | tr -d ' ')"
assert_match "intake prices the parent import destination" "$pointer_intake" \
  "^- claude-code .* $((root_bytes * 2)) bytes always-on$"
assert_no_match "valid import targets produce no missing-target defect" "$pointer_intake" \
  'import target missing or not a file'

for target in missing/AGENTS.md packages/api; do
  printf '@%s\n' "$target" > "$POINTERS/CLAUDE.md"
  pointer_vitals="$(python3 "$VITALS" "$POINTERS")"
  assert_match "vitals explains the invalid import $target" "$pointer_vitals" \
    'stale: .*import target missing or not a file'
  pointer_intake="$(bash "$INTAKE" "$POINTERS")"
  assert_match "intake explains the invalid import $target" "$pointer_intake" \
    'defect: CLAUDE.md import target missing or not a file'
  set +e
  python3 "$VITALS" --strict "$POINTERS" > /dev/null 2>&1
  vitals_ec=$?
  bash "$INTAKE" --strict "$POINTERS" > /dev/null 2>&1
  intake_ec=$?
  set -e
  assert_eq "vitals strict rejects the invalid import $target" "$vitals_ec" "1"
  assert_eq "intake strict rejects the invalid import $target" "$intake_ec" "1"
done

printf '%s\n' '@AGENTS.md' > "$POINTERS/CLAUDE.md"
rm "$POINTERS/packages/api/AGENTS.md"
pointer_json="$(python3 "$VITALS" --json "$POINTERS")"
assert_eq "a root handbook cannot hide a missing sibling import" \
  "$(json_file_probe "$pointer_json" packages/api/CLAUDE.md 'e["diagnosis"]')" "['stale']"
ln -s missing.md "$POINTERS/AGENTS.override.md"
pointer_json="$(python3 "$VITALS" --json "$POINTERS")"
assert_eq "vitals rejects a dangling context symlink" \
  "$(json_file_probe "$pointer_json" AGENTS.override.md 'e["diagnosis"]')" "['stale']"
rm "$POINTERS/AGENTS.override.md"
ln -s AGENTS.md "$POINTERS/AGENTS.override.md"
pointer_json="$(python3 "$VITALS" --json "$POINTERS")"
assert_eq "a valid context symlink stays healthy" \
  "$(json_file_probe "$pointer_json" AGENTS.override.md 'e["diagnosis"]')" "['healthy']"

echo
echo "$PASS passed, $FAIL failed"
if ((FAIL > 0)); then
  printf 'Failed:\n'
  printf '  - %s\n' "${failures[@]}"
  exit 1
fi
