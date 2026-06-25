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
