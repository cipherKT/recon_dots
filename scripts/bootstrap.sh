#!/usr/bin/env bash

mkdir -p ~/.config/zsh

ln -sf ~/Project/dotfiles/zsh/aliases.zsh ~/.config/zsh/aliases.zsh
ln -sf ~/Project/dotfiles/zsh/functions.zsh ~/.config/zsh/functions.zsh
ln -sf ~/Project/dotfiles/zsh/exports.zsh ~/.config/zsh/exports.zsh
ln -sf ~/Project/dotfiles/zsh/recon.zsh ~/.config/zsh/recon.zsh
ln -sf ~/Project/dotfiles/zsh/paths.zsh ~/.config/zsh/paths.zsh

echo "[+] Dotfiles linked successfully!"
