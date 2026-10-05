# The server's Nix-owned CLI tools, each for a reason of Sietch's own; the
# workstation's set is deliberately absent. Agents run here under herdr and
# the Codex app (the `chatgpt` cask in modules/darwin/server.nix).
{ inputs, pkgs, ... }:

let
  # Same store-owned tier as the MacBook: llm-agents.nix's packages output,
  # served by cache.numtide.com (modules/darwin/base.nix).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  xdg.configFile."ghostty/config".source = ../dotfiles/ghostty;

  home.packages = with pkgs; [
    git             # clone/pull ~/nix-config to rebuild this machine
    git-lfs         # the vault clone's media (global git config names its filter)
    herdr           # agent multiplexer for remote sessions
    llmAgents.codex # codex CLI for agent runs outside the desktop app
    ghostty-bin.terminfo # xterm-ghostty, the TERM SSH sessions from Ghostty arrive with
    ghostty-bin     # the terminal over Screen Sharing, same config as the MacBook
    nerd-fonts.jetbrains-mono # the font that config names
  ];
}
