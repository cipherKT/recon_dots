# Make sure ~/.local/bin is in PATH so command -v can find mise if installed locally
export PATH="$PATH:$HOME/.local/bin"

# ─── Go / Mise (Tool Version Manager) ─────────────────────────────────────────
if command -v mise &>/dev/null && mise where go &>/dev/null; then
    export GOROOT="$(mise where go)"
else
    export GOROOT=/usr/local/go
fi
export GOPATH=$HOME/go

# ─── PATH ─────────────────────────────────────────────────────────────────────
export PATH="$PATH:$GOROOT/bin"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/.pdtm/go/bin"
