# ─── curlall ──────────────────────────────────────────────────────────────────
# Usage: curlall <urls_file> [-o <output_file>] [-v | -vv] [curl_options]
_curlall_draw_progress() {
    [[ $progress_enabled -eq 1 ]] || return 0
    local filled=0 bar="" i
    if [[ $total -gt 0 && $done -gt 0 ]]; then
        filled=$(( (done * bar_width + total - 1) / total ))
    fi
    for (( i = 1; i <= bar_width; i++ )); do
        (( i <= filled )) && bar+="." || bar+=" "
    done
    print -u 2 -n -- $'\r\e[2K'"[$bar] [$done/$total] done"
}

_curlall_emit() {
    local line="$1"
    [[ -n "$output" ]] && print -r -- "$line" >> "$output"
    [[ $progress_enabled -eq 1 ]] && print -u 2 -n -- $'\r\e[2K'
    print -r -- "$line"
    _curlall_draw_progress
}

curlall() {
    local input="$1"
    if [[ -z "$input" || "$input" == "-h" || "$input" == "--help" ]]; then
        echo "Usage: curlall <urls_file> [-o <output_file>] [-v | -vv] [curl_options]"
        echo "  -o FILE  Save terminal results to FILE and display them"
        echo "  -v       Print response headers to the terminal"
        echo "  -vv      Write request/response headers and body to curlall_output.md"
        return 0
    fi
    [[ -f "$input" ]] || { echo "[!] File not found: $input"; return 1; }
    command -v curl &>/dev/null || { echo "[!] curl is not installed"; return 1; }

    shift
    local curl_args=() output="" verbose_mode=0 arg
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -vv) verbose_mode=2 ;;
            -v) verbose_mode=1 ;;
            -o)
                [[ $# -ge 2 ]] || { echo "[!] -o requires an output file"; return 1; }
                output="$2"; shift
                ;;
            -o?*) output="${1#-o}" ;;
            *) curl_args+=("$1") ;;
        esac
        shift
    done
    if [[ -n "$output" && "$output" == "$input" ]]; then
        echo "[!] Output file must be different from the input file"; return 1
    fi
    if [[ -n "$output" ]]; then
        : > "$output" || { echo "[!] Cannot write output file: $output"; return 1; }
    fi

    local req_body=""
    if [[ $verbose_mode -eq 2 ]]; then
        local i=1
        while [[ $i -le ${#curl_args[@]} ]]; do
            arg="${curl_args[i]}"
            if [[ "$arg" == "-d" || "$arg" == "--data" || "$arg" == "--data-raw" || "$arg" == "--data-binary" || "$arg" == "--data-urlencode" || "$arg" == "--data-ascii" || "$arg" == "--json" ]]; then
                [[ $((i + 1)) -le ${#curl_args[@]} ]] && req_body="${curl_args[i+1]}"; break
            elif [[ "$arg" =~ ^-d.+ ]]; then req_body="${arg#-d}"; break
            fi
            (( i += 1 ))
        done
    fi
    local md_file="curlall_output.md"
    if [[ $verbose_mode -eq 2 ]]; then
        : > "$md_file"
        print "# Curlall Request & Response Report" > "$md_file"
        print "Generated on: $(date)" >> "$md_file"
        print >> "$md_file"
    fi

    local url status_code redirect_url info curl_exit
    local total=0 done=0 progress_enabled=0 bar_width=30
    while IFS= read -r url || [[ -n "$url" ]]; do
        url="${url#"${url%%[![:space:]]*}"}"
        url="${url%"${url##*[![:space:]]}"}"
        [[ -n "$url" ]] && (( total += 1 ))
    done < "$input"
    [[ -t 2 ]] && progress_enabled=1
    _curlall_draw_progress

    while IFS= read -r url || [[ -n "$url" ]]; do
        url="${url#"${url%%[![:space:]]*}"}"
        url="${url%"${url##*[![:space:]]}"}"
        [[ -z "$url" ]] && continue
        if [[ ! "$url" =~ ^https?:// ]]; then
            _curlall_emit "[INVALID] $url"
            (( done += 1 ))
            _curlall_draw_progress
            continue
        fi

        local body_file="$(mktemp)" trace_file="$(mktemp)"
        info=$(curl -s -S -v -o "$body_file" -w "%{http_code}\n%{redirect_url}" "${curl_args[@]}" "$url" 2> "$trace_file")
        curl_exit=$?
        if [[ $curl_exit -eq 0 ]]; then
            status_code="${info%%$'\n'*}"; redirect_url="${info#*$'\n'}"
        else status_code="ERR"; redirect_url=""; fi
        if [[ "$status_code" == "ERR" ]]; then
            _curlall_emit "[ERR] $url"
        elif [[ -n "$redirect_url" && "$status_code" =~ ^3[0-9][0-9]$ ]]; then
            _curlall_emit "[$status_code] $url -> $redirect_url"
        else _curlall_emit "[$status_code] $url"; fi

        if [[ $verbose_mode -eq 1 && "$status_code" != "ERR" ]]; then
            _curlall_emit "Headers:"
            while IFS= read -r arg; do
                [[ "$arg" == '< '* ]] && _curlall_emit "${arg#< }"
            done < "$trace_file"
            _curlall_emit ""
        fi
        if [[ $verbose_mode -eq 2 ]]; then
            local req_headers resp_headers req_content resp_content body_size
            req_headers=$(sed -n 's/^> //p' "$trace_file")
            resp_headers=$(sed -n 's/^< //p' "$trace_file")
            req_content="$req_headers"; [[ -n "$req_body" ]] && req_content="$req_content"$'\n\n'"$req_body"
            resp_content="$resp_headers"; body_size=$(wc -c < "$body_file")
            if [[ $body_size -gt 0 ]]; then
                if grep -qI . "$body_file" && [[ $body_size -le 50000 ]]; then
                    resp_content="$resp_content"$'\n\n'"$(< "$body_file")"
                elif [[ $body_size -gt 50000 ]]; then
                    resp_content="$resp_content"$'\n\n[Response body too large: '"$body_size"' bytes]'
                else resp_content="$resp_content"$'\n\n[Binary data: '"$body_size"' bytes]'; fi
            fi
            {
                print "## $url"; print; print "### Request"; print '```http'; print -r -- "$req_content"; print '```'; print
                print "### Response"; print '```http'; print -r -- "$resp_content"; print '```'; print
            } >> "$md_file"
        fi
        rm -f "$body_file" "$trace_file"
        (( done += 1 )); _curlall_draw_progress
    done < "$input"
    [[ $progress_enabled -eq 1 ]] && print -u 2
    [[ -n "$output" ]] && print "[+] Results saved to: $output" >&2
    [[ $verbose_mode -eq 2 ]] && print "[+] Markdown report saved to $md_file"
}
