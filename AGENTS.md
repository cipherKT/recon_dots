# Agent Setup Guide for recon_dots

## Philosophy & Core Principles

- Lightweight automation, not one-click pipelines
- Output always goes to `$PWD` — you control the directory structure (no auto-created target trees)
- Manual analysis stays central to the workflow
- Amass intentionally removed from subs (too slow, poor yield)

## Setup

- Run `chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh` to install dotfiles
- After bootstrap, run `source ~/.zshrc` to load the new environment
- Secrets file `~/.config/zsh/secrets.zsh` must be populated with API tokens (GITHUB_TOKEN, SHODAN_SECRET, PDTM_API)

## Recon Workflow (Critical)

- All recon tools output to **current directory** (`$PWD`) — never assume domain-relative paths
- Standard workflow:

  ```bash
  mkdir -p ~/BugBounty/targets/example.com/recon
  cd ~/BugBounty/targets/example.com/recon
  ```

- Then run tools like `subs example.com`, `hx passive/all_subs.txt`, etc.

## Wrapper Commands & Exact Patterns

### `subs` — Subdomain Enumeration

```bash
subs target.com
```

Output: `./passive/{subfinder,assetfinder,crtsh,github,all_subs}.txt`
Requires: `$GITHUB_TOKEN` in secrets.zsh
Dependencies: subfinder, assetfinder, jq, anew, github-subdomains, curl

### `hx` — HTTP Probing

```bash
hx passive/all_subs.txt
```

Output: `./live/httpx.txt` (full) and `./live/httpx_simple.txt` (URLs only)
Dependencies: httpx, anew

### `kat` — Katana Crawl

```bash
kat live/httpx_simple.txt     # file input
kat https://sub.target.com    # single URL
```

Output: `./katana.txt`
Dependencies: katana

### `url_harvest` — Full URL Collection

```bash
url_harvest live/httpx_simple.txt   # file with one host per line
url_harvest https://sub.target.com  # single host
```

Output per host: `./<hostname>/{katana,gau,waymore,waybackurls,all_urls}.txt`
Dependencies: katana, gau, waymore, waybackurls, anew

### `ffm` — FFUF Directory Bruteforce

```bash
ffm https://target.com
```

Uses `$WL_DIRB`, filters all status codes except 404
Dependencies: ffuf

## Tool Dependencies

- Install via pdtm (ProjectDiscovery Tool Manager) or manually:
  subfinder, assetfinder, httpx, katana, gau, waymore, waybackurls, ffuf, anew, jq, github-subdomains
- Wordlists auto-cloned to `~/BugBounty/wordlists/` during bootstrap

## Environment & Configuration

### Key Files

- zsh modules: `aliases.zsh`, `exports.zsh`, `functions.zsh`, `paths.zsh`, `recon.zsh`
- Main zshrc: `scripts/zshrc` (copied to `~/.zshrc`)
- Secrets template: `zsh/secrets.example.zsh` → `~/.config/zsh/secrets.zsh`

### Wordlist Environment Variables (from exports.zsh)

```bash
$WL_COMMON    # common.txt
$WL_DIRB      # directory-list-2.3-medium.txt
$WL_RAFT      # raft-medium-directories.txt
$WL_PARAMS    # burp-parameter-names.txt
```

### Secrets File Format (~/.config/zsh/secrets.zsh)

```bash
export GITHUB_TOKEN=""
export SHODAN_SECRET=""
export PDTM_API=""
```

- File must be chmod 600
- Never tracked in git
- Bootstrap creates from example only if missing

## Bootstrap Behavior

- Symlinks `zsh/*.zsh` → `~/.config/zsh/`
- Copies `scripts/zshrc` → `~/.zshrc` (always overwrites)
- Installs zsh-autosuggestions and zsh-syntax-highlighting oh-my-zsh plugins if missing
- Creates `~/.config/zsh/secrets.zsh` from example only if it doesn't exist
- Clones SecLists, jeanphorn, orwa into `~/BugBounty/wordlists/` with `--depth 1`

## Extension Guidelines

**Adding a new recon wrapper**: Add to `zsh/recon.zsh` following existing pattern — local vars, dependency check, `$PWD`-relative output, clear echo output.

**Adding a new wordlist var**: Add to `exports.zsh` under wordlists section.

**Adding a new tool to bootstrap**: Add `--depth 1` git clone under wordlists section or dependency install under plugins section.

**Updating PATH**: Edit `paths.zsh` only — never modify `.zshrc` or other files directly.
