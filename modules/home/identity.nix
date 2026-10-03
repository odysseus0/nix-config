# The one impurity on an agent box: its account. Vendors disagree on the user
# and home (root in /root on one, box in /home/box on another), so the
# bootstrap app evaluates with --impure and this module reads both from the
# environment. A pure evaluation reads nothing, and the caller must set them.
{ lib, ... }:
let
  user = builtins.getEnv "USER";
  home = builtins.getEnv "HOME";
in
{
  home.username = lib.mkIf (user != "") user;
  home.homeDirectory = lib.mkIf (home != "") home;
}
