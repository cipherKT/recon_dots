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
            -d 3 \
            -o "$output"
    else
        katana \
            -u "$input" \
            -silent \
            -jc \
            -kf all \
            -d 3 \
            -o "$output"
    fi

    echo "[+] Output: $output"
}
