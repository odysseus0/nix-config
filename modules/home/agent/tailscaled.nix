# agent-net: Tailscale on a box with no systemd and no promise of root.
#
# tailscaled runs in userspace-networking mode under the user's state dir, so
# it never changes the box's routes or resolv.conf, and it works the same with
# or without /dev/net/tun. The only thing on the box that needs the tailnet is
# bd, which reaches Sietch through a local forward (127.0.0.1:<port> to
# Sietch's Dolt over `tailscale nc`).
#
# Nothing supervises these processes. `up` is idempotent: with state left
# from an earlier run the node resumes, and on a wiped home
# `up --auth-key=...` enrolls a new one.
{ config, lib, pkgs, facts, ... }:
let
  state = "${config.xdg.stateHome}/tailscale";
  port = toString facts.sietch.beadsPort;
  tailscale = lib.getExe' pkgs.tailscale "tailscale";
  agent-net = pkgs.writeShellApplication {
    name = "agent-net";
    runtimeInputs = [ pkgs.tailscale pkgs.socat ];
    text = ''
      state=${lib.escapeShellArg state}
      sock="$state/tailscaled.sock"
      ts() { tailscale --socket="$sock" "$@"; }
      alive() { [ -s "$state/$1.pid" ] && kill -0 "$(cat "$state/$1.pid")" 2>/dev/null; }
      start() {
        name=$1; shift
        nohup "$@" >"$state/$name.log" 2>&1 </dev/null &
        echo $! >"$state/$name.pid"
      }

      case "''${1:-}" in
        up)
          shift
          mkdir -p "$state"
          if ! alive tailscaled; then
            start tailscaled tailscaled --tun=userspace-networking \
              --state="$state/tailscaled.state" --socket="$sock" --statedir="$state"
            for _ in $(seq 50); do [ -S "$sock" ] && break; sleep 0.2; done
          fi
          # A running node keeps its settings; `up` is for first enrollment
          # (or re-enrollment after the node was removed from the tailnet).
          ts status --peers=false >/dev/null 2>&1 || ts up "$@"
          alive forward || start forward socat \
            "TCP-LISTEN:${port},bind=127.0.0.1,fork,reuseaddr" \
            "EXEC:${tailscale} --socket=$sock nc ${facts.sietch.host} ${port}"
          ts status --peers=false
          ;;
        down)
          for name in forward tailscaled; do
            if alive "$name"; then kill "$(cat "$state/$name.pid")"; fi
            rm -f "$state/$name.pid"
          done
          ;;
        status)
          ts status
          ;;
        *)
          echo "usage: agent-net up [tailscale up flags, e.g. --auth-key=tskey-...] | down | status" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [ agent-net ];
}
