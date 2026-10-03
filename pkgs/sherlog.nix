# Sherlog (`shlog`): full-text search over local agent session transcripts.
# Runs a fork until upstream merges the session-identity fixes
# (catoncat/sherlog#124 and the Codex segment fix): built from
# ~/src/github.com/odysseus0/sherlog (branch `local`) into
# $XDG_DATA_HOME/sherlog/shlog. When a release carries both fixes, pin the
# release archive instead.
{ writeShellScriptBin }:
writeShellScriptBin "shlog" ''
  case "''${XDG_DATA_HOME:-}" in /*) data=$XDG_DATA_HOME ;; *) data=$HOME/.local/share ;; esac
  exec "$data/sherlog/shlog" "$@"
''
