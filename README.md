# recon_dots

Personal recon and bug bounty environment for Arch Linux / Omarchy.
Modular zsh configuration with reusable recon wrappers, portable environment variables, and a one-shot bootstrap.

---

## Structure

```text
.
├── README.md
├── scripts/
│   ├── bootstrap.sh
│   └── zshrc
└── zsh/
    ├── aliases.zsh
    ├── exports.zsh
    ├── functions.zsh
    ├── paths.zsh
    ├── recon.zsh
    └── secrets.example.zsh
```

---

## Bootstrap

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This will:
- Symlink all `zsh/*.zsh` files to `~/.config/zsh/`
- Copy `scripts/zshrc` to `~/.zshrc`
- Install `zsh-autosuggestions` and `zsh-syntax-highlighting` oh-my-zsh plugins
- Create `~/.config/zsh/secrets.zsh` from the example if it doesn't exist
- Clone SecLists, jeanphorn, and orwa wordlists into `~/BugBounty/wordlists/`

---

## ZSH Modules

| File | Purpose |
| --- | --- |
| `aliases.zsh` | Shell aliases and oh-my-zsh conflict unaliases |
| `exports.zsh` | Environment variables and wordlist paths |
| `functions.zsh` | Generic helper functions |
| `paths.zsh` | PATH configuration |
| `recon.zsh` | Recon and bug bounty wrappers |
| `secrets.zsh` | API tokens — not tracked, lives only in `~/.config/zsh/` |

---

## Wordlists

Wordlists live at `~/BugBounty/wordlists/`. Configured in `exports.zsh`:

```bash
$WL_COMMON    # common.txt
$WL_DIRB      # directory-list-2.3-medium.txt
$WL_RAFT      # raft-medium-directories.txt
$WL_PARAMS    # burp-parameter-names.txt
```

---

## Recon Wrappers

All wrappers output to the **current directory**. The expected workflow is:

```text
~/BugBounty/targets/target.com/
└── recon/              ← cd here and run everything
    ├── passive/
    ├── live/
    └── urls/
```

---

### `subs` — Subdomain Enumeration

Runs subfinder, assetfinder, crt.sh, and github-subdomains.

```bash
subs target.com
```

Output:
```text
./passive/subfinder.txt
./passive/assetfinder.txt
./passive/crtsh.txt
./passive/github.txt
./passive/all_subs.txt     ← deduplicated
```

Dependencies: `subfinder`, `assetfinder`, `jq`, `anew`, `github-subdomains`, `curl`
Requires: `$GITHUB_TOKEN` in secrets.zsh

---

### `hx` — HTTP Probing

Runs httpx with full fingerprinting — status code, title, tech detection, content length, CDN, CNAME, IP, redirects.
Also outputs a clean URL-only file for piping into other tools.

```bash
hx passive/all_subs.txt
```

Output:
```text
./live/httpx.txt           ← full httpx output
./live/httpx_simple.txt    ← URLs only (col 1)
```

Dependencies: `httpx`, `anew`

---

### `kat` — Katana Crawl

Accepts a file or a single URL.

```bash
kat live/httpx_simple.txt
kat https://sub.target.com
```

Output:
```text
./katana.txt
```

Dependencies: `katana`

---

### `url_harvest` — Full URL Collection

Runs katana, gau, waymore, and waybackurls per host. Creates a subdirectory per hostname and deduplicates all results into `all_urls.txt`.

```bash
url_harvest live/httpx_simple.txt   # file with one host per line
url_harvest https://sub.target.com  # single host
```

Output per host:
```text
./<hostname>/katana.txt
./<hostname>/gau.txt
./<hostname>/waymore.txt
./<hostname>/waybackurls.txt
./<hostname>/all_urls.txt           ← deduplicated
```

Dependencies: `katana`, `gau`, `waymore`, `waybackurls`, `anew`

---

### `ffm` — FFUF Directory Bruteforce

```bash
ffm https://target.com
```

Uses `$WL_DIRB`. Filters all status codes except 404.

Dependencies: `ffuf`

---

### `js_harvest` — Extract JS File URLs

Extracts JS/JSX/MJS/CJS file URLs from a list of URLs using `rg`.

```bash
js_harvest urls/target.com/all_urls.txt
```

Output: `./js_files.txt`

Dependencies: `rg` (ripgrep), `sort`

---

### `js_harvest_all` — Batch JS Harvest

Iterates over every hostdir under `./urls/`, runs `js_harvest` per host, and combines results.

```bash
js_harvest_all
```

Output: `./urls/<hostname>/js_files.txt` (per host) + `./js_files_all.txt` (combined, deduplicated)

Dependencies: `rg` (ripgrep), `sort`

---

## Secrets

Never tracked. Create manually or let bootstrap generate it from the example:

```text
~/.config/zsh/secrets.zsh
```

```bash
export GITHUB_TOKEN=""
export SHODAN_SECRET=""
export PDTM_API=""
```

---

## Dependencies

| Tool | Used in |
| --- | --- |
| `subfinder` | subs |
| `assetfinder` | subs |
| `httpx` | hx |
| `katana` | kat, url_harvest |
| `gau` | url_harvest |
| `waymore` | url_harvest |
| `waybackurls` | url_harvest |
| `ffuf` | ffm |
| `anew` | subs, hx, url_harvest |
| `jq` | subs |
| `github-subdomains` | subs |
| `rg` (ripgrep) | js_harvest, js_harvest_all |

Install most via [pdtm](https://github.com/projectdiscovery/pdtm).

---

## Philosophy

- Lightweight automation, not one-click pipelines
- Output always goes to `$PWD` — you control the directory structure
- Manual analysis stays central to the workflow
