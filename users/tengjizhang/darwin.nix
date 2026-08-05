{ pkgs, ... }:

{
  # Homebrew moved to the user level (2026-08-04): the manifest lives in
  # home/brew.nix (rendered to ~/.config/homebrew/Brewfile) and is applied by
  # the sudo-free `make brew-apply` clock. Homebrew never needed root, and
  # keeping it in system activation made every GUI-app change cost a sudo
  # prompt — hostile to remote (SSH) operation. darwin.nix now carries only
  # genuinely system-scoped surfaces.

  # Ensure the login shell for the primary user is the nix-managed path.
  # Darwin intentionally does NOT change shells for existing accounts via users.users.*,
  # so we do it declaratively here during activation. Safe and idempotent.
  system.activationScripts.fixUserShell.text = ''
    set -e
    USERNAME="tengjizhang"
    DESIRED="/run/current-system/sw/bin/fish"

    # Read current login shell from Directory Services (returns: "UserShell: <path>")
    CURRENT=$(/usr/bin/dscl . -read /Users/"$USERNAME" UserShell 2>/dev/null | /usr/bin/awk '{print $2}')

    if [ "$CURRENT" != "$DESIRED" ]; then
      echo "Updating login shell for $USERNAME: ${CURRENT:-<unset>} -> $DESIRED"
      # chsh requires the shell to be present in /etc/shells; nix-darwin's environment.shells ensures this.
      /usr/bin/chsh -s "$DESIRED" "$USERNAME" \
        || /usr/bin/dscl . -create "/Users/$USERNAME" UserShell "$DESIRED"
    fi
  '';

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.tengjizhang = {
    home = "/Users/tengjizhang";
    shell = pkgs.fish;
  };

  # Touch ID for sudo - no more password prompts!
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;  # Enables Touch ID in tmux/screen sessions
  };

  # Required for some settings like homebrew to know what user to apply to.
  system.primaryUser = "tengjizhang";
}
