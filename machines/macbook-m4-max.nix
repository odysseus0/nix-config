{ pkgs, ... }: {
  imports = [ ./darwin-common.nix ];

  # Server-readiness note (this is the darwin machine; a NixOS home server is
  # planned as a second machine under machines/). When that machine.nix lands,
  # give it `programs.nix-ld.enable = true;` — the vendor-owned tier (Vite+,
  # grok, and anything else with its own curl-installer or self-updater)
  # ships prebuilt Linux binaries that expect an FHS-ish dynamic linker;
  # nix-ld is the standard fix on NixOS. Not needed on Darwin.

  environment.systemPackages = with pkgs; [
    # Basic system utilities (Mitchell's pattern)
    cachix
    mosh  # system-level so non-interactive SSH can find mosh-server
    tmux  # better than zellij for iOS terminals (scroll mode works with touch)
  ];
}
