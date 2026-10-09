#!/usr/bin/env python3
"""Score every agent-context file in a repo against what the repo already answers.

The golden rule of the skill: keep only what the agent would get wrong without
the line and can verify it did right. A line the tree, a manifest, a linter or a
hook already answers is a line to delete, and this script names those lines so a
repair has somewhere to start.

Read-only by contract. Nothing here writes into the repo under audit and nothing
runs a subprocess in it, so this is safe on a checkout nobody owns. Standard
library only, so it runs wherever python3 does. Every token figure is an
estimate and never a tokenizer result.

Usage: vitals.py [--json] [--strict] <repo-root>
  --json    one JSON object instead of the text report
  --strict  exit 1 when any file is not healthy or any contradiction was found
"""

import argparse
import json
import math
import os
import re
import sys
from pathlib import Path

USAGE = "vitals.py [--json] [--strict] <repo-root>"

# Directories whose contents are somebody else's checkout. Walking them turns a
# vendored AGENTS.md into a finding about a repo the user does not own.
PRUNE = {
    "node_modules", ".git", "vendor", "dist", "build", "target",
    ".venv", "venv", ".next", ".turbo", ".cache", "coverage",
}

CONTEXT_NAMES = {
    "AGENTS.md", "AGENTS.override.md", "AGENT.md", "Agents.md",
    "CLAUDE.md", "CLAUDE.local.md", "Claude.md", "CONTEXT.md", "GEMINI.md",
}
ROOT_NAMES = {
    "AGENTS.md", "AGENTS.override.md", "CLAUDE.md",
    "AGENT.md", "Agents.md", "Claude.md",
}
SINGLE_PATHS = {".cursorrules", ".windsurfrules", ".github/copilot-instructions.md"}
RULE_DIRS = {(".claude", "rules"): ".md", (".grok", "rules"): ".md",
             (".windsurf", "rules"): ".md", (".cursor", "rules"): ".mdc"}

# A root file is read in every session by every tool, and adherence drops past
# the first screenful: past this the file is longer than the attention it gets.
ROOT_LINE_CAP = 60
# Past this a model follows the first half and drifts on the rest, whatever the
# bottom of the file says.
ANY_LINE_CAP = 200

# A pointer is a purchase order, not a mention: the line costs its own tokens in
# every session, and the file it names costs its whole body in every session the
# model fills the order. Past this many destinations a context file is a reading
# list, and the budget it reports is not the budget it spends.
ROOT_POINTER_CAP = 5
ANY_POINTER_CAP = 12
# Reading a model cannot decide to skip, over this multiple of a file's own
# body, means the file spends most of its context by reference where no line
# count shows it. A priced map entry at a large document is progressive
# disclosure and is not counted here: that read is conditional by construction.
AMPLIFY_RATIO = 8
# A prose destination under this is cheaper carried as the one clause it holds
# than fetched: the pointer, the hop and the file all go.
INLINE_TOKENS = 120
# A destination directory is summed over its own markdown, never walked forever.
DEST_FILE_CAP = 40

# The whole report lands in a model's context window, so a file with a hundred
# findings of one kind prints a sample and a count instead of the hundred.
FINDING_CAP = 25

STATES = ("derivable", "enforced", "duplicate", "stale", "misplaced", "redirect")

MANIFESTS = ["package.json", "pyproject.toml", "Cargo.toml", "go.mod", "Gemfile",
             ".nvmrc", ".node-version", ".python-version", ".ruby-version",
             "rust-toolchain", "rust-toolchain.toml", ".tool-versions"]
# A version is derivable only from a manifest that can pin that name: a
# package.json says nothing about the interpreter a Python line names, so a
# name whose own manifests are all absent stays in prose.
NODE_VERSION_FILES = [".nvmrc", ".node-version", ".tool-versions"]
NODE_PKG_FILES = ["package.json"] + NODE_VERSION_FILES
PIN_SOURCES = {
    "node": NODE_VERSION_FILES + ["package.json"],
    "typescript": NODE_PKG_FILES,
    "react": NODE_PKG_FILES,
    "next": NODE_PKG_FILES,
    "nextjs": NODE_PKG_FILES,
    "vue": NODE_PKG_FILES,
    "python": [".python-version", "pyproject.toml", ".tool-versions"],
    "django": [".python-version", "pyproject.toml", ".tool-versions"],
    "ruby": [".ruby-version", "Gemfile", ".tool-versions"],
    "rails": [".ruby-version", "Gemfile", ".tool-versions"],
    "go": ["go.mod", ".tool-versions"],
    "rust": ["Cargo.toml", "rust-toolchain", "rust-toolchain.toml", ".tool-versions"],
    "postgres": [".tool-versions"],
    "redis": [".tool-versions"],
}
PATH_EXTS = (".md", ".ts", ".tsx", ".js", ".jsx", ".py", ".go", ".rs", ".rb", ".sh",
             ".json", ".yaml", ".yml", ".toml", ".txt", ".sql", ".css", ".html")
PM_BUILTINS = {"install", "i", "add", "remove", "rm", "dev", "build", "test", "lint",
               "start", "run", "exec", "dlx", "create", "init", "update", "up",
               "outdated", "audit", "publish", "pack", "link", "why", "list", "ls"}
HOOK_WORDS = ("test", "lint", "typecheck", "tsc", "format", "prettier", "biome",
              "eslint", "ruff", "pytest", "vitest", "jest", "cargo", "gitleaks", "build")
TOOL_PATTERNS = [
    ("prettier", (".prettierrc*", "prettier.config.*")),
    ("biome", ("biome.json", "biome.jsonc")),
    ("eslint", ("eslint.config.*", ".eslintrc*")),
    ("ruff", ("ruff.toml", ".ruff.toml")),
    ("rustfmt", ("rustfmt.toml", ".rustfmt.toml")),
    ("clippy", ("clippy.toml",)),
    ("golangci", (".golangci.yml", ".golangci.yaml")),
    ("editorconfig", (".editorconfig",)),
    ("shellcheck", (".shellcheckrc",)),
    ("markdownlint", (".markdownlint*",)),
]
TOOL_NAMES = ("prettier", "biome", "eslint", "ruff", "black", "rustfmt", "clippy",
              "gofmt", "golangci")
TOOL_ALIASES = {"gofmt": "golangci"}
TOOL_PRIORITY = ("prettier", "biome", "eslint", "ruff", "black", "rustfmt", "clippy",
                 "golangci", "editorconfig", "markdownlint", "shellcheck")

