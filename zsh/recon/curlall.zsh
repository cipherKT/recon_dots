# ─── curlall ──────────────────────────────────────────────────────────────────
# Usage: curlall <urls_file> [curl_options] [-v | -vv]
# Output: terminal summary and optionally curlall_output.md
curlall() {
    local input="$1"
    if [[ -z "$input" || "$input" == "-h" || "$input" == "--help" ]]; then
        echo "Usage: curlall <urls_file> [curl_options] [-v | -vv]"
        echo "Options:"
        echo "  -v    Verbose mode: print response headers to terminal"
        echo "  -vv   Very verbose: write request/response headers and body to curlall_output.md"
        return 0
    fi

    if [[ ! -f "$input" ]]; then
        echo "[!] File not found: $input"
        return 1
    fi

    if ! command -v curl &>/dev/null; then
        echo "[!] curl is not installed"
        return 1
    fi

    # Shift input file out
    shift

    # Parse remaining arguments to extract -v and -vv, and separate curl flags
    local curl_args=()
    local verbose_mode=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -vv)
                verbose_mode=2
                ;;
            -v)
                verbose_mode=1
                ;;
            *)
                curl_args+=("$1")
                ;;
        esac
        shift
    done

    # Extract request body payload from curl arguments if verbose_mode is 2
    local req_body=""
    if [[ $verbose_mode -eq 2 ]]; then
        local i=1
        while [[ $i -le ${#curl_args[@]} ]]; do
            local arg="${curl_args[i]}"
            if [[ "$arg" == "-d" || "$arg" == "--data" || "$arg" == "--data-raw" || "$arg" == "--data-binary" || "$arg" == "--data-urlencode" || "$arg" == "--data-ascii" || "$arg" == "--json" ]]; then
                if [[ $((i + 1)) -le ${#curl_args[@]} ]]; then
                    req_body="${curl_args[i+1]}"
                fi
                break
            elif [[ "$arg" =~ ^-d.+ ]]; then
                req_body="${arg#-d}"
                break
            fi
            ((i++))
        done
    fi

    # Prepare markdown output file if needed
    local md_file="curlall_output.md"
    if [[ $verbose_mode -eq 2 ]]; then
        : > "$md_file"
        echo "# Curlall Request & Response Report" >> "$md_file"
        echo "Generated on: $(date)" >> "$md_file"
        echo "" >> "$md_file"
    fi

    # Read URLs and process them sequentially
    while IFS= read -r url || [[ -n "$url" ]]; do
        # Trim leading and trailing whitespace
        url="${url#"${url%%[![:space:]]*}"}"
        url="${url%"${url##*[![:space:]]}"}"
        if [[ -z "$url" ]]; then
            continue
        fi

        # Basic URL prefix validation
        if [[ ! "$url" =~ ^https?:// ]]; then
            echo "[INVALID] $url"
            continue
        fi

        # Temp files to capture curl output
        local body_file=$(mktemp)
        local trace_file=$(mktemp)

        # Run curl
        local info
        info=$(curl -s -S -v -o "$body_file" -w "%{http_code}\n%{redirect_url}" "${curl_args[@]}" "$url" 2> "$trace_file")
        local curl_exit=$?

        local status_code
        local redirect_url
        if [[ $curl_exit -eq 0 ]]; then
            status_code=$(echo "$info" | head -n 1)
            redirect_url=$(echo "$info" | tail -n 1)
        else
            status_code="ERR"
            redirect_url=""
        fi

        # Print terminal summary
        if [[ "$status_code" == "ERR" ]]; then
            echo "[ERR] $url"
        elif [[ -n "$redirect_url" && "$status_code" =~ ^3[0-9][0-9]$ ]]; then
            echo "[$status_code] $url -> $redirect_url"
        else
            echo "[$status_code] $url"
        fi

        # If verbose_mode is 1, print response headers to terminal
        if [[ $verbose_mode -eq 1 && "$status_code" != "ERR" ]]; then
            local resp_headers=$(grep '^< ' "$trace_file" | sed 's/^< //')
            echo "Headers:"
            echo "$resp_headers"
            echo ""
        fi

        # If verbose_mode is 2, write request and response details to markdown file
        if [[ $verbose_mode -eq 2 ]]; then
            local req_headers=$(grep '^> ' "$trace_file" | sed 's/^> //')
            local resp_headers=$(grep '^< ' "$trace_file" | sed 's/^< //')

            # Prepare request content
            local req_content="$req_headers"
            if [[ -n "$req_body" ]]; then
                req_content="$req_content"$'\n\n'"$req_body"
            fi

            # Prepare response content
            local resp_content="$resp_headers"
            if [[ -f "$body_file" ]]; then
                local body_size=$(wc -c < "$body_file")
                if [[ $body_size -gt 0 ]]; then
                    if grep -qI . "$body_file" && [[ $body_size -le 50000 ]]; then
                        resp_content="$resp_content"$'\n\n'"$(cat "$body_file")"
                    elif [[ $body_size -gt 50000 ]]; then
                        resp_content="$resp_content"$'\n\n'"[Response body too large: $body_size bytes]"
                    else
                        resp_content="$resp_content"$'\n\n'"[Binary data: $body_size bytes]"
                    fi
                fi
            fi

            {
                printf "## %s\n\n" "$url"
                printf "### Request\n"
                printf "\`\`\`http\n"
                printf "%s\n" "$req_content"
                printf "\`\`\`\n\n"
                printf "### Response\n"
                printf "\`\`\`http\n"
                printf "%s\n" "$resp_content"
                printf "\`\`\`\n\n"
            } >> "$md_file"
        fi

        # Clean up temp files
        rm -f "$body_file" "$trace_file"
    done < "$input"

    if [[ $verbose_mode -eq 2 ]]; then
        echo "[+] Markdown report saved to $md_file"
    fi
}
