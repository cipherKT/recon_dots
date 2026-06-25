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
