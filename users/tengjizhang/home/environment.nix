{ pkgs, ... }:

let
  # Bun's actual default global install location
  bunInstallDir = "$HOME/.bun";
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

  # Add global bin paths (pnpm for AI CLI tools, bun for qmd)
  home.sessionPath = [ pnpmHome "${bunInstallDir}/bin" ];
}
