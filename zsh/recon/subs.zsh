# ─── subs ─────────────────────────────────────────────────────────────────────
# Usage: subs target.com '*.target.com' api.target.com ...
# Output: ./passive/<domain>.txt per domain + ./passive/all_subs.txt (merged)
subs() {
    if [[ $# -eq 0 ]]; then
        echo "[!] Usage: subs domain1 domain2 ...  (wildcards like *.domain accepted)"
        return 1
    fi

    if ! command -v subfaster &>/dev/null; then
        echo "[!] Missing dependency: subfaster"
        return 1
    fi

    local base="$(pwd)/passive"
    mkdir -p "$base"

    local domain d out
    for domain in "$@"; do
        d="${domain#\*.}"   # strip leading *. wildcard
        out="$base/$d.txt"
        echo "[+] Running subfaster on $d"
        subfaster -d "$d" -silent -all -recursive -o "$out"
    done

    echo "[+] Combining results"
    local f
    local -a files=()
    for f in "$base"/*.txt; do
        [[ "$(basename "$f")" == "all_subs.txt" ]] && continue
        files+=("$f")
    done
    cat "${files[@]}" | sort -u | anew "$base/all_subs.txt"

    echo "[+] Done — $(wc -l < "$base/all_subs.txt") unique subs"
    echo "[+] Output: $base/all_subs.txt"
}
