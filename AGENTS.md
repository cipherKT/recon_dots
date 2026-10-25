# Agent Setup Guide for recon_dots

## Scope

This repository contains recon wrappers and their setup scripts only. Do not add
personal aliases, general exports, desktop configuration, shell frameworks, or
a replacement zshrc. Keep manual analysis central; avoid one-click pipelines.
Amass is intentionally excluded from subs (slow, poor yield).

## Setup

- Run `bash scripts/bootstrap.sh` to link the loader into
  `${XDG_CONFIG_HOME:-$HOME/.config}/recon-dots/recon.zsh`.
- Bootstrap prints a source line; the user adds it to their existing zsh setup.
- Never overwrite startup files, install shell plugins, or manage personal secrets.
- Run `bash scripts/install-recon-tools.sh` separately for dependencies;
  `--check-only` inspects without installation.
- `GITHUB_TOKEN` is optional and supplied by the caller's environment.
- Dependencies must be available on PATH. The installer links urldedupe into
  `~/.local/bin` rather than relying on an alias.

## Recon workflow

All output is rooted in `$PWD`, never a hardcoded target tree. For example:

```zsh
mkdir -p ~/BugBounty/targets/example.com/recon
cd ~/BugBounty/targets/example.com/recon
subs example.com
hx passive/all_subs.txt
kat live/httpx_simple.txt
url_harvest live/httpx_simple.txt
js_harvest_all
```

- `subs`: `passive/<domain>.txt`, raw sources in `passive/<domain>/`,
  merged `passive/all_subs.txt`.
- `hx`: `live/httpx.txt` and `live/httpx_simple.txt`.
- `kat`: `katana.txt`.
- `url_harvest` / `url_harvest_katana`: single host writes flat in `$PWD`;
  file input writes under `urls/<hostname>/` plus merged `all_urls.txt`.
- `js_harvest`: `js_files.txt`; `js_harvest_all`: per-host results plus
  `js_files_all.txt`.
- `curlall`: see wrapper usage for batch URL fetching.

## Extensions and checks

Add wrappers in `zsh/recon/<name>.zsh`; the loader discovers them automatically.
Use local variables, dependency checks, clear output, and `$PWD`-relative results.
Update the dependency installer and README when adding required tools.
Keep required configuration explicit rather than importing personal shell modules.
Validate Bash scripts with `bash -n`, zsh files with `zsh -n`, and smoke-test
bootstrap and loader changes using a temporary HOME without installing live tools.

## Linux compatibility

Keep Arch and Kali/Debian package mappings working. Wrappers require zsh;
install it for minimal images. Use pipx for Python applications, never
`--break-system-packages`. Package installation must work as a normal user
with sudo or as root without sudo. Check apt behavior with mocked commands
when a real Kali environment is unavailable, and state that validation limit.
