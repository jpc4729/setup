# Makes docs/cs.gif. Run `vhs docs/cs.tape` from the repo root.
Output docs/cs.gif
Set Shell zsh
Set FontSize 16
Set Width 1120
Set Height 760
Set Padding 16
Set WindowBar Colorful
Set TypingSpeed 90ms

# HOME is fake before the setup runs, so a failed setup cannot show real repos,
# and the shell exits on a failure before its prompt shows the repo path. The
# other variables give stock fzf, git and rg, and no personal shell or herdr state.
Hide
Type@5ms `export HOME=/tmp/cs-demo/home PATH=/tmp/cs-demo/bin:$PATH SHELL=/bin/zsh PROMPT='%F{blue}%~%f %# '; unset FZF_DEFAULT_OPTS FZF_DEFAULT_OPTS_FILE XDG_CONFIG_HOME GIT_CONFIG_GLOBAL RIPGREP_CONFIG_PATH ZDOTDIR HERDR_ENV HERDR_PANE_ID CLAUDE_CONFIG_DIR; bash docs/cs-demo.sh || exit 1; cd ~ && clear`
Enter
Sleep 5s
Show

Sleep 800ms
Type "cs"
Sleep 500ms
Enter
Sleep 3s
Down
Sleep 2s
Down@500ms 3
Sleep 500ms
Down
Sleep 3s
Down@500ms 3
Sleep 3s
Type "login"
Sleep 2.5s
Ctrl+T
Sleep 3.5s
