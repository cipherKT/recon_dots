# Make dir and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Initialize obsidian workspace in the current directory
init_obsidian() {
    local target_name="$1"

    if [[ -z "$target_name" ]]; then
        echo "[!] Usage: init_obsidian <target-name>"
        return 1
    fi

    echo "[*] Initializing obsidian workspace for $target_name in $PWD"

    # Create notes directory and copy .obsidian
    mkdir -p "$target_name"_notes
    if [[ -d "$HOME/BugBounty/main_notes/.obsidian" ]]; then
        cp -r "$HOME/BugBounty/main_notes/.obsidian" "$target_name"_notes/
    else
        echo "[!] Error: $HOME/BugBounty/main_notes/.obsidian not found."
        return 1
    fi

    # Create required directories
    mkdir -p "$target_name"_notes/01_Templates "$target_name"_notes/02_Attachments

    # Copy templates
    local templates_dir="$HOME/BugBounty/main_notes/01 Templates"

    for tmpl in "Target Template.md" "Sub Target Template.md"; do
        if [[ -f "$templates_dir/$tmpl" ]]; then
            cp "$templates_dir/$tmpl" "$target_name"_notes/01_Templates/
            sed -i "s/  - target/  - target\n  - ${target_name}/" "$target_name"_notes/01_Templates/"$tmpl"
        else
            echo "[!] Warning: $templates_dir/$tmpl not found."
        fi
    done

    echo "[+] Obsidian workspace initialized successfully."
}
