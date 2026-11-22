#!/usr/bin/env -S python3 -I
"""Sort the changed files of a GitHub PR, or print their patches in parts.

Read-only: it sends only GET requests, through the gh CLI. Standard library only.
The files API returns at most 3000 files, and leaves out the patch of a file
that is too large or binary. Each command says so when that happens.

Usage:
  changes.py inventory [PR]                 header, files by kind, areas, size
  changes.py patch PR [TARGET ...] [--part N]
                                            patches of the files in each TARGET,
                                            an area that inventory prints or a
                                            file path; with no TARGET, every
                                            file that is not noise
Areas do not overlap: a file is in exactly one area.
PR is a number, a URL or a branch. With no PR, the PR of the current branch.
"""

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from urllib.parse import urlparse

# Claude Code cuts a Bash output at 30,000 characters.
PART_CHARS = 25_000
LIST_CAP = 40
# Three folders deep splits `pkg/cmd/<command>/` into one area per command.
AREA_DEPTH = 3
API_FILE_CAP = 3000

KINDS = [
    ("noise", "lockfiles, generated, vendored, snapshots, binaries"),
    ("data", "migrations and schemas"),
    ("deps", "dependency manifests"),
    ("ci", "CI and automation"),
    ("config", "config, infra and build"),
    ("code", "source code"),
    ("tests", "tests"),
    ("docs", "docs"),
]

LOCKFILES = {
    "package-lock.json",
    "npm-shrinkwrap.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "bun.lockb",
    "bun.lock",
    "cargo.lock",
    "poetry.lock",
    "uv.lock",
    "pipfile.lock",
    "gemfile.lock",
    "composer.lock",
    "go.sum",
    "flake.lock",
    "podfile.lock",
    "package.resolved",
    "mix.lock",
    "pubspec.lock",
    "gradle.lockfile",
}
NOISE = re.compile(
    r"(^|/)(vendor|third_party|node_modules|dist|build|out|__generated__|generated|__snapshots__)/"
    r"|\.(min\.(js|css)|map|snap|lock|pb\.go|g\.dart|freezed\.dart)$"
    r"|_pb2(_grpc)?\.pyi?$|\.generated\.|\.gen\.(go|ts|js)$"
    r"|\.(png|jpe?g|gif|webp|ico|pdf|zip|gz|tgz|jar|woff2?|ttf|otf|mp4|mov|wasm|so|dylib|dll|exe)$",
    re.IGNORECASE,
)
DATA = re.compile(
    r"(^|/)(migrations?|migrate|alembic|db/schema|schemas?)/|(^|/)schema\.(prisma|rb|sql|graphql)$"
    r"|\.sql$|\.prisma$",
    re.IGNORECASE,
)
DEPS = {
    "package.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "go.mod",
    "cargo.toml",
    "gemfile",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "composer.json",
    "mix.exs",
    "pubspec.yaml",
    "podfile",
    "brewfile",
    "package.swift",
}
DEPS_RE = re.compile(r"(^|/)requirements[^/]*\.(txt|in)$|\.csproj$", re.IGNORECASE)
CI = re.compile(
    r"(^|/)(\.github/(workflows|actions)|\.circleci|\.buildkite|\.gitlab)/|(^|/)\.gitlab-ci\.yml$"
    r"|(^|/)jenkinsfile$|(^|/)\.github/dependabot\.yml$|(^|/)\.pre-commit-config\.yaml$",
    re.IGNORECASE,
)
CONFIG = re.compile(
    r"(^|/)(dockerfile|docker-compose[^/]*|compose\.ya?ml|makefile|justfile|procfile|\.env[^/]*)$"
    r"|(^|/)(terraform|infra|deploy|k8s|kubernetes|helm|charts|ansible|\.devcontainer)/"
    r"|\.(tf|tfvars|hcl|nix|ini|cfg|conf|toml|ya?ml|properties)$|(^|/)[^/]*\.config\.[a-z]+$"
    r"|(^|/)(tsconfig|eslint|prettier|babel|vite|webpack|jest|vitest)[^/]*$",
    re.IGNORECASE,
)
TESTS = re.compile(
    r"(^|/)(tests?|__tests__|spec|specs|e2e|testdata|fixtures?|__mocks__)/"
    r"|(_test\.go|_test\.py|_spec\.rb|\.test\.[a-z]+|\.spec\.[a-z]+|Tests?\.(swift|kt|java|cs))$"
    r"|(^|/)test_[^/]+\.py$|(^|/)conftest\.py$",
    re.IGNORECASE,
)
DOCS = re.compile(
    r"(^|/)(docs?|documentation)/|\.(md|mdx|rst|adoc|txt)$|(^|/)(license|changelog|readme)[^/]*$",
    re.IGNORECASE,
)
# A word in the path that hints at stored data, access or money. A hint only:
# the reader checks the diff.
SENSITIVE = re.compile(
    r"auth|login|logout|session|permission|rbac|acl|role|policy|secret|token|credential|crypt"
    r"|password|oauth|saml|sso|payment|billing|invoice|price|pricing|stripe|checkout|webhook",
    re.IGNORECASE,
)


