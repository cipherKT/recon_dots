# ─── subs ─────────────────────────────────────────────────────────────────────
# Usage: subs target.com
# Output: ./passive/*.txt  (run from your recon/ dir)
subs() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "[!] Usage: subs target.com"
        return 1
    fi

    local tools=(subfinder assetfinder amass jq anew github-subdomains curl)
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

    echo "[+] Running amass passive"
    amass enum -passive -d "$domain" \
        -o "$base/amass.txt"

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

# ─── hx ───────────────────────────────────────────────────────────────────────
# Usage: hx passive/all_subs.txt   (or any subs file)
# Output: ./live/httpx.txt
hx() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "[!] Usage: hx subdomains.txt"
        return 1
    fi
    if [[ ! -f "$input" ]]; then
        echo "[!] File not found: $input"
        return 1
    fi
    if ! command -v httpx &>/dev/null; then
        echo "[!] httpx not installed"
        return 1
    fi

    local base="$(pwd)/live"
    mkdir -p "$base"
    local output="$base/httpx.txt"

    echo "[*] Running httpx"
    httpx \
        -l "$input" \
        -silent \
        -follow-redirects \
        -sc -cl -ct -location -wc \
        -title -server -tech-detect \
        -ip -cname -cdn \
        -threads 100 \
        -rate-limit 200 \
        -timeout 10 \
        -retries 2 \
        -o "$output"

    echo "[+] Output: $output"
    echo "[+] Live hosts: $(wc -l < "$output")"
}

# ─── kat ──────────────────────────────────────────────────────────────────────
# Usage: kat live/httpx.txt
# Output: ./katana.txt
kat() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "[!] Usage: kat live_hosts.txt"
        return 1
    fi
    if [[ ! -f "$input" ]]; then
        echo "[!] File not found: $input"
        return 1
    fi

    local output="$(pwd)/katana.txt"

    katana \
        -list "$input" \
        -silent \
        -jc \
        -kf all \
        -d 5 \
        -o "$output"

    echo "[+] Output: $output"
}

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
