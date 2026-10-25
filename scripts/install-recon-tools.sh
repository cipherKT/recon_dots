#!/usr/bin/env bash
# install-recon-tools.sh — install every dependency used by zsh/recon/*.zsh
#
# Usage: install-recon-tools [--upgrade] [--check-only] [-y]
#   --upgrade     reinstall Go/pipx tools even when already present
#   --check-only  print tool status + pending manual steps, install nothing
#   -y            assume yes for the system package manager (no prompt)
#
# Covered wrappers and their tools:
#   subs                : subfaster, subfinder, assetfinder, curl, jq, github-subdomains
#   hx                  : httpx, anew
#   kat                 : katana
#   url_harvest(_katana): gau, waymore, waybackurls, anew, urldedupe
#   Additional recon tools: ffuf, shortscan
#   js_harvest(_all)    : rg (ripgrep)
#   curlall             : curl
#
# Manual steps (API tokens etc.) are printed at the end ONLY if incomplete.

set -u
set -o pipefail

UPGRADE=0
CHECK_ONLY=0
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
  --upgrade) UPGRADE=1 ;;
  --check-only) CHECK_ONLY=1 ;;
  -y | --yes) ASSUME_YES=1 ;;
  -h | --help)
    echo "Usage: $(basename "$0") [--upgrade] [--check-only] [-y]"
    echo "  --upgrade     reinstall Go/pipx tools even when already present"
    echo "  --check-only  print tool status + pending manual steps, install nothing"
    echo "  -y            assume yes for the system package manager (no prompt)"
    exit 0
    ;;
  *)
    echo "[!] Unknown flag: $arg (see --help)"
    exit 1
    ;;
  esac
done

# Make sure freshly installed Go/pipx binaries are visible in this session
export PATH="$HOME/go/bin:$HOME/.pdtm/go/bin:$HOME/.local/bin:$PATH"

OK=()
SKIPPED=()
FAILED=()

have() { command -v "$1" &>/dev/null; }

mark_ok() {
  OK+=("$1")
  echo "    [ok] $1"
}
mark_skipped() {
  SKIPPED+=("$1")
  echo "    [~] $1 ($2)"
}
mark_failed() {
  FAILED+=("$1")
  echo "    [FAIL] $1 ($2)"
}

# ─── 1. System packages (curl, jq, rg, git, go, cmake, make, compiler, pipx) ──
# binary -> package names per manager (pacman | apt | dnf | brew)
SYS_TOOLS=(curl jq rg git go cmake make g++ pipx zsh)
PACMAN_PKGS=(curl jq ripgrep git go cmake make gcc python-pipx zsh)
APT_PKGS=(curl jq ripgrep git golang-go cmake make g++ pipx zsh)
DNF_PKGS=(curl jq ripgrep git golang cmake make gcc-c++ pipx zsh)
BREW_PKGS=(curl jq ripgrep git go cmake make gcc pipx zsh)

detect_pm() {
  if have pacman; then
    echo pacman
  elif have apt-get; then
    echo apt
  elif have dnf; then
    echo dnf
  elif have brew; then
    echo brew
  else
    echo none
  fi
}

# Minimal Kali/container installations may run as root without sudo installed.
run_as_root() {
  if (( EUID == 0 )); then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    echo "[!] sudo is required to install system packages as a non-root user." >&2
    return 1
  fi
}

