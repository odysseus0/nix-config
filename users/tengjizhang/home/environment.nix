{ ... }:

let
  # Explicitly set to bun's XDG-compliant default
  bunInstallDir = "$HOME/.cache/.bun";
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    GOPATH = "$HOME/go";
    OP_ACCOUNT = "my.1password.com";
    BUN_INSTALL = bunInstallDir;
  };

  # Add bun global bin to PATH (for AI CLI tools installed via update-ai-tools)
  home.sessionPath = [ "${bunInstallDir}/bin" ];
}
