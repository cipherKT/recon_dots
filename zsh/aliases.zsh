# ─── Unalias oh-my-zsh git plugin conflicts ───────────────────────────────────
unalias gau 2>/dev/null || true
unalias gf  2>/dev/null || true
# ─── General ──────────────────────────────────────────────────────────────────
alias ll='ls -lah'
alias zshreload='source ~/.zshrc'
# ─── Recon shortcuts ──────────────────────────────────────────────────────────
alias passive='ls passive/ 2>/dev/null || echo "[!] No passive/ dir here"'
alias live='ls live/ 2>/dev/null || echo "[!] No live/ dir here"'

# ─── Quick navs ──────────────────────────────────────────────────────────
alias bb='cd ~/BugBounty/'
alias dots='cd ~/BugBounty/recon_dots/'

# ─── BugBounty aliases ──────────────────────────────────────────────────────────
alias urldedupe='/home/cipher/BugBounty/tools/urldedupe/urldedupe'
alias dirsearch='/home/cipher/BugBounty/tools/dirsearch/.venv/bin/python /home/cipher/BugBounty/tools/dirsearch/dirsearch.py'