def die(msg):
    print(f"changes.py: {msg}", file=sys.stderr)
    sys.exit(1)


def run(args):
    try:
        res = subprocess.run(args, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        die("gh is not installed. Install the GitHub CLI, then run `gh auth login`.")
    if res.returncode != 0:
        die(f"`{' '.join(args)}` failed: {res.stderr.strip() or res.stdout.strip()}")
    return res.stdout


def resolve(pr):
    fields = "number,url,title,state,isDraft,author,baseRefName,headRefName,baseRefOid,headRefOid,additions,deletions,changedFiles,commits"
    out = run(["gh", "pr", "view", *([pr] if pr else []), "--json", fields])
    meta = json.loads(out)
    url = urlparse(meta["url"])
    parts = url.path.strip("/").split("/")
    if len(parts) < 4 or parts[2] != "pull":
        die(f"cannot read the repo from the PR URL {meta['url']}")
    meta["host"] = url.hostname
    meta["repo"] = f"{parts[0]}/{parts[1]}"
    return meta


def files(meta, with_patch):
    keys = "filename, previous_filename, status, additions, deletions"
    jq = f".[] | {{{keys}{', patch' if with_patch else ''}, has_patch: (.patch != null)}}"
    out = run(
        [
            "gh",
            "api",
            "--hostname",
            meta["host"],
            "--paginate",
            "--jq",
            jq,
            f"repos/{meta['repo']}/pulls/{meta['number']}/files?per_page=100",
        ]
    )
    rows = [json.loads(line) for line in out.splitlines() if line.strip()]
    for row in rows:
        row["kind"] = kind(row["filename"], row)
    return rows


def kind(path, row):
    name = path.rsplit("/", 1)[-1].lower()
    if name in LOCKFILES or NOISE.search(path):
        return "noise"
    if (
        row["status"] != "removed"
        and not row["has_patch"]
        and row["additions"] + row["deletions"] == 0
    ):
        # A changed file with no patch and no lines is a binary or a mode change.
        return "noise"
    if DATA.search(path):
        return "data"
    if name in DEPS or DEPS_RE.search(path):
        return "deps"
    if CI.search(path):
        return "ci"
    if TESTS.search(path):
        return "tests"
    if DOCS.search(path):
        return "docs"
    if CONFIG.search(path):
        return "config"
    return "code"


def area(path):
    parts = path.split("/")[:-1]
    return "/".join(parts[:AREA_DEPTH]) + "/" if parts else "(repo root)"


def size(lines, count):
    by_lines = (
        "S" if lines < 100 else "M" if lines < 500 else "L" if lines < 2000 else "XL"
    )
    by_files = (
        "S" if count <= 5 else "M" if count <= 30 else "L" if count <= 100 else "XL"
    )
    order = "SMLX"
    return max(by_lines, by_files, key=lambda s: order.index(s[0]))


def label(row):
    path = row["filename"]
    if row["status"] == "renamed" and row.get("previous_filename"):
        path = f"{row['previous_filename']} -> {path}"
    flags = [row["status"]] if row["status"] not in ("modified", "renamed") else []
    if row["status"] == "renamed" and row["additions"] + row["deletions"] == 0:
        flags.append("pure rename")
    if not row["has_patch"] and row["kind"] != "noise":
        flags.append("no patch from GitHub")
    note = f" [{', '.join(flags)}]" if flags else ""
    return f"  +{row['additions']} -{row['deletions']}  {path}{note}"


def inventory(args):
    meta = resolve(args.pr)
    rows = files(meta, with_patch=False)
    signal = [r for r in rows if r["kind"] != "noise"]
    lines = sum(r["additions"] + r["deletions"] for r in signal)
    noise = sum(r["additions"] + r["deletions"] for r in rows if r["kind"] == "noise")

    draft = ", draft" if meta["isDraft"] else ""
    print(f"PR #{meta['number']}: {meta['title']}")
    print(f"{meta['url']}")
    print(
        f"state: {meta['state'].lower()}{draft}  author: {(meta.get('author') or {}).get('login', '?')}"
    )
    print(
        f"base: {meta['baseRefName']} @ {meta['baseRefOid'][:12]}  head: {meta['headRefName']} @ {meta['headRefOid'][:12]}"
    )
    print(
        f"repo: {meta['repo']}  host: {meta['host']}  commits: {len(meta.get('commits') or [])}"
    )
    print(
        f"github totals: {meta['changedFiles']} files, +{meta['additions']} -{meta['deletions']}"
    )
    print(
        f"size: {size(lines, len(signal))} ({len(signal)} files and {lines} lines that are not noise; {noise} noise lines)"
    )
    default = run(
        [
            "gh",
            "api",
            "--hostname",
            meta["host"],
            f"repos/{meta['repo']}",
            "--jq",
            ".default_branch",
        ]
    ).strip()
    if meta["baseRefName"] != default:
        print(
            f"stacked: the base is {meta['baseRefName']}, not the default branch {default}"
        )
    if len(rows) < meta["changedFiles"]:
        missing = meta["changedFiles"] - len(rows)
        cap = f" (the API stops at {API_FILE_CAP})" if len(rows) >= API_FILE_CAP else ""
        print(
            f"warning: the files API gave {len(rows)} of {meta['changedFiles']} files{cap}; {missing} files are not listed"
        )

    print("\nfiles by kind:")
    for key, desc in KINDS:
        group = sorted(
            (r for r in rows if r["kind"] == key),
            key=lambda r: -(r["additions"] + r["deletions"]),
        )
        if not group:
            continue
        add = sum(r["additions"] for r in group)
        dele = sum(r["deletions"] for r in group)
        print(f"\n{key}: {len(group)} files, +{add} -{dele} ({desc})")
        shown = group if args.all else group[:LIST_CAP]
        for r in shown:
            print(label(r))
        if len(group) > len(shown):
            print(f"  ... and {len(group) - len(shown)} more (run with --all)")

    areas = defaultdict(lambda: [0, 0])
    for r in signal:
        a = areas[area(r["filename"])]
        a[0] += 1
        a[1] += r["additions"] + r["deletions"]
    print(
        f"\nareas (files that are not noise, by folder up to {AREA_DEPTH} deep, most lines first; no overlap):"
    )
    for name, (count, n) in sorted(areas.items(), key=lambda kv: -kv[1][1]):
        print(f"  {n:>6} lines  {count:>4} files  {name}")

    hints = [r["filename"] for r in signal if SENSITIVE.search(r["filename"])]
    removed = [r["filename"] for r in rows if r["status"] == "removed"]
    if hints:
        print(
            f"\npath hints of access, stored data or money ({len(hints)}): "
            + ", ".join(hints[:LIST_CAP])
        )
    if removed:
        print(f"\nremoved files ({len(removed)}): " + ", ".join(removed[:LIST_CAP]))


def patch(args):
    meta = resolve(args.pr)
    rows = files(meta, with_patch=True)
    if args.target:
        targets = set(args.target)
        rows = [
            r
            for r in rows
            if r["filename"] in targets
            or (area(r["filename"]) in targets and r["kind"] != "noise")
        ]
    else:
        rows = [r for r in rows if r["kind"] != "noise"]
    if not rows:
        die("no changed file matches")

    chunks = []
    for r in rows:
        head = f"=== {r['filename']}"
        if r.get("previous_filename"):
            head += f" (from {r['previous_filename']})"
        head += f" [{r['status']}, {r['kind']}, +{r['additions']} -{r['deletions']}]"
        if r.get("patch"):
            body = r["patch"]
        else:
            ref = meta["baseRefOid"] if r["status"] == "removed" else meta["headRefOid"]
            body = (
                "(GitHub gives no patch: the file is too large, binary or only renamed. Read it with:\n"
                f" gh api --hostname {meta['host']} -H 'Accept: application/vnd.github.raw' "
                f"'repos/{meta['repo']}/contents/{r['filename']}?ref={ref}')"
            )
        chunks.append(f"{head}\n{body}\n")

    # Split at file borders, and inside a file only when it is larger than a part.
    parts, cur = [], ""
    for c in chunks:
        while len(c) > PART_CHARS:
            cut = c.rfind("\n", 0, PART_CHARS) + 1 or PART_CHARS
            if cur:
                parts.append(cur)
                cur = ""
            parts.append(c[:cut])
            c = c[cut:]
        if len(cur) + len(c) > PART_CHARS and cur:
            parts.append(cur)
            cur = ""
        cur += c
    if cur:
        parts.append(cur)

    if not 1 <= args.part <= len(parts):
        die(f"--part must be from 1 to {len(parts)}")
    print(parts[args.part - 1], end="")
    print(f"\n--- part {args.part} of {len(parts)}, {len(rows)} files", end="")
    print(f"; next: --part {args.part + 1}" if args.part < len(parts) else "; end")


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = ap.add_subparsers(dest="cmd", required=True)
    inv = sub.add_parser("inventory")
    inv.add_argument("pr", nargs="?")
    inv.add_argument("--all", action="store_true", help="list every file in each kind")
    pat = sub.add_parser("patch")
    pat.add_argument("pr")
    pat.add_argument("target", nargs="*")
    pat.add_argument("--part", type=int, default=1)
    args = ap.parse_args()
    inventory(args) if args.cmd == "inventory" else patch(args)


if __name__ == "__main__":
    main()
