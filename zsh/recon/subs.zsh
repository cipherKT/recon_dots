# ─── subs ─────────────────────────────────────────────────────────────────────
# Usage: subs target.com
# Output: ./passive/*.txt  (run from your recon/ dir)
subs() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[!] Usage: subs target.com"
        return 1
    fi

    local tools=(subfinder assetfinder jq anew github-subdomains curl)
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo "[!] Missing dependency: $tool"
            return 1
        fi
    done

    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo "[!] GITHUB_TOKEN is not set"
        return 1
    fi

    local base="$(pwd)/passive"
    mkdir -p "$base"

    echo "[+] Running subfinder"
    subfinder -d "$domain" -silent -all -recursive \
        -o "$base/subfinder.txt"

    echo "[+] Running assetfinder"
    assetfinder --subs-only "$domain" \
        | anew "$base/assetfinder.txt"

    echo "[+] Running crt.sh"
    curl -s "https://crt.sh/?q=%25.$domain&output=json" \
        | jq -r '.[].name_value' \
        | sed 's/\*\.//g' \
        | anew "$base/crtsh.txt"

    echo "[+] Running github-subdomains"
    github-subdomains -d "$domain" -t "$GITHUB_TOKEN" \
        -o "$base/github.txt"

    echo "[+] Combining results"
    cat "$base"/*.txt | sort -u | anew "$base/all_subs.txt"

    echo "[+] Done — $(wc -l < "$base/all_subs.txt") unique subs"
    echo "[+] Output: $base/all_subs.txt"
}
