# Source through the real path so the bootstrap symlink works from any directory.
# Keep loader variables local and prevent user aliases from rewriting wrappers.
() {
    setopt localoptions noaliases
    local recon_dir="${(%):-%x}"
    recon_dir="${recon_dir:A:h}/recon"
    local wrapper
    for wrapper in "$recon_dir"/*.zsh(N); do
        source "$wrapper" || return
    done
}
