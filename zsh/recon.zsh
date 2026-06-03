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

    echo "[*] Filtering URLs only"
    awk '{print $1}' "$output" | anew "$base/httpx_simple.txt"
    echo "[+] URLs only: $base/httpx_simple.txt"
}

# ─── kat ──────────────────────────────────────────────────────────────────────
# Usage: kat <file.txt|url>
# Output: ./katana.txt
kat() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "[!] Usage: kat <live_hosts.txt|url>"
        return 1
    fi

    local output="$(pwd)/katana.txt"

    if [[ -f "$input" ]]; then
        katana \
            -list "$input" \
            -silent \
            -jc \
            -kf all \
            -d 5 \
            -o "$output"
    else
        katana \
            -u "$input" \
            -silent \
            -jc \
            -kf all \
            -d 5 \
            -o "$output"
    fi

    echo "[+] Output: $output"
}

# ─── url_harvest ──────────────────────────────────────────────────────────────
# Usage: url_harvest <file.txt|url>
# File: one host per line (https://sub.target.com or sub.target.com)
# Output: .urls/<hostname>/katana.txt, gau.txt, waymore.txt, waybackurls.txt, all_urls.txt
url_harvest() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: url_harvest <file.txt|url>"
        return 1
    fi

    local tools=(katana gau waymore waybackurls anew)
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo "[!] Missing dependency: $tool"
            return 1
        fi
    done

    # build list of hosts — single URL or file
    local hosts=()
    if [[ -f "$input" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            hosts+=("$line")
        done < "$input"
    else
        hosts+=("$input")
    fi

    for host in "${hosts[@]}"; do
        # strip scheme for clean hostname used as dir name
        local hostname="${host#https://}"
        hostname="${hostname#http://}"
        hostname="${hostname%/}"

        local base="$(pwd)/urls/$hostname"
        mkdir -p "$base"

        echo ""
        echo "[+] Harvesting: $hostname"

        echo "  [*] Running katana"
        katana \
            -u "$host" \
            -silent \
            -jc \
            -kf all \
            -d 5 \
            -o "$base/katana.txt"

        echo "  [*] Running gau"
        gau "$hostname" --o "$base/gau.txt"

        echo "  [*] Running waymore"
        waymore -i "$hostname" -mode U -oU "$base/waymore.txt"

        echo "  [*] Running waybackurls"
        waybackurls "$hostname" -no-subs \
            | anew "$base/waybackurls.txt"

        echo "  [+] Deduping into all_urls.txt"
        cat "$base/katana.txt" \
            "$base/gau.txt" \
            "$base/waymore.txt" \
            "$base/waybackurls.txt" \
            2>/dev/null \
            | sort -u \
            | anew "$base/all_urls.txt"

        echo "  [+] Done — $(wc -l < "$base/all_urls.txt") unique URLs"
        echo "  [+] Output: $base/"
    done
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
