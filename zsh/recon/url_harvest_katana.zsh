# ─── url_harvest_katana ───────────────────────────────────────────────────────
# Usage: url_harvest_katana <file.txt|url>
# File: one host per line (https://sub.target.com or sub.target.com)
# Output: ./urls/<hostname>/{katana,gau,waymore,waybackurls,all_urls}.txt
# Includes Katana crawling.
url_harvest_katana() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: url_harvest_katana <file.txt|url>"
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
        echo "[+] Harvesting (with katana): $hostname"

        echo "  [*] Running katana"
        katana \
            -u "$host" \
            -silent \
            -jc \
            -kf all \
            -d 3 \
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

    echo ""
    echo "[+] Creating combined deduplicated all_urls.txt via urldedupe"
    cat "$(pwd)/urls/"*/all_urls.txt 2>/dev/null \
        | urldedupe \
        | anew "$(pwd)/all_urls.txt"
    echo "[+] Combined: $(pwd)/all_urls.txt ($(wc -l < "$(pwd)/all_urls.txt") unique)"
}
