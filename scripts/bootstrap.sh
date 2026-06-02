#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_CONFIG="$HOME/.config/zsh"

echo "[+] Linking dotfiles from: $DOTFILES_DIR"
mkdir -p "$ZSH_CONFIG"

for f in aliases exports functions paths recon; do
    ln -sf "$DOTFILES_DIR/zsh/$f.zsh" "$ZSH_CONFIG/$f.zsh"
    echo "    linked $f.zsh"
done

# Copy zshrc from scripts/
cp "$DOTFILES_DIR/scripts/zshrc" "$HOME/.zshrc"
echo "[+] Copied zshrc to ~/.zshrc"

# ─── oh-my-zsh plugins ───────────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    echo "[+] Installing zsh-autosuggestions"
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "[~] zsh-autosuggestions already installed"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    echo "[+] Installing zsh-syntax-highlighting"
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo "[~] zsh-syntax-highlighting already installed"
fi

# Secrets file — create if missing, never overwrite
if [[ ! -f "$ZSH_CONFIG/secrets.zsh" ]]; then
    cp "$DOTFILES_DIR/zsh/secrets.example.zsh" "$ZSH_CONFIG/secrets.zsh"
    echo "[+] Created secrets.zsh from example — fill in your tokens"
fi
chmod 600 "$ZSH_CONFIG/secrets.zsh"

# ─── Wordlists ────────────────────────────────────────────────────────────────
WORDLISTS="$HOME/BugBounty/wordlists"
mkdir -p "$WORDLISTS"

if [[ ! -d "$WORDLISTS/SecLists" ]]; then
    echo "[+] Cloning SecLists"
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git \
        "$WORDLISTS/SecLists"
else
    echo "[~] SecLists already present"
fi

if [[ ! -d "$WORDLISTS/jeanphorn" ]]; then
    echo "[+] Cloning jeanphorn wordlist"
    git clone --depth 1 https://github.com/jeanphorn/wordlist.git \
        "$WORDLISTS/jeanphorn"
fi

if [[ ! -d "$WORDLISTS/orwa" ]]; then
    echo "[+] Cloning orwa wordlist"
    git clone --depth 1 https://github.com/orwagodfather/WordList.git \
        "$WORDLISTS/orwa"
fi

echo ""
echo "[+] Done. Run: source ~/.zshrc"
