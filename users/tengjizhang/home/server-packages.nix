# Store-owned CLI set for the server role. Each entry has a Sietch-specific
# reason; workstation tooling (home/packages.nix) is deliberately absent.
{ pkgs, ... }: {
  home.packages = with pkgs; [
    git     # clone/pull ~/nix-config to rebuild this machine
    herdr   # agent multiplexer for remote sessions (installed on Sietch 2026-09-09)

    # Runtime dependencies of the shared shell config (shell.nix, config.fish):
    # the `ls`/`ll` aliases, fzf.fish and its preview/diff commands.
    eza
    bat
    fzf
    fd
    delta
  ];
}
