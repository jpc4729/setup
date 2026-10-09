---
name: handoff
description: "Summarize the current conversation into a handoff document and a kickoff prompt when the user asks to transfer work to another session."
argument-hint: "[what the next session will do]"
disable-model-invocation: true
metadata:
  short-description: "Handoff document and kickoff prompt"
---

Use only when the user asks for a handoff. Produce two artifacts in order. If the user gives a focus for the next session, tailor both artifacts to it.

The handoff must work with any model, harness, or tool set. Describe the work and required capabilities without prescribing a model, provider, tool API, or invocation syntax. Record task-specific tools and commands as context and evidence; do not assume the next session has them, shared files, conversation history, or persistent state.

## 1. Handoff document

Write it so a new session can continue the work. If file writing is available and permitted, save a Markdown file in the operating system's temporary directory and report its path. Never save it in the current workspace. Otherwise, print the full document in the response. If the next session cannot access a saved file, tell the user to attach or paste its contents.

- First reach a safe point: finish the current step or undo it, so no file is left half-edited. Record what is still broken.
- State the objective, scope, constraints, and definition of done. Record pending questions and approvals; the handoff does not grant new permissions.
- State what is done, what remains, and what is blocked. Include the checks actually run and their results, with commands when applicable. Mark unverified claims and checks not run.
- Record relevant working state, such as the repository, branch, changed files, and unfinished operations. Explain what must be checked again before work resumes.
- Reference existing artifacts (requirements, plans, decisions, issues, commits, diffs) by path or URL. Avoid copying whole artifacts, but include the facts needed to continue when the destination cannot access them. Identify required material that must be transferred.
- Record failed approaches ("tried X, failed because Y") and decisions with their reasons, so the next session does not repeat rejected approaches.
- If relevant skills or guides are known, list their names, locations, and purpose as optional resources. State the required work directly so it does not depend on those resources or a skill system.
- List remaining tasks in dependency order and size each by complexity: S, M, L, or XL. Do not assume delegation is available or authorized.
- Redact sensitive information (API keys, passwords, personal data).

## 2. Kickoff prompt

Print a single fenced code block, ready to copy into the next session. Keep it short and avoid repeating details from the handoff document.

- Open with the action: `Read <handoff path>, then ...` when the file will be accessible, or `Read the attached or pasted handoff, then ...` otherwise.
- State the objective and its definition of done.
- Include scope constraints and required confirmations only where they apply.
- Direct the next session to verify the current state and available capabilities, then take the next unfinished step within the user's authorization. If required context or access is missing, ask for it instead of assuming it exists.
