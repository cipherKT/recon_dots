#!/usr/bin/env bash
# Install only the recon wrapper loader; leave shell configuration to the user.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECON_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/recon-dots"

mkdir -p "$RECON_CONFIG"
loader="$RECON_CONFIG/recon.zsh"
if [[ -e "$loader" && ! -L "$loader" ]]; then
    echo "[!] Refusing to replace existing file: $loader" >&2
    exit 1
fi
if [[ -d "$loader" && ! -L "$loader" ]]; then
    echo "[!] Refusing to replace existing directory: $loader" >&2
    exit 1
fi
ln -sfn "$REPO_DIR/zsh/recon.zsh" "$loader"
echo "[+] Linked recon wrappers: $loader"
echo '[+] Add this line to your existing ~/.zshrc, then run it in zsh:'
printf 'source %q\n' "$loader"
echo '[+] Install recon dependencies separately:'
printf 'bash %q\n' "$REPO_DIR/scripts/install-recon-tools.sh"
