# Long-running user jobs on a Mac, one shape for all of them: started at
# login, restarted when they exit, logs private to the user. Labels are
# com.runtime.<name> because home-ops' runtime registry health-checks them
# under those names.
{ config, lib, ... }:
let
  logs = "${config.home.homeDirectory}/Library/Logs";
in
{
  options.services.background = lib.mkOption {
    default = { };
    description = "Programs launchd keeps running in the user's session.";
    type = lib.types.attrsOf (lib.types.submodule {
      options.program = lib.mkOption {
        type = lib.types.str;
        description = "Executable to run, with no arguments.";
      };
    });
  };

  config.launchd.agents = lib.mapAttrs (name: job: {
    enable = true;
    config = {
      Label = "com.runtime.${name}";
      ProgramArguments = [ job.program ];
      RunAtLoad = true;
      KeepAlive = true;
      # A dependency may not be up yet at login (tailscaled, MySQL); retry
      # every 10s.
      ThrottleInterval = 10;
      ProcessType = "Background";
      StandardOutPath = "${logs}/runtime-${name}.log";
      StandardErrorPath = "${logs}/runtime-${name}.error.log";
      Umask = 63; # 0077: logs may contain private operational context.
    };
  }) config.services.background;
}