install_system_packages() {
  local missing_idx=()
  local i
  for i in "${!SYS_TOOLS[@]}"; do
    have "${SYS_TOOLS[$i]}" || missing_idx+=("$i")
  done

  if ((${#missing_idx[@]} == 0)); then
    echo "[+] System packages — all present"
    return 0
  fi

  if ((CHECK_ONLY)); then
    local names=()
    for i in "${missing_idx[@]}"; do names+=("${SYS_TOOLS[$i]}"); done
    echo "[*] System packages — missing: ${names[*]}"
    return 0
  fi

  local pm
  pm="$(detect_pm)"
  if [[ "$pm" == "none" ]]; then
    echo "[!] No supported package manager found (pacman/apt/dnf/brew)."
    echo "    Install manually: curl jq ripgrep git go cmake make c++-compiler pipx zsh"
    for i in "${missing_idx[@]}"; do mark_failed "${SYS_TOOLS[$i]}" "no package manager"; done
    return 1
  fi

  echo "[+] System packages — installing missing via $pm"
  if ((!ASSUME_YES)); then
    local reply
    read -r -p "    Install with $pm (sudo if needed)? [Y/n] " reply || reply=n
    if [[ "$reply" =~ ^[Nn] ]]; then
      echo "    Skipped by user — install manually (see summary)."
      for i in "${missing_idx[@]}"; do mark_failed "${SYS_TOOLS[$i]}" "skipped by user"; done
      return 1
    fi
  fi

  local pkgs=()
  local i
  for i in "${missing_idx[@]}"; do
    case "$pm" in
    pacman) pkgs+=("${PACMAN_PKGS[$i]}") ;;
    apt) pkgs+=("${APT_PKGS[$i]}") ;;
    dnf) pkgs+=("${DNF_PKGS[$i]}") ;;
    brew) pkgs+=("${BREW_PKGS[$i]}") ;;
    esac
  done
  # de-duplicate package names
  pkgs=($(printf '%s\n' "${pkgs[@]}" | sort -u))

  case "$pm" in
  pacman) run_as_root pacman -S --needed --noconfirm "${pkgs[@]}" ;;
  apt) run_as_root apt-get update && run_as_root apt-get install -y "${pkgs[@]}" ;;
  dnf) run_as_root dnf install -y "${pkgs[@]}" ;;
  brew) brew install "${pkgs[@]}" ;;
  esac

  # re-verify each binary
  for i in "${missing_idx[@]}"; do
    local bin="${SYS_TOOLS[$i]}"
    if have "$bin"; then
      mark_ok "$bin (system)"
    else
      mark_failed "$bin" "system install incomplete"
    fi
  done
}

# ─── 2. Go tools ─────────────────────────────────────────────────────────────
# binary -> go install path
GO_TOOLS=(
  "subfaster:github.com/melvinsh/subfaster/v2/cmd/subfaster@latest"
  "subfinder:github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  "assetfinder:github.com/tomnomnom/assetfinder@latest"
  "httpx:github.com/projectdiscovery/httpx/cmd/httpx@latest"
  "katana:github.com/projectdiscovery/katana/cmd/katana@latest"
  "gau:github.com/lc/gau/v2/cmd/gau@latest"
  "waybackurls:github.com/tomnomnom/waybackurls@latest"
  "anew:github.com/tomnomnom/anew@latest"
  "github-subdomains:github.com/gwen001/github-subdomains@latest"
  "ffuf:github.com/ffuf/ffuf/v2@latest"
  "shortscan:github.com/bitquark/shortscan@latest"
)

install_go_tools() {
  echo "[+] Go tools"
  if ! have go && ((!CHECK_ONLY)); then
    echo "    [!] go toolchain missing and system install did not provide it."
    echo "        Install go manually, then re-run: $(basename "$0")"
    for entry in "${GO_TOOLS[@]}"; do
      have "${entry%%:*}" || mark_failed "${entry%%:*}" "no go toolchain"
    done
    return 1
  fi
  if ! have go; then
    echo "    [~] go toolchain missing (system install would provide it)"
  fi

  for entry in "${GO_TOOLS[@]}"; do
    local bin="${entry%%:*}"
    local pkg="${entry#*:}"
    if have "$bin" && ((!UPGRADE)) && ((!CHECK_ONLY)); then
      mark_skipped "$bin" "already installed"
      continue
    fi
    if ((CHECK_ONLY)); then
      if have "$bin"; then
        mark_skipped "$bin" "already installed"
      else echo "    [..] $bin — missing (would: go install $pkg)"; fi
      continue
    fi
    echo "    [*] installing $bin ..."
    if go install "$pkg" 2>/tmp/recon-install-go-err.log; then
      mark_ok "$bin (go install)"
    else
      mark_failed "$bin" "go install failed — $(tail -n 1 /tmp/recon-install-go-err.log 2>/dev/null || echo 'see output')"
    fi
  done
  rm -f /tmp/recon-install-go-err.log
}

