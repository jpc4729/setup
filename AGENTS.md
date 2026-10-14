# AGENTS.md

This repo is an agent setup for macOS. `install.sh` copies each tool folder into its home.

Claude Code (`claude/`) is the main agent tool. Design, measure and test each agent change for Claude Code first. Keep the other tool folders (`codex/`, `cursor/`, `grok/`, `opencode/`) in line with it, but never as critical work: a gap there never blocks or delays a Claude Code change. A tool for agent work, such as `bin/agent-stats`, reads and reports only Claude Code data. An audit of Claude Code results or metrics looks only at `claude/` and Claude Code data, and its findings and fixes target `claude/`.
