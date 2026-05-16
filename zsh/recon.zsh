subs() {
    domain="$1"

    if [[ -z "$domain" ]]; then
        echo "[!] Usage: subs target.com"
        return 1
    fi

    # dependency checks
    tools=(
        subfinder
        assetfinder
        amass
        jq
        anew
        github-subdomains
        curl
    )
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            echo "[!] Missing dependecy: $tool"
            return 1
        fi
    done

    # Check for github token
    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo "[!] GITHUB_TOKEN is not set"
        return 1
    fi

    base="$(pwd)/$domain/recon/passive"
    mkdir -p "$base"

    echo "[+] Running subfinder"

    subfinder -d "$domain" \
    -silent \
    -all \
    -recursive \
    -o "$base/subfinder.txt"

    echo "[+] Running assetfinder"
    assetfinder --subs-only "$domain" \
    | anew "$base/assetfinder.txt"

    echo "[+] Running amass passive"
    amass enum -passive \
    -d "$domain" \
    -o "$base/amass.txt"

    echo "[+] Running crt.sh"
    curl -s "https://crt.sh/?q=%25.$domain&output=json" \
    | jq -r '.[].name_value' \
    | sed 's/\*\.//g' \
    | anew "$base/crtsh.txt"

    echo "[+] Running github-subdomains"
    github-subdomains \
    -d "$domain" \
    -t "$GITHUB_TOKEN" \
    -o "$base/github.txt"

    echo "[+] Combining results"

    cat "$base"/*.txt \
    | sort -u \
    | anew "$base/all_subs.txt"

    echo "[+] Enumeration complete"
    echo "[+] Total unique subs: $(wc -l < "$base/all_subs.txt")"
    echo "[+] Output saved to:"
    echo "    $base/all_subs.txt"

}


hx() {
    input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: hx subdomains.txt"
        return 1
    fi

    if [[ ! -f "$input" ]]; then
        echo "[!] File not found: $input"
        return 1
    fi

    if ! command -v httpx >/dev/null 2>&1; then
        echo "[!] httpx not installed"
        return 1
    fi

    base="$(dirname "$input")/../live"

    mkdir -p "$base"

    output="$base/httpx.txt"

    echo "[*] Running htppx"

    httpx \
        -l "$input" \
        -silent \
        -follow-redirects \
        -sc \
        -cl \
        -ct \
        -location \
        -wc \
        -title \
        -server \
        -tech-detect \
        -ip \
        -cname \
        -cdn \
        -threads 100 \
        -rate-limit 200 \
        -timeout 10 \
        -retries 2 \
        -o "$output"

    echo "[+] Output saved: "
    echo "      $output"

    echo "[+] Total live hosts:"
    wc -l < "$output"
}

ffm() {
    url="${1%/}"
    ffuf \
        -u "$url/FUZZ" \
        -w "$WL_DIRB" \
        -mc all \
        -fc 404
}

kat() {
    input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: kat live_subdomains.txt"
        return 1
    fi

    output="${input%.txt}_katana.txt"

    katana \
        -list "$input" \
        -silent \
        -jc \
        -kf all \
        -d 5 \
        -o "$output"

    echo "[+] Output: $output"
}
