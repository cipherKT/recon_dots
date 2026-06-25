# Source all modular recon wrappers
local recon_dir="${0:A:h}/recon"
if [[ ! -d "$recon_dir" && -n "$ZSH_CONFIG_DIR" ]]; then
    recon_dir="$ZSH_CONFIG_DIR/recon"
fi

if [[ -d "$recon_dir" ]]; then
    for file in "$recon_dir"/*.zsh; do
        source "$file"
    done
else
    echo "[!] Could not find recon wrappers directory: $recon_dir"
fi
