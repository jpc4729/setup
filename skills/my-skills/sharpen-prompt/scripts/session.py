#!/usr/bin/env -S python3 -I
"""Find a Claude Code session, or print it in a compact form.

Reads ~/.claude and every ~/.claude-* home. Read-only, standard library only.
Claude Code calls the transcript format internal, so a record of an unknown
shape is skipped and counted, and a transcript with no message is an error.

Usage:
  session.py find [--skip ID] [WORD ...]   latest sessions that hold every word
  session.py read ID [--part N]            one part of the session
  session.py read ID --item N [--part N]   one clipped piece, whole
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

# Claude Code cuts a Bash output at 30,000 characters.
PART_CHARS = 25_000
FIND_ROWS = 15
TOOL_CLIP = 400
# What the user and the agents said, and why a call failed, is worth more than
# tool output.
LONG_CLIP = 4_000
LONG_TOOLS = {"Agent", "Task", "SendMessage", "AskUserQuestion", "ExitPlanMode"}
PATH_ONLY = {"Read", "Edit", "Write"}
USER_QUEUED = "USER (queued):"
NOTICE = "NOTICE:"
NOTICE_TEXT = ("<task-notification", "<local-command-", "<bash-stdout", "<bash-stderr")
PASTED = re.compile(r"(<pasted_content[^>]*>)(.*?)(</pasted_content>)", re.DOTALL)
# Common shapes only. The skill still tells the model to copy no secret.
SECRET = re.compile(
    r"(?<![A-Za-z0-9_-])(?:sk-(?=[A-Za-z_-]*[0-9])[A-Za-z0-9_-]{20,}"
    r"|gh[pousr]_[A-Za-z0-9]{30,}"
    r"|github_pat_[A-Za-z0-9_]{30,}"
    r"|xox[abprs]-[A-Za-z0-9-]{10,}"
    r"|AKIA[0-9A-Z]{16}"
    r"|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,})"
    r"|(?s:-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----)"
    r"|(?i:bearer)\s+[A-Za-z0-9._~+/=-]{16,}"
    r"|(?i:password|passwd|api[_-]?key|secret[_-]?key|access[_-]?token"
    r"|auth[_-]?token|client[_-]?secret)"
    r"[\"']?\s*[:=]\s*[\"']?[^\s\"',;]{8,}"
)
MASKED = "[secret masked]"
# Queued text shorter than this can match a user record by chance.
MIN_REPEAT = 20
# Checked on the raw line, so the large records are never parsed.
FIND_MARKS = (
    b'"type":"user"',
    b'"queued_command"',
    b'"type":"ai-title"',
    b'"type":"custom-title"',
)
READ_MARKS = (*FIND_MARKS, b'"type":"assistant"', b'"compact_boundary"')
TOOL_RESULT_MARK = b'"tool_use_id":'
BAD_SHAPE = (AttributeError, KeyError, TypeError)


def transcripts():
    """{id: copies}, newest session first, each ID's longest copy first.

    A session resumed with another account has a copy in each home, and the
    copies can differ. A copy is (size, mtime, path).
    """
    homes = set(Path.home().glob(".claude*"))
    if os.environ.get("CLAUDE_CONFIG_DIR"):
        homes.add(Path(os.environ["CLAUDE_CONFIG_DIR"]))
    copies = defaultdict(list)
    for home in homes:
        for path in home.glob("projects/*/*.jsonl"):
            if path.name.startswith("agent-"):
                continue
            try:
                stat = path.stat()
            except OSError:
                continue  # Deleted during the scan.
            copies[path.stem].append((stat.st_size, stat.st_mtime, path))
    for found in copies.values():
        found.sort(key=lambda copy: copy[:2], reverse=True)
    newest_first = sorted(
        copies.items(), key=lambda row: max(c[1] for c in row[1]), reverse=True
    )
    return dict(newest_first)


def load(path, marks, skip_tool_results=False):
    """Yield each parsed record whose raw line holds one of the marks."""
    with path.open("rb") as lines:
        for line in lines:
            if not any(mark in line for mark in marks):
                continue
            if skip_tool_results and TOOL_RESULT_MARK in line:
                continue
            try:
                record = json.loads(line.decode("utf-8", "replace"))
            except ValueError:
                continue  # A line that is still being written.
            if isinstance(record, dict) and not record.get("isSidechain"):
                yield record


def text_of(content):
    """The text of a string or of a list of content blocks."""
    if isinstance(content, str):
        return content
    parts = []
    for block in content if isinstance(content, list) else []:
        if not isinstance(block, dict):
            continue
        text = block.get("text")
        if isinstance(text, str) and text:
            parts.append(text)
        elif block.get("type") == "image":
            parts.append("[image]")
    return "\n".join(parts)


def blocks(record):
    message = record.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    if isinstance(content, list):
        return [block for block in content if isinstance(block, dict)]
    return []


def user_text(record):
    return text_of([block for block in blocks(record) if block.get("type") == "text"])


def is_conversation(record):
    """Whether a user record holds a message, not injected context."""
    return (
        record.get("type") == "user"
        and not record.get("isMeta")
        and not record.get("isCompactSummary")
    )


def is_typed(record):
    """Whether a user record holds a prompt that a person wrote."""
    if not is_conversation(record):
        return False
    text = user_text(record).lstrip()
    return bool(text) and not text.startswith(NOTICE_TEXT)


def queued(record):
    """(label, text) of a message that arrived while Claude was busy, else None.

    A prompt or an agent's final report may exist only in this record.
    """
    attachment = record.get("attachment")
    if (
        record.get("type") != "attachment"
        or not isinstance(attachment, dict)
        or attachment.get("type") != "queued_command"
    ):
        return None
    from_user = attachment.get("commandMode") == "prompt" and not attachment.get(
        "isMeta"
    )
    return (USER_QUEUED if from_user else NOTICE, text_of(attachment.get("prompt")))


def repeats(text, later):
    """Whether a later user record holds this queued text.

    A queued prompt reaches its user record after the queue, so an earlier
    match is a new prompt with the same words.
    """
    text = text.strip()
    return len(text) >= MIN_REPEAT and any(text[:200] in other for other in later)


def rewinds(records):
    """{start index: end index} of each branch that the user went back from.

    Two typed prompts with one parent, with a reply between them, are a rewind.
    Tool results also share parents, so only typed prompts count.
    """
    latest, spans = {}, {}
    replies = 0
    for index, record in enumerate(records):
        if record.get("type") == "assistant":
            replies += 1
        elif is_typed(record) and isinstance(record.get("parentUuid"), str):
            parent = record["parentUuid"]
            if parent in latest and latest[parent][1] < replies:
                spans[latest[parent][0]] = index
            latest[parent] = (index, replies)
    return spans


def gutter(text):
    """Mark each content line, so text cannot forge a label."""
    return "\n".join(f"| {line}" for line in text.splitlines() or [""])


def one_line(text):
    """A value for a header or a label: masked, and with no line break."""
    return " ".join(SECRET.sub(MASKED, str(text)).split())


def tilde(path):
    return str(path).replace(str(Path.home()), "~", 1)


def stamp(mtime):
    return datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")


def note_title(record, titles):
    custom, generated = record.get("customTitle"), record.get("aiTitle")
    if record.get("type") == "custom-title" and isinstance(custom, str):
        titles["custom"] = custom
    elif record.get("type") == "ai-title" and isinstance(generated, str):
        titles["ai"] = generated


def title_from(titles):
    return titles.get("custom") or titles.get("ai") or ""


def overview(path):
    """(title, prompts, words to search, folder) of a transcript."""
    titles, prompts, places, folder = {}, [], set(), ""
    for record in load(path, FIND_MARKS, skip_tool_results=True):
        try:
            note_title(record, titles)
            folder = record.get("cwd") or folder
            places.update(str(record.get(key) or "") for key in ("cwd", "gitBranch"))
            arrived = queued(record)
            if arrived and arrived[0] == USER_QUEUED and arrived[1]:
                prompts.append(arrived[1])
            elif is_typed(record):
                prompts.append(user_text(record))
        except BAD_SHAPE:
            continue
    return title_from(titles), prompts, places, folder


def find(words, skip):
    words = [word.lower() for word in words]
    shown = 0
    for session, copies in transcripts().items():
        if session == skip:
            continue
        path = copies[0][2]
        try:
            title, prompts, places, folder = overview(path)
        except OSError:
            continue  # Deleted or locked during the scan.
        if not prompts:
            continue
        haystack = "\n".join([session, title, *places, *prompts]).lower()
        if not all(word in haystack for word in words):
            continue
        date = stamp(max(copy[1] for copy in copies))
        label = one_line(title or prompts[0])[:80]
        home = tilde(path.parents[2])
        count = f"{len(prompts)} prompt{'' if len(prompts) == 1 else 's'}"
        print(f"{session}  {date}  {home}  {one_line(tilde(folder))}  {count}  {label}")
        shown += 1
        if shown == FIND_ROWS:
            print(f"(the latest {FIND_ROWS} matches; add words to narrow them)")
            return 0
    if not shown:
        print("no session matches", file=sys.stderr)
        return 1
    return 0


def locate(prefix):
    sessions = transcripts()
    hits = [session for session in sessions if session.startswith(prefix)]
    if not hits:
        sys.exit(f"no session has an ID that starts with {prefix}")
    if len(hits) > 1:
        sys.exit(
            f"{len(hits)} sessions match, give more of the ID:\n"
            + "\n".join(hits[:FIND_ROWS])
        )
    return hits[0], sessions[hits[0]]


def render(session, copies):
    """(the whole session in file order as text, the full text of each clip)."""
    path = copies[0][2]
    try:
        records = list(load(path, READ_MARKS))
    except OSError as error:
        sys.exit(f"cannot read {path}: {error}")
    typed = [
        (index, user_text(record))
        for index, record in enumerate(records)
        if is_conversation(record)
    ]
    rewound = rewinds(records)
    ends = set(rewound.values())
    body, items, names, titles = [], [], {}, {}
    folder = branch = ""
    prompts = messages = skipped = 0

    def clip(text, limit):
        """Keep the head and the tail: what ran, and how it ended."""
        if len(text) <= limit:
            return text
        items.append(text)
        half = limit // 2
        gone = len(text) - 2 * half
        mark = f"[... {gone} characters clipped, whole text: --item {len(items)} ...]"
        return f"{text[:half]}\n{mark}\n{text[-half:]}"

    def add(label, text, limit=0):
        """Add one turn."""
        text = SECRET.sub(MASKED, text)
        if limit:
            text = clip(text, limit)
        body.append(f"{label}\n{gutter(text)}")

    def add_prompt(label, text):
        nonlocal prompts
        prompts += 1
        text = SECRET.sub(MASKED, text)
        add(label, PASTED.sub(lambda m: m[1] + clip(m[2], LONG_CLIP) + m[3], text))

    def add_call(block):
        name, args = block.get("name") or "?", block.get("input") or {}
        names[block.get("id")] = name
        as_json = json.dumps(args, ensure_ascii=False)
        if name in PATH_ONLY and "file_path" in args:
            note = ""
            if name != "Read":
                items.append(SECRET.sub(MASKED, as_json))
                note = f"\n[body not shown, whole text: --item {len(items)}]"
            add(f"TOOL {one_line(name)}:", args["file_path"] + note)
        elif name == "Bash" and "command" in args:
            add("TOOL Bash:", args["command"], TOOL_CLIP)
        else:
            limit = LONG_CLIP if name in LONG_TOOLS else TOOL_CLIP
            add(f"TOOL {one_line(name)}:", as_json, limit)

    def add_result(block):
        failed = block.get("is_error")
        long_output = failed or names.get(block.get("tool_use_id")) in LONG_TOOLS
        add(
            "ERROR:" if failed else "RESULT:",
            text_of(block.get("content")),
            LONG_CLIP if long_output else TOOL_CLIP,
        )

    def handle(record, index):
        nonlocal messages, folder, branch
        note_title(record, titles)
        kind = record.get("type")
        if kind == "system" and record.get("subtype") == "compact_boundary":
            body.append("[context compacted here]")
        elif kind == "attachment":
            arrived = queued(record)
            later = (text for at, text in typed if at > index)
            if arrived and arrived[1] and not repeats(arrived[1], later):
                if arrived[0] == USER_QUEUED:
                    add_prompt(USER_QUEUED, arrived[1])
                else:
                    add(NOTICE, arrived[1], LONG_CLIP)
        elif is_conversation(record):
            messages += 1
            folder = record.get("cwd") or folder
            branch = record.get("gitBranch") or branch
            for block in blocks(record):
                if block.get("type") == "text":
                    text = block.get("text") or ""
                    if text.lstrip().startswith(NOTICE_TEXT):
                        add(NOTICE, text, LONG_CLIP)
                    elif text:
                        add_prompt("USER:", text)
                elif block.get("type") == "image":
                    add("USER:", "[image]")
                elif block.get("type") == "tool_result":
                    add_result(block)
        elif kind == "assistant":
            messages += 1
            for block in blocks(record):
                if block.get("type") == "text" and block.get("text"):
                    add("ASSISTANT:", block["text"])
                elif block.get("type") == "tool_use":
                    add_call(block)

    for index, record in enumerate(records):
        if index in ends:
            body.append("[end of the rewound branch]")
        if index in rewound:
            body.append(
                "[rewound branch: the user went back and discarded everything"
                " from here to the end mark]"
            )
        try:
            handle(record, index)
        except BAD_SHAPE:
            skipped += 1
    if not messages and not prompts:
        sys.exit(f"no message found in {path}: the transcript format may have changed")

    head = [
        f"Session: {session}",
        f"File: {tilde(path)}",
        *(
            f"Other copy, not read: {tilde(other)} ({size / 1048576:.1f} MB, {stamp(mtime)})"
            for size, mtime, other in copies[1:]
            if size != copies[0][0]
        ),
        f"Folder: {one_line(tilde(folder))}",
        f"Branch: {one_line(branch)}",
        f"Title: {one_line(title_from(titles))}",
        f"Prompts: {prompts}",
        (
            "Format: a label starts a line, and each content line starts with '| ',"
            " so text inside content that looks like a label is only content."
        ),
        "Not shown: thinking, injected context, the steps inside subagents.",
        (
            f"Clipped: tool output to {TOOL_CLIP} characters; reports, errors and"
            f" pasted text to {LONG_CLIP}; Edit and Write show only the path."
            " Each clipped piece names its --item number."
            " Common secret shapes are masked, and a mask can hit an ordinary name."
        ),
    ]
    if not messages:
        head.append(
            "Warning: only queued prompts were parsed. If the session held more,"
            " the transcript format may have changed."
        )
    if skipped:
        head.append(f"Records skipped because their shape is unknown: {skipped}")
    return "\n".join(head) + "\n\n" + "\n\n".join(body) + "\n", items


def split_parts(text):
    """Cut at line ends, so a part starts with a whole line.

    A line longer than a part is cut, and the rest keeps the gutter.
    """
    pieces = []
    for line in text.split("\n"):
        while len(line) > PART_CHARS:
            pieces.append(line[:PART_CHARS])
            line = "| " + line[PART_CHARS:]
        pieces.append(line)
    parts, current, size = [], [], 0
    for piece in pieces:
        if current and size + len(piece) + 1 > PART_CHARS:
            parts.append("\n".join(current))
            current, size = [], 0
        current.append(piece)
        size += len(piece) + 1
    parts.append("\n".join(current))
    return parts


def page(text, part, what):
    parts = split_parts(text)
    total = len(parts)
    if not 1 <= part <= total:
        sys.exit(f"part {part} does not exist: {what} has {total} parts")
    print(f"[part {part} of {total}]")
    print(parts[part - 1])
    print(f"[next: --part {part + 1}]" if part < total else "[last part]")
    return 0


def read(prefix, part, item):
    session, copies = locate(prefix)
    text, items = render(session, copies)
    if item is None:
        return page(text, part, "this session")
    if not 1 <= item <= len(items):
        sys.exit(f"item {item} does not exist: this session has {len(items)} items")
    return page(gutter(items[item - 1]), part, "this item")


def main():
    # A transcript can hold a lone surrogate, which cannot be encoded.
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)
    find_cmd = commands.add_parser("find")
    find_cmd.add_argument("--skip", default="", help="an ID to leave out")
    find_cmd.add_argument("words", nargs="*")
    read_cmd = commands.add_parser("read")
    read_cmd.add_argument("id")
    read_cmd.add_argument("--part", type=int, default=1)
    read_cmd.add_argument("--item", type=int, help="print one clipped piece, whole")
    args = parser.parse_args()
    if args.command == "find":
        return find(args.words, args.skip)
    return read(args.id, args.part, args.item)


if __name__ == "__main__":
    sys.exit(main())
