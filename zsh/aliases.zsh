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
alias dots='cd ~/security/BugBounty/recon_dots/'
alias bb='cd ~/security/BugBounty/'

# ─── BugBounty aliases ──────────────────────────────────────────────────────────
alias install-recon='bash ~/security/BugBounty/recon_dots/scripts/install-recon-tools.sh'
alias urldedupe='$HOME/security/BugBounty/tools/urldedupe/urldedupe'
alias dirsearch='~/security/BugBounty/tools/dirsearch/.venv/bin/python ~/BugBounty/tools/dirsearch/dirsearch.py'
alias loxs='~/security/BugBounty/tools/loxs/.venv/bin/python ~/BugBounty/tools/loxs/loxs.py'
alias serve='python3 -m http.server 4444'

# ─── Docker ──────────────────────────────────────────────────────────
alias docker='sudo docker'

# ─── venvs──────────────────────────────────────────────────────────
alias activate_android="source $HOME/security/tools/python_venvs/.android/bin/activate"
alias activate_web="source $HOME/security/tools/python_venvs/.web/bin/activate"
