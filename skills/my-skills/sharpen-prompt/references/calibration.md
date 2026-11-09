# Calibrate for the target model

Last checked 2026-11-07. Copy a line from here into the sharpened prompt only when the target model from Step 1 of `SKILL.md` calls for it.

- All 5.x models: effort sets depth, not wording (Opus 5.5 defaults to medium). One brief instruction steers a family of behaviors, and the reason behind a request helps.
- Opus 5 and 5.5: drop "double-check" lines. Narrow tasks: "Deliver what was asked, at the scope intended; if the request seems mistaken, say so in a sentence and continue as asked." Delegation: "Delegate only large, independent work; don't use subagents to verify your own work." Unattended runs need named stops. Written files run long: "Match the document's length to what the task needs."
- Sonnet 5.5 and Haiku 5.5 at low or medium effort: "Before reporting done, run a real check that exercises the change. A syntax-only check, or a command that failed to start, doesn't count. If none can run, say which and why." Sonnet 5.5 adds extras: "When the work is done and checked, stop; mention extras instead of doing them."
- Fable 5 and 5.1: brief the outcome, reason and boundaries, not the steps. Long runs: "Audit each progress claim against a tool result from this session." Fable 5.1: "Edit surgically rather than rewriting whole files."

To refresh, fetch with `.md` appended: platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (and the prompting-claude-opus-5-5, -sonnet-5-5, -fable-5-1 pages), code.claude.com/docs/en/best-practices.md, and claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models.
