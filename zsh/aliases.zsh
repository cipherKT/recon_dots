# ─── Unalias oh-my-zsh git plugin conflicts ───────────────────────────────────
unalias gau 2>/dev/null || true
unalias gf  2>/dev/null || true
# ─── General ──────────────────────────────────────────────────────────────────
alias ll='ls -lah'
alias zshreload='source ~/.zshrc'
alias urldedupe='/home/cipher/BugBounty/tools/urldedupe/urldedupe'
# ─── Recon shortcuts ──────────────────────────────────────────────────────────
alias passive='ls passive/ 2>/dev/null || echo "[!] No passive/ dir here"'
alias live='ls live/ 2>/dev/null || echo "[!] No live/ dir here"'

# ─── Quick navs──────────────────────────────────────────────────────────
alias bb='cd ~/BugBounty/'
alias dots='cd ~/BugBounty/recon_dots/'
alias edit_dots='cd ~/BugBounty/recon_dots/ && zeditor .'

