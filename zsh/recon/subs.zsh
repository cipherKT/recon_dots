# ─── subs ─────────────────────────────────────────────────────────────────────
# Usage: subs target.com '*.target.com' api.target.com ...
# Output: ./passive/<domain>.txt per domain + ./passive/all_subs.txt (merged)
#         Raw tool output is kept in ./passive/<domain>/.
subs() {
    if [[ $# -eq 0 ]]; then
        echo "[!] Usage: subs domain1 domain2 ...  (wildcards like *.domain accepted)"
        return 1
    fi

    local base="$(pwd)/passive"
    mkdir -p "$base"

    local domain d out source_dir source_file crt_json
    local -a domain_outputs=()
    local ran_any=0
    for domain in "$@"; do
        d="${domain#\*.}"   # strip leading *. wildcard
        out="$base/$d.txt"
        source_dir="$base/$d"
        mkdir -p "$source_dir"
        : >| "$out"
        # Do not mix stale output into a later run where a tool is unavailable.
        : >| "$source_dir/subfaster.txt"
        : >| "$source_dir/subfinder.txt"
        : >| "$source_dir/assetfinder.txt"
        : >| "$source_dir/crtsh.txt"
        : >| "$source_dir/github.txt"

        if command -v subfaster &>/dev/null; then
            source_file="$source_dir/subfaster.txt"
            echo "[+] Running subfaster on $d"
            subfaster -d "$d" -silent -all -recursive -o "$source_file"
            ran_any=1
        else
            echo "[!] Missing dependency: subfaster (skipping)"
        fi

        if command -v subfinder &>/dev/null; then
            source_file="$source_dir/subfinder.txt"
            echo "[+] Running subfinder on $d"
            subfinder -d "$d" -silent -all -recursive -o "$source_file"
            ran_any=1
        else
            echo "[!] Missing dependency: subfinder (skipping)"
        fi

        if command -v assetfinder &>/dev/null; then
            source_file="$source_dir/assetfinder.txt"
            echo "[+] Running assetfinder on $d"
            assetfinder --subs-only "$d" | sort -u >| "$source_file"
            ran_any=1
        else
            echo "[!] Missing dependency: assetfinder (skipping)"
        fi

        if command -v curl &>/dev/null && command -v jq &>/dev/null; then
            source_file="$source_dir/crtsh.txt"
            crt_json="$source_dir/crtsh.json"
            echo "[+] Running crt.sh on $d (best effort)"
            if curl -fsSL --max-time 30 -A 'recon_dots subs' \
                "https://crt.sh/?q=%25.$d&output=json" -o "$crt_json" \
                && jq -r '.[].name_value // empty' "$crt_json" \
                    | sed 's/\*\.//g' | sort -u >| "$source_file"; then
                ran_any=1
            else
                echo "[!] crt.sh unavailable for $d (continuing)"
                : >| "$source_file"
            fi
            rm -f "$crt_json"
        else
            echo "[!] Missing dependency: curl and/or jq (skipping crt.sh)"
        fi

        if command -v github-subdomains &>/dev/null; then
            source_file="$source_dir/github.txt"
            if [[ -n "$GITHUB_TOKEN" ]]; then
                echo "[+] Running github-subdomains on $d"
                github-subdomains -d "$d" -t "$GITHUB_TOKEN" -o "$source_file"
                ran_any=1
            else
                echo "[!] GITHUB_TOKEN is not set (skipping github-subdomains)"
            fi
        else
            echo "[!] Missing dependency: github-subdomains (skipping)"
        fi

        # Keep the documented per-domain file as the clean, deduplicated input
        # for the next stage (hx), while retaining each source above.
        local -a source_files=()
        local f
        for f in "$source_dir"/*.txt; do
            [[ -f "$f" ]] && source_files+=("$f")
        done
        if (( ${#source_files[@]} )); then
            cat "${source_files[@]}" | sed '/^[[:space:]]*$/d' | sort -u >| "$out"
        fi
        domain_outputs+=("$out")
    done

    echo "[+] Combining results"
    if (( ! ran_any )); then
        echo "[!] No subdomain enumeration tool is available"
        return 1
    fi
    cat "${domain_outputs[@]}" | sort -u >| "$base/all_subs.txt"

    echo "[+] Done — $(wc -l < "$base/all_subs.txt") unique subs"
    echo "[+] Output: $base/all_subs.txt"
}
