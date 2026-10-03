# Store-owned CLI set for the server role. Each entry has a Sietch-specific
# reason; workstation tooling (home/packages.nix) is deliberately absent.
# Sietch is an agent host (remote-execution node): agents run here under
# herdr and the Codex app (declared as the `chatgpt` cask in darwin-server.nix).
{ inputs, pkgs, ... }:

let
  # Same store-owned tier as the MacBook: llm-agents.nix's packages output,
  # served by cache.numtide.com (machines/darwin-common.nix).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  xdg.configFile."ghostty/config".source = ../ghostty;

  home.packages = with pkgs; [
    git             # clone/pull ~/nix-config to rebuild this machine
    git-lfs         # the vault clone's media (global git config names its filter)
    herdr           # agent multiplexer for remote sessions
    llmAgents.codex # codex CLI for agent runs outside the desktop app
    ghostty-bin.terminfo # xterm-ghostty, the TERM George's SSH sessions arrive with
    ghostty-bin     # George's terminal over Screen Sharing, same config as the MacBook
    nerd-fonts.jetbrains-mono # the font that config names

    # Runtime dependencies of the shared shell config (shell.nix, config.fish):
    # the `ls`/`ll` aliases, fzf.fish and its preview/diff commands.
    eza
    bat
    fzf
    fd
    delta
  ];
}
