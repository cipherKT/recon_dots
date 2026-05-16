#!/usr/bin/env bash

set -e

mkdir -p ~/.config/zsh

ln -sf ~/Project/dotfiles/zsh/aliases.zsh ~/.config/zsh/aliases.zsh
ln -sf ~/Project/dotfiles/zsh/functions.zsh ~/.config/zsh/functions.zsh
ln -sf ~/Project/dotfiles/zsh/exports.zsh ~/.config/zsh/exports.zsh
ln -sf ~/Project/dotfiles/zsh/recon.zsh ~/.config/zsh/recon.zsh
ln -sf ~/Project/dotfiles/zsh/paths.zsh ~/.config/zsh/paths.zsh

echo "[+] Dotfiles linked successfully!"
chmod 600 ~/.config/zsh/secrets.zsh 2>/dev/null || true

mkdir -p "$HOME"/Wordlists
if [[ ! -d "$HOME/Wordlists/jeanPhorn" ]]; then
    git clone https://github.com/jeanphorn/wordlist.git \
        "$HOME/Wordlists/jeanPhorn"
fi
if [[ ! -d "$HOME/Wordlists/orwa" ]]; then
    git clone https://github.com/orwagodfather/WordList.git \
        "$HOME/Wordlists/orwa"
fi
if [[ ! -d "$HOME/Wordlists/SecLists" ]]; then
    git clone https://github.com/danielmiessler/SecLists.git \
        "$HOME/Wordlists/SecLists"
fi
