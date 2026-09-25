# ─── url_harvest ──────────────────────────────────────────────────────────────
# Usage: url_harvest [-t threads] <file.txt|url>
# File: one host per line (https://sub.target.com or sub.target.com)
# Output (file input): ./urls/<hostname>/{gau,waymore,waybackurls,all_urls}.txt + combined ./all_urls.txt
# Output (single URL): ./gau.txt, ./waymore.txt, ./waybackurls.txt, ./all_urls.txt in $PWD (no urls/ dir)
# Skips Katana — for data-heavy targets where crawling would waste time.
# Tools run in parallel per host; hosts run in parallel up to -t (default 3, max 15).
# Single URL: tools run concurrently flat into $PWD; -t is ignored.
url_harvest() {
    # ── parse flags ──
    local max_threads=3
    while [[ "$1" == -* ]]; do
        case "$1" in
            -t) max_threads="$2"; shift 2 ;;
            *)  echo "[!] Unknown flag: $1"; return 1 ;;
        esac
    done

    # hard cap to prevent system freeze
    if (( max_threads > 15 )); then
        echo "[!] Capping threads to 15 (requested $max_threads)"
        max_threads=15
    fi

    local input="$1"

    if [[ -z "$input" ]]; then
        echo "[!] Usage: url_harvest [-t threads] <file.txt|url>"
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
    local single_input=0
    if [[ -f "$input" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            hosts+=("$line")
        done < "$input"
    else
        hosts+=("$input")
        single_input=1
    fi

    local total=${#hosts[@]}
    if (( single_input )); then
        echo "[+] url_harvest — single URL (all tools run concurrently)"
    else
        echo "[+] url_harvest — $total host(s), $max_threads thread(s)"
        echo "[+] Max concurrent processes: $((max_threads * 3)) (${max_threads} hosts × 3 tools)"
    fi

    # strip scheme / trailing slash — clean hostname used as dir name
    _url_harvest_hostname() {
        local hostname="${1#https://}"
        hostname="${hostname#http://}"
        hostname="${hostname%/}"
        echo "$hostname"
    }

    # ── worker: runs all tools in parallel for a single host ──
    _url_harvest_worker() {
        local host="$1"
        local hostname="$(_url_harvest_hostname "$host")"

        local base="$(pwd)/urls/$hostname"
        mkdir -p "$base"

        # run tools in parallel — each writes to its own file
        gau "$hostname" --o "$base/gau.txt"                             > /dev/null 2>&1 &
        waymore -i "$hostname" -mode U -oU "$base/waymore.txt"          > /dev/null 2>&1 &
        (waybackurls "$hostname" -no-subs | anew "$base/waybackurls.txt") > /dev/null 2>&1 &
        wait

        # merge after all tools finish
        cat "$base/gau.txt" \
            "$base/waymore.txt" \
            "$base/waybackurls.txt" \
            2>/dev/null \
            | sort -u \
            | anew "$base/all_urls.txt"

        local count=$(wc -l < "$base/all_urls.txt" 2>/dev/null || echo 0)
        echo "  [✓] $hostname — $count unique URLs"
    }

    # ── single URL: flat output in $PWD — no urls/ dir ──
    # Individual tool files + combined ./all_urls.txt live in the current directory.
    if (( single_input )); then
        local host="${hosts[1]}"
        local hostname="$(_url_harvest_hostname "$host")"

        local base="$(pwd)"

        # run tools in parallel — each writes to its own file in $PWD
        gau "$hostname" --o "$base/gau.txt"                             > /dev/null 2>&1 &
        waymore -i "$hostname" -mode U -oU "$base/waymore.txt"          > /dev/null 2>&1 &
        (waybackurls "$hostname" -no-subs | anew "$base/waybackurls.txt") > /dev/null 2>&1 &
        wait

        # combine into ./all_urls.txt
        cat "$base/gau.txt" \
            "$base/waymore.txt" \
            "$base/waybackurls.txt" \
            2>/dev/null \
            | sort -u \
            | anew "$base/all_urls.txt"

        local count=$(wc -l < "$base/all_urls.txt" 2>/dev/null || echo 0)
        echo "  [✓] $hostname — $count unique URLs"
        echo ""
        echo "[+] Output: $(pwd)/all_urls.txt"
        return 0
    fi

    # ── thread pool (zsh-compatible: no wait -n) ──
    # Track worker PIDs in an array; when full, wait for the oldest to finish.
    local worker_pids=()

    for host in "${hosts[@]}"; do
        if (( ${#worker_pids[@]} >= max_threads )); then
            # wait for the oldest worker to finish, then drop it from the queue
            wait "${worker_pids[1]}"
            worker_pids=("${worker_pids[@]:1}")
        fi

        _url_harvest_worker "$host" &
        worker_pids+=($!)
    done

    wait    # drain remaining workers

    echo ""
    echo "[+] Creating combined deduplicated all_urls.txt via urldedupe"
    cat "$(pwd)/urls/"*/all_urls.txt 2>/dev/null \
        | urldedupe \
        | anew "$(pwd)/all_urls.txt"
    echo "[+] Combined: $(pwd)/all_urls.txt ($(wc -l < "$(pwd)/all_urls.txt") unique)"
}
