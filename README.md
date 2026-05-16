
# Recon Dotfiles

Personal recon and bug bounty environment setup for WSL/Linux.

Modular zsh configuration with:
- reusable recon wrappers
- portable environment variables
- organized recon output structure
- bootstrap-based setup

---

# Structure

```text
dotfiles/
├── bootstrap.sh
├── zsh/
│   ├── aliases.zsh
│   ├── exports.zsh
│   ├── functions.zsh
│   ├── paths.zsh
│   ├── recon.zsh
│   └── secrets.example.zsh
├── scripts/
├── git/
└── README.md
````

---

# Features

## ZSH Modular Setup

Configuration is split into separate files instead of maintaining a bloated `.zshrc`.

### Included Modules

| File          | Purpose                       |
| ------------- | ----------------------------- |
| aliases.zsh   | Small shell aliases           |
| exports.zsh   | Environment variables         |
| functions.zsh | Generic helper functions      |
| paths.zsh     | PATH configuration            |
| recon.zsh     | Recon and bug bounty wrappers |

---

# Recon Wrappers

## Passive Enumeration

### `subs`

Runs:

* subfinder
* assetfinder
* amass (passive)
* crt.sh scraping
* github-subdomains

Example:

```bash
subs target.com
```

Output structure:

```text
target.com/
└── recon/
    └── passive/
```

---

## HTTP Probing

### `hx`

Runs `httpx` with:

* status code
* title
* tech detection
* content length
* CDN detection
* cname resolution
* redirects
* IP resolution

Example:

```bash
hx target.com/recon/passive/all_subs.txt
```

Output:

```text
target.com/recon/live/httpx.txt
```

---

## Katana Wrapper

### `kat`

Example:

```bash
kat target.com/recon/live/httpx.txt
```

---

## FFUF Shortcut

### `ffm`

Uses predefined medium wordlist.

Example:

```bash
ffm https://target.com
```

---

# Wordlists

Environment variables are used instead of hardcoded paths.

Examples:

```bash
$WL_COMMON
$WL_DIRB
$WL_RAFT
```

Configured in:

```text
zsh/exports.zsh
```

---

# Bootstrap Setup

Run:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This:

* creates zsh config structure
* creates symlinks
* clones wordlists
* prepares environment

---

# Secrets

Secrets are intentionally NOT tracked.

Create:

```text
~/.config/zsh/secrets.zsh
```

Example:

```bash
export GITHUB_TOKEN="token"
export SHODAN_SECRET="key"
```

---

# Dependencies

Core tools currently used:

* subfinder
* assetfinder
* amass
* httpx
* katana
* ffuf
* anew
* jq
* github-subdomains

---

# Philosophy

The goal is:

* lightweight automation
* reproducible environment setup
* cleaner recon workflows
* less repetitive typing

This setup intentionally avoids over-automated “one-click recon” pipelines.
Manual analysis remains central to the workflow.
