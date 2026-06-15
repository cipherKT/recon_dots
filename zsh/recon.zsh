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
# Output: ./live/httpx.txt, ./live/httpx_simple.txt
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
# Output: ./urls/<hostname>/{katana,gau,waymore,waybackurls,all_urls}.txt
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

    echo ""
    echo "[+] Creating combined deduplicated all_urls.txt via urldedupe"
    cat "$(pwd)/urls/"*/all_urls.txt 2>/dev/null \
        | urldedupe \
        | anew "$(pwd)/all_urls.txt"
    echo "[+] Combined: $(pwd)/all_urls.txt ($(wc -l < "$(pwd)/all_urls.txt") unique)"
}

# ─── url_harvest_wo_katana ─────────────────────────────────────────────────────
# Usage: url_harvest_wo_katana <file.txt|url>
# Same as url_harvest but skips katana — for data-heavy targets where
# crawling would waste time on millions of static assets.
# Output: ./urls/<hostname>/{gau,waymore,waybackurls,all_urls}.txt
url_harvest_wo_katana() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: url_harvest_wo_katana <file.txt|url>"
        return 1
    fi

    local tools=(gau waymore waybackurls anew)
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo "[!] Missing dependency: $tool"
            return 1
        fi
    done

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

# ─── js_harvest ───────────────────────────────────────────────────────────────
# Usage: js_harvest <urls.txt>
# Output: ./js_files.txt
js_harvest() {
  local input="$1"
  if [[ -z "$input" ]]; then 
    echo "[!] Usage: js_harvest <urls.txt>"
    return 1
  fi 

  if [[ ! -f "$input" ]]; then 
    echo "[!] File not found: $input"
    return 1
  fi 

  local output="$(pwd)/js_files.txt"

  rg '\.js' "$input" | sort -u > "$output"

  echo "[+] Ouput saved to: $output"
  echo "[+] JS/JSON files found: $(wc -l < "$output")"

}

# ─── js_harvest all ───────────────────────────────────────────────────────────────
# Usage: js_harvest_all
# Reads ./urls/<hostname>/all_urls.txt
# Output: ./urls/<hostname>/js_files.txt
js_harvest_all(){
  # echo "Harvesting all js files"
  local url_dir="$PWD/urls"
  # echo "hui hui hui hui just after urls directory"
  local combined="$PWD/js_files_all.txt"
  [[ -f "$combined" ]] && rm -f "$combined"
  touch "$combined"
  # echo "hui hui hui hui after combined declaration"
  if [[ ! -d "$url_dir" ]]; then 
    echo "[!] No urls directory found. Run url_harvest first"
    return 1
  else 
    echo "[+] urls directory found"
  fi 

  for dir in "$url_dir"/*/; do 
    [[ ! -d "$dir" ]] && continue
    local hostname="$(basename "$dir")"
    local input="$dir/all_urls.txt"
    local output="$dir/js_files.txt"

    # echo "----------Debug-------------"
    # echo "$hostname, $input, $output"

    if [[ ! -f "$input" ]]; then 
      echo "  [-] skipping $hostname. No urls file found"
      continue
    fi 

    rg '\.js' "$input" | sort -u > "$output"
    
    local count=$(wc -l < "$output")
      
    if [[ $count -gt 0 ]]; then 
      cat "$output" >> "$combined"
      echo "[+] $hostname - $count js files"
    else 
      echo "[-] $hostname - no js files found"
    fi 
  done

  sort -u -o "$combined" "$combined"
  echo ""
  echo "[+] Per-host: .urls/<hostname>/js_files.txt"
  echo "[+] Combined: $combined ($(wc -l < "$combined") unique)"


}
