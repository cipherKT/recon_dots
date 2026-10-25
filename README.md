# recon_dots

Reusable zsh recon scripts. This repository manages recon wrappers and their
dependency installer only; your shell configuration stays yours.

## Setup

```bash
bash scripts/bootstrap.sh
```

Bootstrap links `zsh/recon.zsh` into
`${XDG_CONFIG_HOME:-$HOME/.config}/recon-dots/recon.zsh` and prints the exact
`source` line to add to your existing `~/.zshrc`. It does not edit your shell
startup files, install plugins, clone wordlists, or manage secrets.
Keep this checkout in place because the loader is symlinked to it.
You can also source `zsh/recon.zsh` directly without bootstrap.

Install or inspect dependencies separately:

```bash
bash scripts/install-recon-tools.sh --check-only
bash scripts/install-recon-tools.sh
```

The installer supports `--upgrade` and `-y`. Ensure `~/go/bin`,
`~/.pdtm/go/bin`, and `~/.local/bin` are on your existing shell PATH
(or the appropriate Go bin directory if you customize Go's installation).
It installs `urldedupe` as a command in `~/.local/bin`; no alias is required.
Its source/build directory defaults to `~/security/BugBounty/tools/urldedupe`
and can be overridden with `URLDEDUPE_DIR`.

Provide `GITHUB_TOKEN` through your own environment or secrets setup to enable
the GitHub source in `subs`. No tokens are stored or sourced by this repository.

## Kali Linux

Kali is supported through the installer's Debian/apt package mapping. The
wrappers require **zsh**, even if your login shell is Bash. The installer
includes zsh for minimal installations and uses pipx for waymore, following
[Kali's Python application guidance](https://www.kali.org/docs/general-use/python3-external-packages/).
It does not bypass the system Python environment protections.

Run setup as your normal user so Go and pipx tools belong to that user:

```bash
bash scripts/install-recon-tools.sh
bash scripts/bootstrap.sh
zsh
```

Run the source line printed by bootstrap in zsh and add it to your existing
`~/.zshrc` for future terminals. Add the tool directories to your own PATH if
needed, placing Go tools before system commands to avoid unrelated binaries
with the same name (especially Python's `httpx`):

```zsh
export PATH="$HOME/go/bin:$HOME/.pdtm/go/bin:$HOME/.local/bin:$PATH"
```

System packages use sudo for ordinary users; root environments call the package
manager directly. Running the whole installer as root installs user tools for
root. No Kali theme, prompt, aliases, or startup configuration is replaced.

## Migrating an older installation

Older bootstrap versions replaced `~/.zshrc` and linked general shell modules
into `~/.config/zsh`. This bootstrap leaves those existing files alone.
Before switching, copy any personal settings you want to retain out of the
old repo-linked modules, remove their obsolete links/source entries, and add
the new loader's source line. Existing secrets remain yours to manage.
The old `install-recon` alias is replaced by the explicit installer command above.

## Structure

- `zsh/recon/*.zsh`: recon wrappers, one per file.
- `zsh/recon.zsh`: loads wrappers without changing aliases, PATH, or shell preferences.
- `scripts/bootstrap.sh`: links the recon loader.
- `scripts/install-recon-tools.sh`: installs recon tool dependencies.

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

Runs subfaster, subfinder, assetfinder, crt.sh, and github-subdomains for each
domain. Missing tools are skipped; crt.sh is best effort because the service
can be unavailable.

```bash
subs target.com
```

Output:

```text
./passive/target.com.txt       ← merged result for the domain
./passive/target.com/          ← raw output from each source
./passive/all_subs.txt         ← deduplicated across all domains
```

Dependencies: `subfaster`, `subfinder`, `assetfinder`, `jq`, `github-subdomains`, `curl`
`github-subdomains` uses `$GITHUB_TOKEN` when it is set.

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

### `url_harvest` — URL Collection (No Katana)

Skips katana entirely — for data-heavy targets where crawling millions of static assets wastes time.

```bash
url_harvest live/httpx_simple.txt   # file with one host per line
url_harvest https://sub.target.com  # single host
```

Output per host:

```text
./urls/<hostname>/gau.txt
./urls/<hostname>/waymore.txt
./urls/<hostname>/waybackurls.txt
./urls/<hostname>/all_urls.txt      ← deduplicated per host
```

For file input, also creates a combined, deduplicated `./all_urls.txt` in the recon root via `urldedupe`.
When a **single URL** is passed, the tools run concurrently flat into `$PWD` — `./gau.txt`, `./waymore.txt`, `./waybackurls.txt`, `./all_urls.txt` with no `urls/` dir (and `-t` is ignored).

Dependencies: `gau`, `waymore`, `waybackurls`, `anew`, `urldedupe`

---

### `url_harvest_katana` — Full URL Collection

Runs katana, gau, waymore, and waybackurls per host. Creates a subdirectory per hostname and deduplicates all results into `all_urls.txt`.

```bash
url_harvest_katana live/httpx_simple.txt   # file with one host per line
url_harvest_katana https://sub.target.com  # single host
```

Output per host:

```text
./urls/<hostname>/katana.txt
./urls/<hostname>/gau.txt
./urls/<hostname>/waymore.txt
./urls/<hostname>/waybackurls.txt
./urls/<hostname>/all_urls.txt      ← deduplicated per host
```

For file input, also creates a combined, deduplicated `./all_urls.txt` in the recon root via `urldedupe`.
When a **single URL** is passed, the tools run concurrently flat into `$PWD` — `./katana.txt`, `./gau.txt`, `./waymore.txt`, `./waybackurls.txt`, `./all_urls.txt` with no `urls/` dir (and `-t` is ignored).

Dependencies: `katana`, `gau`, `waymore`, `waybackurls`, `anew`, `urldedupe`

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

## Philosophy

- Lightweight automation, with manual analysis central to the workflow.
- Output is rooted in `$PWD`; callers choose their own target directory structure.
- No general aliases, desktop settings, shell frameworks, or personal environment configuration.
