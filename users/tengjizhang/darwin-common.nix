# Account layer shared by every Darwin role (workstation and server): the
# existing macOS account, its Nix-managed login shell, and the primary user
# that user-scoped nix-darwin options (homebrew, power, defaults) apply to.
{ pkgs, ... }:

{
  # Ensure the login shell for the primary user is the nix-managed path.
  # Darwin intentionally does NOT change shells for existing accounts via users.users.*,
  # so we do it declaratively here during activation. Safe and idempotent.
  # It must be postActivation: nix-darwin runs only its fixed activation-script
  # names, so a custom-named script never runs.
  system.activationScripts.postActivation.text = ''
    USERNAME="tengjizhang"
    DESIRED="/run/current-system/sw/bin/fish"

    # Read current login shell from Directory Services (returns: "UserShell: <path>")
    CURRENT=$(/usr/bin/dscl . -read /Users/"$USERNAME" UserShell 2>/dev/null | /usr/bin/awk '{print $2}')

    if [ "$CURRENT" != "$DESIRED" ]; then
      echo "Updating login shell for $USERNAME: ''${CURRENT:-<unset>} -> $DESIRED"
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

  # Required for some settings like homebrew to know what user to apply to.
  system.primaryUser = "tengjizhang";
}
