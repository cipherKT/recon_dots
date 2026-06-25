# ─── url_harvest ──────────────────────────────────────────────────────────────
# Usage: url_harvest <file.txt|url>
# File: one host per line (https://sub.target.com or sub.target.com)
# Output: ./urls/<hostname>/{gau,waymore,waybackurls,all_urls}.txt
# Skips Katana — for data-heavy targets where crawling would waste time.
url_harvest() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: url_harvest <file.txt|url>"
        return 1
    fi

    local tools=(gau waymore waybackurls anew)
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
        echo "[+] Harvesting (no katana): $hostname"

        echo "  [*] Running gau"
        gau "$hostname" --o "$base/gau.txt"

        echo "  [*] Running waymore"
        waymore -i "$hostname" -mode U -oU "$base/waymore.txt"

        echo "  [*] Running waybackurls"
        waybackurls "$hostname" -no-subs \
            | anew "$base/waybackurls.txt"

        echo "  [+] Deduping into all_urls.txt"
        cat "$base/gau.txt" \
            "$base/waymore.txt" \
            "$base/waybackurls.txt" \
            2>/dev/null \
            | sort -u \
            | anew "$base/all_urls.txt"

        echo "  [+] Done — $(wc -l < "$base/all_urls.txt") unique URLs"
        echo "  [+] Output: $base/"
    done

    echo ""
    echo "[+] Creating combined deduplicated all_urls.txt via urldedupe"
    cat "$(pwd)/urls/"*/all_urls.txt 2>/dev/null \
        | urldedupe \
        | anew "$(pwd)/all_urls.txt"
    echo "[+] Combined: $(pwd)/all_urls.txt ($(wc -l < "$(pwd)/all_urls.txt") unique)"
}