FENCE_RE = re.compile(r"^(```|~~~)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
FM_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$")
LIST_RE = re.compile(r"^\s*(?:[-*+]\s+|\d+[.)]\s+)+")
NUM_STEP_RE = re.compile(r"^\s*\d+[.)]\s+(.*)$")
BACKTICK_RE = re.compile(r"`([^`\n]+)`")
IMPORT_RE = re.compile(r"^\s*@([A-Za-z0-9._~/\-]+)\s*$")

# A heading that announces a reading list: every line under it is a spend
# instruction until it proves otherwise.
REDIRECT_SECTIONS = ("where to look", "read", "reading", "reference", "references",
                     "documentation", "docs", "pointer", "pointers", "links",
                     "resources", "further", "context files", "before you start",
                     "onboarding", "orientation")
READ_VERB_RE = re.compile(
    r"\b(read|re-?read|open|see|consult|refer|review|study|start with|"
    r"look (?:at|in|up)|load|check|browse|scan|inspect)\b", re.I)
# Two destinations, or an order over them, is a chain: the model pays for every
# hop it takes and for guessing which hop it was allowed to skip.
ORDER_RE = re.compile(
    r"\b(then|first|in (?:that|this) order|override[sd]?|precedence|afterwards|"
    r"followed by|beside it)\b", re.I)
# A line about how the context system loads rather than about the repo's work.
META_RE = re.compile(
    r"\b(override[sd]?|precedence|wins over|second copy|one-line pointer|"
    r"not a copy|shared core|delta|nearest|concatenat|loads? (?:first|last)|"
    r"in (?:that|this) order)\b", re.I)
# A trigger no model can decide from the task it was handed: it reads every
# time, at full price, or never, which is the same as no line at all.
VAGUE_TRIGGER_RE = re.compile(
    r"\b(before guessing|when in doubt|if in doubt|if needed|if necessary|"
    r"as needed|as appropriate|where relevant|when unsure|if unsure|"
    r"for (?:more|further|details|context|background|the full)|"
    r"before any work|before starting|to understand|familiaris|familiariz)\b", re.I)
# A trigger that names the moment. Paired with one destination, this is the map
# entry a pointer is allowed to be.
BOUND_TRIGGER_RE = re.compile(
    r"(\u2192|->|\b(when|before|after|while|only if|if you|whenever|editing|"
    r"changing|touching|adding)\b)", re.I)
# A path written in prose, outside a code span: a pointer does not stop costing
# because nobody wrapped it in backticks.
BARE_PATH_RE = re.compile(
    r"(?<![\w/.-])((?:[A-Za-z0-9._-]+/)+[A-Za-z0-9._-]+\.[A-Za-z0-9]+"
    r"|[A-Za-z0-9._-]+\.(?:md|mdx|txt|rst))")
PROSE_EXTS = (".md", ".mdx", ".txt", ".rst")

DERIVABLE_SECTIONS = ("structure", "layout", "directory", "directories", "architecture",
                      "tech stack", "stack", "dependencies", "overview", "project tree",
                      "folders", "modules")
# A `Never` under `## Architecture` is a rule that happens to live there, and
# deleting the section would delete the rule with it.
SECTION_RULE_RE = re.compile(r"\b(never|always|ask before|do not|don't|must)\b", re.I)
TREE_CHARS = ("├──", "└──", "│")
DEP_PIN_RE = re.compile(
    r"\b(node|python|ruby|go|rust|typescript|react|next|nextjs|vue|django|rails|"
    r"postgres|redis)\b\s*v?\d+(\.\d+)*", re.I)
STYLE_RE = re.compile(
    r"\b(indent|indentation|tabs?|spaces|semicolons?|trailing comma|single quotes|"
    r"double quotes|quote style|line length|max line|line width|import order|"
    r"sort imports|unused (imports|variables)|camelCase|snake_case|PascalCase|"
    r"kebab-case|format(ting)? (with|using)|"
    r"run (prettier|biome|eslint|ruff|black|rustfmt|clippy|gofmt))\b", re.I)
TOOL_VERB_RE = re.compile(r"\b(use|run|follow|obey|respect|apply)\b", re.I)
MODAL_RE = re.compile(r"\b(always|never|before|after|must|every)\b", re.I)
# A modal governs the clause it sits in and no further: `Never edit X; run Y`
# forbids the edit and prescribes Y, and read as one sentence it turns the
# prescription into part of the prohibition.
CLAUSE_SPLIT_RE = re.compile(r";|\s+[\u2014\u2013]\s+|\s+-\s+|\.\s+|,\s+")
# A generated tree named with its regenerate command is what a root file is
# for: the ban and the escape hatch have to arrive together.
NEVER_EDIT_RE = re.compile(
    r"\b(never|do not|don't|dont)\s+(edit|touch|modify|hand-edit|change)\b", re.I)
GENERATED_RE = re.compile(r"generated|regenerate|codegen", re.I)
HOOK_MODAL_RE = re.compile(r"\b(always|never|must)\b", re.I)
HOOK_ACT_RE = re.compile(
    r"\b(run|commit|push|format|lint|test|typecheck|build|check|before|after)\b", re.I)
IMPERATIVE_RE = re.compile(
    r"^(run|open|edit|create|write|copy|delete|check|add|remove|commit|push|deploy|"
    r"build|install|update|generate|bump|tag|publish|release|merge|rebase|verify|"
    r"restart)\b", re.I)
RULE_IMPERATIVE_RE = re.compile(
    r"\b(use|never|always|run|ask|do not|don't|must|keep|prefer)\b", re.I)
CMD_ONLY_RE = re.compile(
    r"^(npm run|pnpm run|yarn run|bun run|npm|pnpm|yarn|bun|just|make)\s+"
    r"([A-Za-z0-9][A-Za-z0-9:._-]*)$")
RUNNER_RE = re.compile(
    r"\b(npm run|pnpm run|yarn run|bun run|pnpm|yarn|bun|just|make)\s+"
    r"([A-Za-z0-9][A-Za-z0-9:._-]*)")
NODE_REF_RE = re.compile(r"\bnode\s*v?(\d+)(?:\.\d+)*", re.I)
PY_REF_RE = re.compile(r"\bpython\s*v?(\d+)\.(\d+)", re.I)
PM_MARK_RE = re.compile(r"\b(never|do not|don't|dont|use|run|install with|prefer)\b")
PM_NAME_RE = re.compile(r"\b(npm|pnpm|yarn|bun)\b")
PM_NEGATIVE = {"never", "do not", "don't", "dont"}
NEG_OBJ_RE = re.compile(r"\b(?:never|do not|don't|dont)\s+(.+)")
POS_OBJ_RE = re.compile(r"\b(?:always|use|run)\s+(.+)")
LIMIT_RE = re.compile(
    r"\b(?:max|maximum|under|at most|cap|limit)\b[^0-9\n]{0,40}(\d+)\s*"
    r"(lines|chars|characters|columns|bytes|tokens)\b", re.I)
WRAP_RE = re.compile(r"\b(?:wrap at|line length)\s*(?:of\s+)?(\d+)", re.I)
JUST_RECIPE_RE = re.compile(r"^([@_A-Za-z][A-Za-z0-9_-]*)(?: [^:]*)?:")
MAKE_TARGET_RE = re.compile(r"^([A-Za-z0-9_.-]+):")

# One pathological repo (fifty files repeating one rule) would otherwise pair
# every copy with every other and bury the report.
PAIR_CAP = 10


def estimate_tokens(text):
    # Four characters per token is the English-prose average for the GPT and
    # Claude tokenizer families; path- and code-heavy markdown runs denser, so
    # the figure reads slightly high there. It sizes a budget and is not a
    # tokenizer. intake.sh uses the same basis on bytes.
    return int(math.ceil(len(text) / 4.0))


def read_text(path):
    """File text with CR stripped, or None when it cannot be read."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read().replace("\r", "")
    except OSError:
        return None


def load_json(path):
    text = read_text(path)
    if text is None:
        return None
    try:
        return json.loads(text)
    except ValueError:
        return None


def flatten_strings(obj):
    if isinstance(obj, str):
        return [obj]
    out = []
    if isinstance(obj, dict):
        for value in obj.values():
            out.extend(flatten_strings(value))
    elif isinstance(obj, list):
        for value in obj:
            out.extend(flatten_strings(value))
    return out


def normalise(text):
    """One line reduced to what two files would have to share to be one line."""
    line = LIST_RE.sub("", text.strip(), count=1).lower()
    line = line.replace("`", "")
    line = re.sub(r"\s+", " ", line).strip()
    return line.strip(" .,;:!?-*")


def finding(lineno, text, reason, kind=None):
    out = {"line": lineno, "text": text.strip()[:120], "reason": reason}
    if kind:
        out["kind"] = kind
    return out


class Doc(object):
    """A parsed context file: its lines, its frontmatter and its instruction lines."""

    def __init__(self, text):
        self.text = text
        lines = text.split("\n")
        if lines and lines[-1] == "":
            lines.pop()
        self.lines = lines
        self.frontmatter = {}
        self.body_start = 0
        if lines and lines[0].strip() == "---":
            for i in range(1, len(lines)):
                if lines[i].strip() == "---":
                    self.body_start = i + 1
                    for entry in lines[1:i]:
                        match = FM_KEY_RE.match(entry.strip())
                        if match:
                            self.frontmatter[match.group(1).lower()] = match.group(2).strip()
                    break
        self.instruction = []
        self.headings = []
        in_fence = False
        in_comment = False
        for idx in range(self.body_start, len(lines)):
            raw = lines[idx]
            stripped = raw.strip()
            if FENCE_RE.match(stripped):
                in_fence = not in_fence
                continue
            if in_fence or not stripped:
                continue
            if in_comment:
                in_comment = "-->" not in stripped
                continue
            if stripped.startswith("<!--"):
                in_comment = "-->" not in stripped
                continue
            if stripped.startswith("#"):
                match = HEADING_RE.match(stripped)
                if match:
                    self.headings.append((idx + 1, len(match.group(1)), match.group(2).strip()))
                continue
            self.instruction.append((idx + 1, raw))
        self.heading_text, self.heading_line = self._heading_context()

    def _heading_context(self):
        """Nearest preceding heading of level 2 or deeper, for every line.

        An H1 is the document title and not a section, so it never scopes a
        line: a file titled `# Architecture` would otherwise read as derivable
        from its first line to its last.
        """
        total = len(self.lines)
        text = [""] * (total + 2)
        line = [0] * (total + 2)
        by_line = dict((ln, (lvl, txt)) for ln, lvl, txt in self.headings)
        cur_text, cur_line = "", 0
        for ln in range(1, total + 1):
            if ln in by_line:
                level, txt = by_line[ln]
                cur_text, cur_line = (txt, ln) if level >= 2 else ("", 0)
            text[ln] = cur_text
            line[ln] = cur_line
        return text, line

    def body_lines(self):
        return self.lines[self.body_start:]

    def pointer_target(self):
        body = [ln.strip() for ln in self.body_lines() if ln.strip()]
        if len(body) == 1 and body[0].startswith("@") and " " not in body[0]:
            return body[0][1:]
        return None

    def digest(self):
        return "\n".join(n for n in (normalise(ln) for ln in self.body_lines()) if n)


class Repo(object):
    """Everything about the repo that makes a line in prose unnecessary."""

    def __init__(self, root):
        self.root = Path(root)
        self.pkg = load_json(self.root / "package.json")
        self.pyproject = read_text(self.root / "pyproject.toml") or ""
        self.manifests = [m for m in MANIFESTS if (self.root / m).exists()]
        self.scripts = set()
        if isinstance(self.pkg, dict) and isinstance(self.pkg.get("scripts"), dict):
            self.scripts = set(self.pkg["scripts"].keys())
        self.just_src, self.recipes = self._just()
        self.make_src, self.targets = self._make()
        self.tools = self._tools()
        self.hooks = self._hooks()
        self.node_pin = self._node_pin()
        self.python_pin = self._python_pin()
        self._dest_cache = {}

    def _first_file(self, *names):
        for name in names:
            if (self.root / name).is_file():
                return name
        return None

    def _just(self):
        src = self._first_file("justfile", "Justfile", ".justfile")
        names = set()
        if src:
            for line in (read_text(self.root / src) or "").split("\n"):
                match = JUST_RECIPE_RE.match(line)
                if match:
                    names.add(match.group(1).lstrip("@"))
        return src, names

    def _make(self):
        src = self._first_file("Makefile", "makefile", "GNUmakefile")
        names = set()
        if src:
            for line in (read_text(self.root / src) or "").split("\n"):
                if line.startswith("\t"):
                    continue
                match = MAKE_TARGET_RE.match(line)
                if match and match.group(1) != ".PHONY":
                    names.add(match.group(1))
        return src, names

    def _tools(self):
        found = {}
        for tool, patterns in TOOL_PATTERNS:
            for pattern in patterns:
                hits = sorted(p.name for p in self.root.glob(pattern) if p.is_file())
                if hits:
                    found[tool] = hits[0]
                    break
        if "prettier" not in found and isinstance(self.pkg, dict) and "prettier" in self.pkg:
            found["prettier"] = "package.json"
        if "ruff" not in found and "[tool.ruff]" in self.pyproject:
            found["ruff"] = "pyproject.toml"
        if "[tool.black]" in self.pyproject:
            found["black"] = "pyproject.toml"
        return found

    def _hooks(self):
        """Every command a hook already runs, as (config path, command)."""
        out = []
        for rel in (".claude/settings.json", ".claude/settings.local.json"):
            data = load_json(self.root / rel)
            events = data.get("hooks") if isinstance(data, dict) else None
            if not isinstance(events, dict):
                continue
            for _, entries in sorted(events.items()):
                for entry in entries if isinstance(entries, list) else []:
                    inner = entry.get("hooks") if isinstance(entry, dict) else None
                    for hook in inner if isinstance(inner, list) else []:
                        command = hook.get("command") if isinstance(hook, dict) else None
                        if isinstance(command, str):
                            out.append((rel, command))
        for rel in (".husky", ".githooks"):
            directory = self.root / rel
            if not directory.is_dir():
                continue
            for path in sorted(p for p in directory.iterdir() if p.is_file()):
                text = read_text(path)
                if text:
                    out.append((rel + "/" + path.name, text))
        pre_commit = read_text(self.root / ".pre-commit-config.yaml")
        for line in (pre_commit or "").split("\n"):
            match = re.match(r"^\s*-?\s*(?:id|entry):\s*(.+)$", line)
            if match:
                out.append((".pre-commit-config.yaml", match.group(1).strip().strip("'\"")))
        for rel in ("lefthook.yml", "lefthook.yaml"):
            for line in (read_text(self.root / rel) or "").split("\n"):
                match = re.match(r"^\s*run:\s*(.+)$", line)
                if match:
                    out.append((rel, match.group(1).strip().strip("'\"")))
        for path in sorted(list(self.root.glob(".lintstagedrc*"))
                           + list(self.root.glob("lint-staged.config.*"))):
            text = read_text(path)
            if text:
                out.append((path.name, text))
        if isinstance(self.pkg, dict) and isinstance(self.pkg.get("lint-staged"), (dict, list)):
            for command in flatten_strings(self.pkg["lint-staged"]):
                out.append(("package.json", command))
        return out

    def _node_pin(self):
        for rel in (".nvmrc", ".node-version"):
            text = (read_text(self.root / rel) or "").strip().split("\n")[0].strip()
            match = re.search(r"(\d+)", text.lstrip("v")) if text else None
            if match:
                return (text, int(match.group(1)), rel)
        for line in (read_text(self.root / ".tool-versions") or "").split("\n"):
            match = re.match(r"^(?:nodejs|node)\s+v?(\d+)", line.strip())
            if match:
                return (line.strip().split()[-1], int(match.group(1)), ".tool-versions")
        engines = self.pkg.get("engines") if isinstance(self.pkg, dict) else None
        node = engines.get("node") if isinstance(engines, dict) else None
        match = re.search(r"(\d+)", node) if isinstance(node, str) else None
        if match:
            return (node, int(match.group(1)), "package.json")
        return None

    def _python_pin(self):
        text = (read_text(self.root / ".python-version") or "").strip().split("\n")[0]
        match = re.search(r"(\d+)\.(\d+)", text)
        if match:
            return (text.strip(), match.group(0), ".python-version")
        for line in (read_text(self.root / ".tool-versions") or "").split("\n"):
            match = re.match(r"^python\s+(\d+)\.(\d+)", line.strip())
            if match:
                return (line.strip().split()[-1], match.group(0).split(None, 1)[-1],
                        ".tool-versions")
        match = re.search(r"requires-python\s*=\s*['\"][^'\"]*?(\d+)\.(\d+)", self.pyproject)
        if match:
            return (match.group(0).split("=", 1)[-1].strip(" '\""),
                    "%s.%s" % (match.group(1), match.group(2)), "pyproject.toml")
        return None

    def is_dir(self, rel):
        if not rel or rel.startswith(("/", "~", "..")):
            return False
        return (self.root / rel).is_dir()

    def resolves(self, target, from_dir):
        if target.startswith(".."):
            return True
        if (self.root / target).exists():
            return True
        return bool(from_dir) and (self.root / from_dir / target).exists()

    def import_path(self, target, from_dir):
        return self.root / from_dir / Path(target).expanduser()

    def dest_info(self, target, from_dir):
        """What the agent pays, and what it gets, when it fills one pointer."""
        key = (target, from_dir)
        if key in self._dest_cache:
            return self._dest_cache[key]
        base = None
        for candidate in [self.root / target,
                          (self.root / from_dir / target) if from_dir else None]:
            if candidate is not None and candidate.exists():
                base = candidate
                break
        info = {"path": target, "exists": False, "tokens": 0,
                "prose": False, "context": False, "skill": False}
        if base is not None:
            rel = os.path.relpath(str(base), str(self.root)).replace(os.sep, "/")
            name = os.path.basename(rel.rstrip("/"))
            total = 0
            if base.is_dir():
                seen = 0
                for path in sorted(base.rglob("*.md")):
                    if any(part in PRUNE for part in path.parts):
                        continue
                    total += estimate_tokens(read_text(path) or "")
                    seen += 1
                    if seen >= DEST_FILE_CAP:
                        break
            else:
                total = estimate_tokens(read_text(base) or "")
            info = {"path": rel, "exists": True, "tokens": total,
                    "prose": base.is_file() and rel.endswith(PROSE_EXTS),
                    "context": is_context_path(rel, name),
                    "skill": name == "SKILL.md"}
        self._dest_cache[key] = info
        return info

    def skill_listed(self, rel):
        """A skill Claude Code already advertises: its trigger is in the prompt.

        Only the listing this script can prove counts. A tree Claude Code never
        scans leaves the pointer earning its place, so the finding stays quiet.
        """
        parts = rel.split("/")
        if len(parts) < 2 or parts[-1] != "SKILL.md":
            return False
        doc = Doc(read_text(self.root / rel) or "")
        if doc.frontmatter.get("disable-model-invocation", "").lower() == "true":
            return False
        if parts[:2] == [".claude", "skills"]:
            return True
        return (self.root / ".claude" / "skills" / parts[-2]).exists()

    def pin_source(self, word):
        for name in PIN_SOURCES.get(word, []):
            if name in self.manifests:
                return name
        return None

    def script_source(self, runner, name):
        base = runner.split()[0]
        if base in ("npm", "pnpm", "yarn", "bun") and name in self.scripts:
            return "package.json"
        if base == "just" and name in self.recipes:
            return self.just_src
        if base == "make" and name in self.targets:
            return self.make_src
        return None

    def unknown_script(self, runner, name):
        parts = runner.split()
        base, explicit = parts[0], len(parts) > 1
        if base in ("npm", "pnpm", "yarn", "bun"):
            if self.pkg is None or name in self.scripts:
                return None
            if not explicit and name in PM_BUILTINS:
                return None
            return "%s has no script %s" % (base, name)
        if base == "just":
            if not self.just_src or name in self.recipes:
                return None
            return "just has no script %s" % name
        if base == "make":
            if not self.make_src or name in self.targets:
                return None
            return "make has no script %s" % name
        return None

    def style_owner(self, raw):
        if not self.tools:
            return None
        low = raw.lower()
        if TOOL_VERB_RE.search(raw):
            for name in TOOL_NAMES:
                key = TOOL_ALIASES.get(name, name)
                if key in self.tools and re.search(r"\b%s\b" % name, low):
                    return (name, self.tools[key])
        if STYLE_RE.search(raw):
            for key in TOOL_PRIORITY:
                if key in self.tools:
                    return (key, self.tools[key])
        return None

    def hook_owner(self, low):
        for path, command in self.hooks:
            lowered = command.lower()
            for word in HOOK_WORDS:
                if word in lowered and re.search(r"\b%s\b" % word, low):
                    return (path, word)
        return None

    def hook_runs(self, word):
        return any(word in command.lower() for _, command in self.hooks)


def clauses(text):
    """One line cut into the clauses a modal can govern, list marker dropped."""
    body = LIST_RE.sub("", text.strip(), count=1)
    return [part.strip() for part in CLAUSE_SPLIT_RE.split(body) if part.strip()]


def command_only(raw):
    """A line whose whole content is a runner invocation, label aside.

    `Test: pnpm test` carries nothing the manifest does not; a sentence with a
    constraint around the same command does, so only a short label may precede.
    """
    text = LIST_RE.sub("", raw.strip(), count=1).strip().rstrip(".;,")
    candidates = [text]
    for sep in (":", " — ", " – ", " - "):
        if sep in text:
            head, rest = text.split(sep, 1)
            if len(head.split()) <= 4:
                candidates.append(rest.strip())
    for candidate in candidates:
        match = CMD_ONLY_RE.match(candidate.strip().strip("`").strip().rstrip(".;,"))
        if match:
            return match.group(1), match.group(2)
    return None


def path_like(span):
    """A backtick span read as a repo-relative path, or None."""
    text = span.strip()
    if not text or " " in text or any(ch in text for ch in "<>*{}$"):
        return None
    if text.startswith(("http", "@", "-", "~", "/")):
        return None
    text = text.split("#", 1)[0]
    if text.startswith("./"):
        text = text[2:]
    if not text:
        return None
    if "/" not in text:
        # `.env` and `.prettierrc` name a file kind, not a place in the tree,
        # and a bare `.md` names nothing at all.
        if text.startswith("."):
            return None
        if not text.endswith(PATH_EXTS):
            return None
    return text


def prose_only(raw):
    """The line with its code spans blanked, so `just check` is not a read verb."""
    return BACKTICK_RE.sub(" ", raw)


def destinations(raw):
    """Every repo path a line sends the agent to, in order, deduplicated."""
    out = []
    seen = set()
    for span in BACKTICK_RE.findall(raw):
        target = path_like(span)
        if target and target not in seen:
            seen.add(target)
            out.append(target)
    for match in BARE_PATH_RE.finditer(prose_only(raw)):
        target = path_like(match.group(1))
        if target and target not in seen:
            seen.add(target)
            out.append(target)
    return out


def redirect_kind(repo, prose, targets, infos, relpath=""):
    """Which way one pointer wastes context, or None when it earns its line."""
    cost = sum(i["tokens"] for i in infos if i["exists"])
    note = "~%d tokens per hit" % cost
    if all(not i["exists"] for i in infos):
        # A destination that resolves to nothing is stale, and stale owns it.
        return None
    # A sentence that names AGENTS.md is not the import Claude Code expands.
    if os.path.basename(relpath) in ("CLAUDE.md", "Claude.md"):
        names = [os.path.basename(t.rstrip("/")) for t in targets]
        names += [os.path.basename(i["path"].rstrip("/")) for i in infos]
        if "AGENTS.md" in names:
            return ("prose-import",
                    "prose-read is not an @import; Claude Code does not load the file")
    if META_RE.search(prose) and all(i["context"] for i in infos):
        return ("meta", "narrates the context system; no task turns on it")
    if len(targets) > 1 or ORDER_RE.search(prose):
        return ("chain", "%d destinations in one line — %s" % (len(targets), note))
    info = infos[0]
    if info["skill"] and repo.skill_listed(info["path"]):
        return ("listed", "the host already lists this skill; this repeats its trigger")
    if (info["prose"] and not info["context"] and not info["skill"]
            and info["tokens"] <= INLINE_TOKENS):
        return ("inline", "%s carries ~%d tokens — carry the fact, drop the hop"
                % (info["path"], info["tokens"]))
    if VAGUE_TRIGGER_RE.search(prose) or not BOUND_TRIGGER_RE.search(prose):
        return ("unbounded", "no trigger a model can decide — %s" % note)
    return None


def score_redirect(repo, doc, relpath):
    """Lines that spend context by reference instead of carrying a fact.

    Returns the findings, every distinct destination, the destinations of
    the lines that failed, and the prose-read edges for the map.
    """
    out = []
    dests = {}
    hot = {}
    edges = []
    from_dir = os.path.dirname(relpath)
    for lineno, raw in doc.instruction:
        heading = doc.heading_text[lineno].lower()
        prose = prose_only(raw)
        targets = destinations(raw)
        if not targets:
            continue
        if not (any(key in heading for key in REDIRECT_SECTIONS)
                or READ_VERB_RE.search(prose)):
            continue
        infos = [repo.dest_info(target, from_dir) for target in targets]
        for info in infos:
            if info["exists"]:
                dests[info["path"]] = info["tokens"]
                edges.append({"from": relpath, "to": info["path"],
                              "kind": "prose-read", "line": lineno})
        verdict = redirect_kind(repo, prose, targets, infos, relpath)
        if verdict:
            out.append(finding(lineno, raw, verdict[1], verdict[0]))
            for info in infos:
                if info["exists"]:
                    hot[info["path"]] = info["tokens"]
    return out, dests, hot, edges


def budget_findings(entry):
    """The two costs a per-line reading never reaches."""
    out = []
    cap = ROOT_POINTER_CAP if entry["root"] else ANY_POINTER_CAP
    if entry["pointer_count"] > cap:
        out.append(finding(
            1, entry["path"],
            "%d destinations, over the %d cap — a reading list, not a rule set"
            % (entry["pointer_count"], cap), "budget"))
    if entry["amplification"] > AMPLIFY_RATIO:
        out.append(finding(
            1, entry["path"],
            "~%d tokens of reading it gives no way to skip, against ~%d of its "
            "own (%dx)" % (entry["unbounded_tokens"], entry["tokens"],
                           entry["amplification"]), "budget"))
    return out


def score_derivable(repo, doc):
    out = []
    for lineno, raw in doc.instruction:
        reason = derivable_reason(repo, raw, doc.heading_text[lineno])
        if reason:
            out.append(finding(lineno, raw, reason))
    return out


def derivable_reason(repo, raw, heading):
    stripped = raw.strip()
    low = heading.lower()
    if any(key in low for key in DERIVABLE_SECTIONS):
        if not SECTION_RULE_RE.search(stripped):
            return "section %s — the tree or manifest answers this" % heading
    if any(ch in stripped for ch in TREE_CHARS):
        return "directory tour"
    if LIST_RE.match(raw):
        item = LIST_RE.sub("", raw.strip(), count=1).strip()
        token = item.split()[0].strip("`*_") if item.split() else ""
        if token.endswith("/") and repo.is_dir(token.rstrip("/")):
            return "directory tour"
    match = DEP_PIN_RE.search(stripped)
    if match:
        source = repo.pin_source(match.group(1).lower())
        if source:
            return "pinned in %s" % source
    command = command_only(raw)
    if command:
        source = repo.script_source(command[0], command[1])
        if source:
            return "listed in %s" % source
    return None


def score_enforced(repo, doc):
    out = []
    for lineno, raw in doc.instruction:
        owner = repo.style_owner(raw)
        if owner:
            out.append(finding(lineno, raw, "owned by %s (%s)" % owner))
            continue
        if MODAL_RE.search(raw):
            hook = repo.hook_owner(raw.lower())
            if hook:
                out.append(finding(lineno, raw, "hook %s runs %s" % hook))
    return out


def score_stale(repo, doc, relpath):
    """References that resolve to nothing: a path, a script, a pin, an import."""
    out = []
    from_dir = os.path.dirname(relpath)
    for lineno, raw in doc.instruction:
        reason = None
        for span in BACKTICK_RE.findall(raw):
            target = path_like(span)
            if target and not repo.resolves(target, from_dir):
                reason = "path does not exist"
                break
        if reason is None:
            for match in RUNNER_RE.finditer(raw):
                reason = repo.unknown_script(match.group(1), match.group(2))
                if reason:
                    break
        if reason is None:
            reason = pin_conflict(repo, raw)
        if reason is None:
            match = IMPORT_RE.match(raw)
            if match:
                if not repo.import_path(match.group(1), from_dir).is_file():
                    reason = "import target missing"
        if reason:
            out.append(finding(lineno, raw, reason))
    return out


def pin_conflict(repo, raw):
    match = NODE_REF_RE.search(raw)
    if match and repo.node_pin and int(match.group(1)) != repo.node_pin[1]:
        return "repo pins %s (%s)" % (repo.node_pin[0], repo.node_pin[2])
    match = PY_REF_RE.search(raw)
    if match and repo.python_pin:
        said = "%s.%s" % (match.group(1), match.group(2))
        if said != repo.python_pin[1]:
            return "repo pins %s (%s)" % (repo.python_pin[0], repo.python_pin[2])
    return None


def score_misplaced(repo, doc, relpath, is_root):
    """Lines that belong in a hook, a skill or a path-scoped rule instead."""
    out = []
    file_level = rule_file_finding(relpath, doc)
    if file_level:
        out.append(file_level)
    for lineno, raw in doc.instruction:
        hit = None
        for clause in clauses(raw):
            # A hook is prescribed only where the modal governs the command:
            # the `run` clause after a never-edit ban is the escape hatch, not
            # an always.
            if not (HOOK_MODAL_RE.search(clause) and HOOK_ACT_RE.search(clause)):
                continue
            if NEVER_EDIT_RE.match(clause):
                continue
            low = clause.lower()
            for word in HOOK_WORDS:
                if re.search(r"\b%s\b" % word, low) and not repo.hook_runs(word):
                    hit = finding(lineno, raw, "an always is a hook, not prose", "hook")
                    break
            if hit:
                break
        if hit is None and is_root:
            head = doc.heading_text[lineno].lower()
            if "where to look" not in head and "pointers" not in head:
                hit = subtree_rule(repo, lineno, raw)
        if hit:
            out.append(hit)
    out.extend(procedures(doc))
    out.sort(key=lambda f: f["line"])
    return out


def subtree_rule(repo, lineno, raw):
    if not RULE_IMPERATIVE_RE.search(raw):
        return None
    if NEVER_EDIT_RE.search(raw) or GENERATED_RE.search(raw):
        return None
    for span in BACKTICK_RE.findall(raw):
        target = span.strip().rstrip("/")
        if not target or target.startswith((".", "/", "~")) or " " in target:
            continue
        if repo.is_dir(target):
            return finding(
                lineno, raw,
                "about %s/ — a path-scoped rule or a nested AGENTS.md" % target, "rule")
    return None


def rule_file_finding(relpath, doc):
    """A rule file with no scope is loaded in every session, like the root file."""
    parts = relpath.split("/")
    pairs = set((parts[i], parts[i + 1]) for i in range(len(parts) - 2))
    # The finding is about the file, so the frontmatter fence on line 1 says
    # nothing; the first line of the body is what the reader has to place.
    text = next((raw for _, raw in doc.instruction), relpath)
    reason = "always-on rule file — scope it with paths/globs or fold into the root"
    if relpath.endswith(".md") and pairs & {(".claude", "rules")}:
        if "paths" not in doc.frontmatter:
            return finding(1, text, reason, "rule")
    if relpath.endswith(".mdc") and pairs & {(".cursor", "rules")}:
        if doc.frontmatter.get("alwaysapply", "").lower() == "true":
            return finding(1, text, reason, "rule")
    return None


def procedures(doc):
    """A long numbered run is a skill or a command, not a line of the handbook."""
    out = []
    run = []
    anchor = 0
    for lineno, raw in doc.instruction:
        step = NUM_STEP_RE.match(raw)
        if step:
            head = doc.heading_line[lineno]
            if run and head != anchor:
                out.extend(flush_procedure(doc, run, anchor))
                run = []
            anchor = head
            run.append((lineno, step.group(1).strip()))
        elif run and raw.startswith("  "):
            continue
        elif run:
            out.extend(flush_procedure(doc, run, anchor))
            run = []
    out.extend(flush_procedure(doc, run, anchor))
    return out


def flush_procedure(doc, run, anchor):
    if len(run) < 5:
        return []
    if sum(1 for _, text in run if IMPERATIVE_RE.match(text)) < 3:
        return []
    line = anchor if anchor else run[0][0]
    text = doc.lines[line - 1] if 0 < line <= len(doc.lines) else run[0][1]
    reason = "%d-step procedure — a skill or a command, loaded on demand" % len(run)
    return [finding(line, text, reason, "skill")]


def cross_file_duplicates(docs):
    """A line or a whole body that a second file already carries."""
    by_line = {}
    by_digest = {}
    for relpath, doc in docs:
        for lineno, raw in doc.instruction:
            key = normalise(raw)
            if len(key.split()) >= 4:
                by_line.setdefault(key, []).append(relpath)
        digest = doc.digest()
        if digest:
            by_digest.setdefault(digest, []).append(relpath)
    out = {}
    counts = {}
    for relpath, doc in docs:
        found = []
        lines = 0
        for lineno, raw in doc.instruction:
            key = normalise(raw)
            others = sorted(set(p for p in by_line.get(key, []) if p != relpath))
            if len(key.split()) >= 4 and others:
                found.append(finding(lineno, raw, "also in %s" % ", ".join(others[:3])))
                lines += 1
        others = sorted(set(p for p in by_digest.get(doc.digest(), []) if p != relpath))
        if others:
            first = next((ln for ln, _ in doc.instruction), 1)
            text = next((raw for _, raw in doc.instruction), relpath)
            found.append(finding(first, text, "same body as %s" % ", ".join(others[:3])))
        found.sort(key=lambda f: f["line"])
        out[relpath] = found
        counts[relpath] = lines
    return out, counts


def pm_stance(low):
    """Which package manager a line asserts and which it forbids."""
    positive, negative = set(), set()
    for clause in clauses(low):
        pos, neg = clause_stance(clause)
        positive |= pos
        negative |= neg
    return positive, negative


def clause_stance(low):
    """The stance of one clause.

    The nearest preceding modal wins, so `never npm, always pnpm` reads as one
    rule rather than as a contradiction with itself.
    """
    names = [m.start() for m in PM_NAME_RE.finditer(low)]
    marks = []
    for match in PM_MARK_RE.finditer(low):
        negated = match.group(1) in PM_NEGATIVE
        # `never use npm`: the verb carries the negation, so the verb alone must
        # not flip the stance back to an assertion.
        if not negated and marks and marks[-1][1]:
            if not any(marks[-1][0] < pos < match.start() for pos in names):
                continue
        marks.append((match.start(), negated))
    positive, negative = set(), set()
    for match in PM_NAME_RE.finditer(low):
        prior = [flag for start, flag in marks if start < match.start()]
        if prior:
            (negative if prior[-1] else positive).add(match.group(1))
    return positive, negative


def obj_key(rest):
    words = normalise(rest).split()[:3]
    # A one-word object (`never run`) collides on any two unrelated lines.
    return " ".join(words) if len(words) >= 2 else None


def contradictions(records):
    out = []
    seen = set()

    def add(rec_a, rec_b, reason):
        key = (rec_a[0], rec_a[1], rec_b[0], rec_b[1], reason)
        mirror = (rec_b[0], rec_b[1], rec_a[0], rec_a[1], reason)
        if key in seen or mirror in seen or (rec_a[0], rec_a[1]) == (rec_b[0], rec_b[1]):
            return
        seen.add(key)
        out.append({
            "a": {"path": rec_a[0], "line": rec_a[1], "text": rec_a[2].strip()[:120]},
            "b": {"path": rec_b[0], "line": rec_b[1], "text": rec_b[2].strip()[:120]},
            "reason": reason,
        })

    stances = []
    negatives, positives, limits = {}, {}, {}
    for rec in records:
        low = rec[2].lower()
        pos, neg = pm_stance(low)
        if pos or neg:
            stances.append((rec, pos, neg))
        for match in NEG_OBJ_RE.finditer(low):
            key = obj_key(match.group(1))
            if key:
                negatives.setdefault(key, []).append(rec)
        for match in POS_OBJ_RE.finditer(low):
            key = obj_key(match.group(1))
            if key:
                positives.setdefault(key, []).append(rec)
        for match in LIMIT_RE.finditer(rec[2]):
            unit = match.group(2).lower()
            unit = "chars" if unit.startswith("char") else unit
            limits.setdefault(unit, {}).setdefault(match.group(1), []).append(rec)
        for match in WRAP_RE.finditer(rec[2]):
            limits.setdefault("columns", {}).setdefault(match.group(1), []).append(rec)

    for i in range(len(stances)):
        rec_a, pos_a, neg_a = stances[i]
        for j in range(i + 1, len(stances)):
            rec_b, pos_b, neg_b = stances[j]
            if rec_a[0] == rec_b[0]:
                continue
            crossed = (pos_a & neg_b) or (pos_b & neg_a)
            rival = any(a != b and b not in neg_a and a not in neg_b
                        for a in pos_a for b in pos_b)
            if crossed or rival:
                add(rec_a, rec_b, "package manager")

    for key, negs in sorted(negatives.items()):
        pairs = 0
        for rec_a in negs:
            for rec_b in positives.get(key, []):
                if pairs >= PAIR_CAP:
                    break
                if (rec_a[0], rec_a[1]) != (rec_b[0], rec_b[1]):
                    add(rec_a, rec_b, 'opposite verb on "%s"' % key)
                    pairs += 1

    for unit, by_number in sorted(limits.items()):
        numbers = sorted(by_number)
        pairs = 0
        for i in range(len(numbers)):
            for j in range(i + 1, len(numbers)):
                for rec_a in by_number[numbers[i]][:2]:
                    for rec_b in by_number[numbers[j]][:2]:
                        if pairs >= PAIR_CAP:
                            break
                        add(rec_a, rec_b, "%s limit: %s vs %s" % (unit, numbers[i], numbers[j]))
                        pairs += 1
    out.sort(key=lambda c: (c["a"]["path"], c["a"]["line"], c["b"]["path"], c["b"]["line"]))
    return out


def diagnose(entry):
    states = []
    if entry["pointer"]:
        return ["stale"] if entry["stale"] else ["healthy"]
    over_root = entry["root"] and entry["lines"] > ROOT_LINE_CAP
    if over_root or entry["lines"] > ANY_LINE_CAP:
        states.append("bloated")
    total = entry["instruction_lines"]
    derivable = len(entry["derivable"])
    if derivable >= 3 or (total and derivable * 5 >= total):
        states.append("derivable")
    if entry["enforced"]:
        states.append("redundant")
    if entry["stale"]:
        states.append("stale")
    if entry["misplaced"]:
        states.append("misplaced")
    if entry["redirect"]:
        states.append("redirect")
    return states or ["healthy"]


def is_context_path(relpath, name):
    if name in CONTEXT_NAMES or relpath in SINGLE_PATHS:
        return True
    parts = relpath.split("/")
    if (len(parts) == 3 and parts[0] == ".github" and parts[1] == "instructions"
            and name.endswith(".instructions.md")):
        return True
    # A rules tree nests: the .claude/rules under packages/api is loaded the
    # same way the one at the root is.
    for i in range(len(parts) - 2):
        suffix = RULE_DIRS.get((parts[i], parts[i + 1]))
        if suffix and name.endswith(suffix):
            return True
    return False


def discover(root):
    found = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in PRUNE)
        rel_dir = os.path.relpath(dirpath, root)
        rel_dir = "" if rel_dir == "." else rel_dir.replace(os.sep, "/")
        for name in filenames:
            relpath = name if not rel_dir else rel_dir + "/" + name
            if is_context_path(relpath, name):
                found.append(relpath)
    return sorted(found)


def build_report(root):
    repo = Repo(root)
    entries = []
    parsed = []
    edges = []
    for relpath in discover(root):
        absolute = os.path.join(root, relpath)
        at_root = "/" not in relpath and relpath in ROOT_NAMES
        entry = {"path": relpath, "root": at_root, "pointer": False, "target": None,
                 "lines": 0, "tokens": 0, "instruction_lines": 0, "derivable": [],
                 "enforced": [], "duplicates": [], "stale": [], "misplaced": [],
                 "duplicate_lines": 0, "redirect": [], "pointer_count": 0,
                 "induced_tokens": 0, "unbounded_tokens": 0, "amplification": 0}
        # A symlink is described and never read: following it counts one body
        # twice, and a dangling one has no body to count at all.
        if os.path.islink(absolute):
            entry["pointer"] = "symlink"
            try:
                entry["target"] = os.readlink(absolute)
            except OSError:
                entry["target"] = ""
            if not os.path.isfile(absolute):
                entry["stale"].append(finding(
                    1, entry["target"], "symlink target missing or not a file"))
            entry["diagnosis"] = diagnose(entry)
            entries.append(entry)
            continue
        text = read_text(absolute)
        if text is None:
            continue
        doc = Doc(text)
        entry["lines"] = len(doc.lines)
        entry["tokens"] = estimate_tokens(text)
        target = doc.pointer_target()
        if target is not None:
            entry["pointer"] = "import"
            entry["target"] = target
            entry["lines"] = 0
            entry["tokens"] = 0
            from_dir = os.path.dirname(relpath)
            lineno = next(i + 1 for i, line in enumerate(doc.lines)
                          if line.strip() == "@" + target)
            if not repo.import_path(target, from_dir).is_file():
                entry["stale"].append(finding(
                    lineno, "@" + target, "import target missing or not a file"))
            entry["diagnosis"] = diagnose(entry)
            dest = os.path.relpath(repo.import_path(target, from_dir), repo.root)
            edges.append({"from": relpath, "to": dest, "kind": "import", "line": lineno})
            entries.append(entry)
            continue
        entry["instruction_lines"] = len(doc.instruction)
        entry["derivable"] = score_derivable(repo, doc)
        entry["enforced"] = score_enforced(repo, doc)
        entry["stale"] = score_stale(repo, doc, relpath)
        entry["misplaced"] = score_misplaced(repo, doc, relpath, entry["root"])
        entry["redirect"], dests, hot, file_edges = score_redirect(repo, doc, relpath)
        edges.extend(file_edges)
        entry["pointer_count"] = len(dests)
        entry["induced_tokens"] = sum(dests.values())
        entry["unbounded_tokens"] = sum(hot.values())
        entry["amplification"] = (entry["unbounded_tokens"] // entry["tokens"]
                                  if entry["tokens"] else 0)
        entry["redirect"] = budget_findings(entry) + entry["redirect"]
        entries.append(entry)
        parsed.append((relpath, doc))

    duplicates, counts = cross_file_duplicates(parsed)
    records = []
    for relpath, doc in parsed:
        for lineno, raw in doc.instruction:
            records.append((relpath, lineno, raw))
    # A prose-read or import pulls its destination into the contradiction set,
    # even when that destination is a doc and not a context file.
    loaded = set(p for p, _ in parsed)
    for edge in edges:
        path = edge["to"]
        if path in loaded:
            continue
        if not path.endswith(PROSE_EXTS):
            continue
        abs_dest = os.path.join(root, path)
        if not os.path.isfile(abs_dest):
            continue
        text = read_text(abs_dest)
        if text is None:
            continue
        extra = Doc(text)
        for lineno, raw in extra.instruction:
            records.append((path, lineno, raw))
        loaded.add(path)
    edges.sort(key=lambda e: (e["from"], e["line"], e["to"]))
    for entry in entries:
        if entry["path"] in duplicates:
            entry["duplicates"] = duplicates[entry["path"]]
            entry["duplicate_lines"] = counts[entry["path"]]
        if "diagnosis" not in entry:
            entry["diagnosis"] = diagnose(entry)

    pairs = contradictions(records)
    summary = {"files": len(entries), "contradictions": len(pairs),
               "healthy": sum(1 for e in entries if e["diagnosis"] == ["healthy"])}
    for state in ("bloated", "derivable", "redundant", "stale", "misplaced",
                  "redirect"):
        summary[state] = sum(1 for e in entries if state in e["diagnosis"])
    # Scoped files contribute to the inventory without loading on every task.
    # Actual prompt cost requires the active loader and task path.
    summary["context_tokens"] = sum(e["tokens"] for e in entries)
    summary["pointers"] = sum(e["pointer_count"] for e in entries)
    summary["induced_tokens"] = sum(e["induced_tokens"] for e in entries)
    summary["unbounded_tokens"] = sum(e["unbounded_tokens"] for e in entries)
    return {"root": root, "absent": not entries, "files": entries,
            "map": edges, "contradictions": pairs, "summary": summary}


def percent(count, total):
    return 0 if not total else int(round(100.0 * count / total))


def measures(entry):
    total = entry["instruction_lines"]
    return ("derivable %d%% (%d)  enforced %d%% (%d)  duplicate %d  stale %d  "
            "misplaced %d  pointers %d (~%d induced, ~%d undecidable, %dx)") % (
        percent(len(entry["derivable"]), total), len(entry["derivable"]),
        percent(len(entry["enforced"]), total), len(entry["enforced"]),
        entry["duplicate_lines"], len(entry["stale"]), len(entry["misplaced"]),
        entry["pointer_count"], entry["induced_tokens"],
        entry["unbounded_tokens"], entry["amplification"])


def render_findings(entry):
    rows = []
    for index, state in enumerate(STATES):
        key = "duplicates" if state == "duplicate" else state
        for item in entry[key]:
            rows.append((item["line"], index, state, item))
    rows.sort(key=lambda row: (row[0], row[1]))
    out = []
    shown = dict((state, 0) for state in STATES)
    for _, _, state, item in rows:
        shown[state] += 1
        if shown[state] > FINDING_CAP:
            continue
        label = state + ("/" + item["kind"] if item.get("kind") else "")
        out.append("  - L%d %s: %s  (%s)" % (item["line"], label, item["text"], item["reason"]))
    for state in STATES:
        if shown[state] > FINDING_CAP:
            out.append("  - … %d more %s" % (shown[state] - FINDING_CAP, state))
    return out


def render_text(report):
    out = ["# context-doctor vitals", "root: %s" % report["root"], "", "## files"]
    if report["absent"]:
        out.append("no context file; create one only for a concrete hazard; see references/prescriptions.md")
    for entry in report["files"]:
        if entry["pointer"] == "symlink":
            out.append("- %s  pointer (symlink -> %s)" % (entry["path"], entry["target"]))
        elif entry["pointer"]:
            out.append("- %s  pointer -> %s" % (entry["path"], entry["target"]))
        else:
            head = "- %s  %d lines  ~%d tokens" % (entry["path"], entry["lines"],
                                                   entry["tokens"])
            out.append(head + "  root" if entry["root"] else head)
        out.append("  diagnosis: %s" % ", ".join(entry["diagnosis"]))
        if not entry["pointer"]:
            out.append("  " + measures(entry))
        out.extend(render_findings(entry))
    out.extend(["", "## map"])
    if not report.get("map"):
        out.append("- none")
    for edge in report.get("map", []):
        out.append("- %s:%d  %s → %s" % (
            edge["from"], edge["line"], edge["kind"], edge["to"]))
    out.extend(["", "## contradictions"])
    if not report["contradictions"]:
        out.append("- none")
    for pair in report["contradictions"]:
        out.append('- %s:%d "%s" vs %s:%d "%s"  (%s)' % (
            pair["a"]["path"], pair["a"]["line"], pair["a"]["text"],
            pair["b"]["path"], pair["b"]["line"], pair["b"]["text"], pair["reason"]))
    summary = report["summary"]
    out.extend(["", "## budget",
                "~%d inventoried context tokens; %d pointers to ~%d induced tokens, "
                "~%d of them undecidable" % (
                    summary["context_tokens"], summary["pointers"],
                    summary["induced_tokens"], summary["unbounded_tokens"])])
    out.extend(["", "## summary",
                "%d files, %d healthy; bloated %d, derivable %d, redundant %d, "
                "stale %d, misplaced %d, redirect %d; contradictions %d" % (
                    summary["files"], summary["healthy"], summary["bloated"],
                    summary["derivable"], summary["redundant"], summary["stale"],
                    summary["misplaced"], summary["redirect"],
                    summary["contradictions"])])
    return "\n".join(out)


def main(argv=None):
    parser = argparse.ArgumentParser(prog="vitals.py", usage=USAGE, add_help=True,
                                     description="Score the context files of a repo.")
    parser.add_argument("--json", action="store_true", dest="as_json")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("repo_root")
    args = parser.parse_args(argv)
    root = os.path.abspath(args.repo_root)
    if not os.path.isdir(root):
        parser.error("not a directory: %s" % args.repo_root)
    report = build_report(root)
    if args.as_json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(render_text(report))
    if args.strict:
        unhealthy = any(entry["diagnosis"] != ["healthy"] for entry in report["files"])
        if unhealthy or report["contradictions"]:
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
