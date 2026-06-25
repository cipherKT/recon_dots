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
