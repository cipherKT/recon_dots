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
alias targets='cd ~/BugBounty/targets/'
alias dots='cd ~/BugBounty/recon_dots/'

# ─── BugBounty aliases ──────────────────────────────────────────────────────────
alias urldedupe='~/BugBounty/tools/urldedupe/urldedupe'
alias dirsearch='~/BugBounty/tools/dirsearch/.venv/bin/python ~/BugBounty/tools/dirsearch/dirsearch.py'
alias loxs='~/BugBounty/tools/loxs/.venv/bin/python ~/BugBounty/tools/loxs/loxs.py'
