# ─── ffm ──────────────────────────────────────────────────────────────────────
# Usage: ffm https://target.com
ffm() {
    local url="${1%/}"
    if [[ -z "$url" ]]; then
        echo "[!] Usage: ffm https://target.com"
        return 1
    fi
    if [[ -z "$WL_DIRB" || ! -f "$WL_DIRB" ]]; then
        echo "[!] WL_DIRB not set or file missing: $WL_DIRB"
        return 1
    fi

    ffuf \
        -u "$url/FUZZ" \
        -w "$WL_DIRB" \
        -mc all \
        -fc 404
}
