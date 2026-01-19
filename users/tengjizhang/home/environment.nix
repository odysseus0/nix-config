{ pkgs, ... }:

let
  # Bun global install location (tools already installed here)
  bunInstallDir = "$HOME/.cache/.bun";
  # pnpm global directory (macOS default)
  pnpmHome = if pkgs.stdenv.isDarwin then "$HOME/Library/pnpm" else "$HOME/.local/share/pnpm";
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    GOPATH = "$HOME/go";
    OP_ACCOUNT = "my.1password.com";
    BUN_INSTALL = bunInstallDir;
    PNPM_HOME = pnpmHome;
  };

  # Add global bin paths (pnpm for AI CLI tools, bun globals)
  # Note: ~/.cache/.bun has older installs (claude, codex, etc.), ~/.bun has newer (qmd)
  home.sessionPath = [ pnpmHome "${bunInstallDir}/bin" "$HOME/.bun/bin" ];
}