# ─── 3. waymore (Python, via pipx) ───────────────────────────────────────────
install_waymore() {
  echo "[+] waymore (Python)"
  if have waymore && ((!UPGRADE)) && ((!CHECK_ONLY)); then
    mark_skipped "waymore" "already installed"
    return 0
  fi
  if ((CHECK_ONLY)); then
    if have waymore; then
      mark_skipped "waymore" "already installed"
    else echo "    [..] waymore — missing (would: pipx install waymore)"; fi
    return 0
  fi
  if have pipx; then
    echo "    [*] installing waymore via pipx ..."
    if have waymore && ((UPGRADE)); then
      pipx reinstall waymore 2>/dev/null || pipx install --force "git+https://github.com/xnl-h4ck3r/waymore.git"
    else
      pipx install "git+https://github.com/xnl-h4ck3r/waymore.git" 2>/dev/null ||
        pipx install waymore
    fi
  else
    mark_failed "waymore" "pipx missing — install pipx with your package manager and re-run"
    return 1
  fi
  if have waymore; then
    mark_ok "waymore"
  else mark_failed "waymore" "pipx/pip install failed"; fi
}

# ─── 4. urldedupe (C++, installed as a command) ────────────────────────────
URLDEDUPE_DIR="${URLDEDUPE_DIR:-$HOME/security/BugBounty/tools/urldedupe}"

link_urldedupe() {
  mkdir -p "$HOME/.local/bin" &&
    ln -sfn "$URLDEDUPE_DIR/urldedupe" "$HOME/.local/bin/urldedupe"
}

install_urldedupe() {
  echo "[+] urldedupe (C++)"
  if [[ -x "$URLDEDUPE_DIR/urldedupe" ]] && ((!UPGRADE)) && ((!CHECK_ONLY)); then
    link_urldedupe || { mark_failed "urldedupe" "could not link executable"; return 1; }
    mark_skipped "urldedupe" "already built at $URLDEDUPE_DIR/urldedupe"
    return 0
  fi
  if ((CHECK_ONLY)); then
    if [[ -x "$URLDEDUPE_DIR/urldedupe" ]]; then
      mark_skipped "urldedupe" "already built"
    else echo "    [..] urldedupe — missing (would: clone + cmake + make in $URLDEDUPE_DIR)"; fi
    return 0
  fi
  if ! have cmake; then
    mark_failed "urldedupe" "cmake missing — install it and re-run"
    return 1
  fi
  if [[ ! -d "$URLDEDUPE_DIR/.git" ]]; then
    echo "    [*] cloning urldedupe ..."
    mkdir -p "$(dirname "$URLDEDUPE_DIR")"
    git clone --depth 1 https://github.com/ameenmaali/urldedupe.git "$URLDEDUPE_DIR" ||
      {
        mark_failed "urldedupe" "git clone failed"
        return 1
      }
  else
    echo "    [*] urldedupe repo present — pulling latest ..."
    git -C "$URLDEDUPE_DIR" pull --ff-only 2>/dev/null || true
  fi
  echo "    [*] building urldedupe ..."
  if (cd "$URLDEDUPE_DIR" && cmake CMakeLists.txt >/dev/null && make); then
    link_urldedupe || { mark_failed "urldedupe" "could not link executable"; return 1; }
    mark_ok "urldedupe ($URLDEDUPE_DIR/urldedupe)"
  else
    mark_failed "urldedupe" "cmake/make failed"
  fi
}

# Tokens are supplied by the caller's environment, not shell files managed here.
check_manual_steps() {
  echo ""
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "[~] Optional: export GITHUB_TOKEN to enable github-subdomains in subs."
  fi
  echo '[+] Ensure these tool directories are on your shell PATH:'
  printf '    %s\n' "$HOME/go/bin" "$HOME/.pdtm/go/bin" "$HOME/.local/bin"
}

# ─── main ────────────────────────────────────────────────────────────────────
echo "=== recon tools installer ($(basename "$0")) ==="
echo ""

install_system_packages
echo ""
install_go_tools
echo ""
install_waymore
echo ""
install_urldedupe

echo ""
echo "=== summary: ${#OK[@]} installed, ${#SKIPPED[@]} already present, ${#FAILED[@]} failed ==="
if ((${#FAILED[@]} > 0)); then
  echo "Failed:"
  for t in "${FAILED[@]}"; do echo "  - $t"; done
fi

check_manual_steps

# Do not report success when a dependency failed to install.
(( ${#FAILED[@]} == 0 ))
