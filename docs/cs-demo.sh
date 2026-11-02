#!/usr/bin/env bash
# Builds the example ~/.local/src for docs/cs.tape in /tmp/cs-demo: a fake HOME
# with foo repos, Claude Code transcripts in two accounts, and a stub herdr with
# two open sessions. It reads no real repo or session. Needs git, jq and macOS date.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
D=/tmp/cs-demo
rm -rf "$D"
export HOME=$D/home GIT_CONFIG_GLOBAL=$D/home/.gitconfig GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Foo GIT_AUTHOR_EMAIL=foo@example.com GIT_COMMITTER_NAME=Foo GIT_COMMITTER_EMAIL=foo@example.com
src=$HOME/.local/src
mkdir -p "$src" "$D/remotes" "$D/bin"
git config --global init.defaultBranch main
# The prompt of the shell that ctrl-t opens.
printf '%s\n' "PROMPT='%F{blue}%~%f %# '" > "$HOME/.zshrc"

commit() { # dir, message, file
  mkdir -p "$1/$(dirname "$3")"
  echo "$2" >> "$1/$3"
  git -C "$1" add -A
  git -C "$1" commit -qm "$2"
}
repo() { # owner/repo, then "message|file" pairs
  local r=$1 m
  shift
  git init -q --bare "$D/remotes/$r.git"
  git clone -q "$D/remotes/$r.git" "$src/$r/main" 2> /dev/null
  for m; do commit "$src/$r/main" "${m%%|*}" "${m#*|}"; done
  git -C "$src/$r/main" push -q -u origin main
}

# acme/api/main is 1 commit behind; feat-rate-limit is 2 ahead with 3 changed files.
repo acme/api "chore: init|README.md" "feat: add /health endpoint|src/health.ts" \
  "fix: retry on 503 from billing|src/billing.ts" "feat: paginate /orders|src/orders.ts"
git clone -q "$D/remotes/acme/api.git" "$D/other-api"
commit "$D/other-api" "chore(deps): bump express to 5.1" package.json
git -C "$D/other-api" push -q
git -C "$src/acme/api/main" fetch -q
git -C "$src/acme/api/main" worktree add -q -b feat/rate-limit ../feat-rate-limit
git -C "$src/acme/api/feat-rate-limit" push -q -u origin feat/rate-limit 2> /dev/null
commit "$src/acme/api/feat-rate-limit" "feat: token bucket per API key" src/middleware/rate_limit.ts
commit "$src/acme/api/feat-rate-limit" "test: cover burst limits" test/rate_limit.test.ts
echo "export const limit = 100" >> "$src/acme/api/feat-rate-limit/src/middleware/rate_limit.ts"
echo "burst: 20" >> "$src/acme/api/feat-rate-limit/test/rate_limit.test.ts"
echo "export const limits = {}" > "$src/acme/api/feat-rate-limit/src/limits.ts"

# acme/web/fix-login-redirect is 1 ahead with 1 changed file.
repo acme/web "chore: init|README.md" "feat: settings page|src/settings.tsx" "fix: focus ring on buttons|src/button.css"
git -C "$src/acme/web/main" worktree add -q -b fix/login-redirect ../fix-login-redirect
git -C "$src/acme/web/fix-login-redirect" push -q -u origin fix/login-redirect 2> /dev/null
commit "$src/acme/web/fix-login-redirect" "fix: keep next= param on login" src/login.tsx
echo "test('keeps next=')" >> "$src/acme/web/fix-login-redirect/src/login.tsx"

repo foo/bar "chore: init|README.md" "docs: add usage|README.md"

# Transcripts with only what cs reads: the folder, entrypoint, AI title and prompts.
proj=$(printf '%s' "$src" | sed 's/[^[:alnum:]]/-/g')
session() { # account ("" for the default), checkout, minutes ago, title, prompts...
  local home=$HOME/.claude${1:+-$1} co=$2 ago=$3 title=$4 id f p
  shift 4
  id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  mkdir -p "$home/projects/$proj-${co//\//-}"
  f=$home/projects/$proj-${co//\//-}/$id.jsonl
  jq -cn --arg cwd "$src/$co" --arg id "$id" --arg p "$1" \
    '{type: "user", cwd: $cwd, entrypoint: "cli", sessionId: $id, message: {role: "user", content: $p}}' > "$f"
  jq -cn --arg t "$title" --arg id "$id" '{type: "ai-title", aiTitle: $t, sessionId: $id}' >> "$f"
  for p; do jq -cn --arg p "$p" --arg id "$id" '{type: "last-prompt", lastPrompt: $p, sessionId: $id}' >> "$f"; done
  touch -t "$(date -v-"$ago"M +%Y%m%d%H%M.%S)" "$f"
}
session "" acme/web/fix-login-redirect 25 "Fix redirect loop after login" \
  "after a valid sign-in, /login sends me back to /login" "keep the next= param and add a test for it"
session work acme/api/main 190 "Upgrade to Postgres 17" \
  "plan the upgrade from Postgres 16 to 17" "run the migrations against a fresh container"
session "" acme/api/feat-rate-limit 1500 "Plan the rate limiter" \
  "plan a rate limit per API key, 100 requests a minute" "write the plan to docs/rate-limit.md"
session "" foo/bar/main 3000 "Add a CI badge to the README" "add the CI status badge to the README"
session "" acme/web/main 6000 "Why is the build slow?" "the build takes 4 minutes, find why" "cache the node_modules step"

# A stub herdr: two open sessions and the text of their panes.
cat > "$D/pane-w1.txt" << 'EOF'
⏺ The limiter is in src/middleware/rate_limit.ts: one token bucket per
  API key, 100 requests a minute, with a burst of 20.

⏺ Bash(npm test -- rate_limit)
  ⎿  Tests: 12 passed, 12 total

 Do you want to make this edit to src/limits.ts?
 ❯ 1. Yes
   2. Yes, allow all edits during this session
   3. No
EOF
cat > "$D/pane-w2.txt" << 'EOF'
⏺ Read(src/settings.tsx)
  ⎿  Read 182 lines

⏺ Update(src/theme.css)
  ⎿  Added 14 lines

✻ Adding the dark color tokens…
EOF
cat > "$D/bin/herdr" << EOF
#!/usr/bin/env bash
case "\$1 \$2" in
  "agent list") jq -n '{result: {agents: [
    {pane_id: "w1:p1", cwd: "$src/acme/api/feat-rate-limit", agent_status: "blocked", terminal_title_stripped: "Rate limit per API key"},
    {pane_id: "w2:p1", cwd: "$src/acme/web/main", agent_status: "working", terminal_title_stripped: "Dark mode for the settings page"}]}}' ;;
  "agent read") cat "$D/pane-\${3%%:*}.txt" ;;
esac
EOF
chmod +x "$D/bin/herdr"
ln -s "$repo_root/bin/cs" "$D/bin/cs"
