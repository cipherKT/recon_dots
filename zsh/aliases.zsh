# ─── Unalias oh-my-zsh git plugin conflicts ───────────────────────────────────
unalias gau 2>/dev/null || true
unalias gf  2>/dev/null || true
# ─── General ──────────────────────────────────────────────────────────────────
alias ll='ls -lah'
alias zshreload='source ~/.zshrc'

# ─── Recon shortcuts ──────────────────────────────────────────────────────────
alias passive='ls passive/ 2>/dev/null || echo "[!] No passive/ dir here"'
alias live='ls live/ 2>/dev/null || echo "[!] No live/ dir here"'
