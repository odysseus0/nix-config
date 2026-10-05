# The weekly, build-gated flake bump (scheduled from home-ops' runtime
# registry, which runs ~/.local/bin/nix-flake-bump). The lock is committed
# only if both Macs still build against it; a bad upstream week reverts
# instead of landing. A green gate then activates the MacBook's home layer,
# which is sudo-free and is where the fast-moving CLI tools live.
{ writeShellScriptBin }:
writeShellScriptBin "nix-flake-bump" ''
  set -uo pipefail
  export PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin

  # launchd hands a job a 256-fd soft limit; `nix flake update` exceeds it
  # writing the nixpkgs packfile and dies with "Too many open files".
  ulimit -n 65536

  cd "$HOME/nix-config" || exit 1
  echo "=== $(date) flake bump ==="

  # A dirty tree means someone is mid-edit; never fight that session.
  if [ -n "$(git status --porcelain)" ]; then
    echo "working tree dirty — skipping"; exit 0
  fi

  git fetch --quiet origin 2>/dev/null
  nix flake update || { echo "update failed"; git checkout -- flake.lock; exit 1; }

  if git diff --quiet --exit-code flake.lock; then
    echo "no input changes"; exit 0
  fi

  echo "--- build gate ---"
  system="$(nix build --no-link --print-out-paths ".#darwinConfigurations.macbook-m4-max.system")" || {
    echo "BUILD FAILED against new inputs — reverting lock"
    git checkout -- flake.lock
    exit 1
  }
  # Sietch shares this lock. Build-only: it activates on its own switch.
  nix build --no-link ".#darwinConfigurations.sietch.system" || {
    echo "SIETCH BUILD FAILED against new inputs — reverting lock"
    git checkout -- flake.lock
    exit 1
  }

  git add flake.lock
  git commit -m "flake.lock: weekly input bump (build-verified)"
  git push || echo "push failed — commit is local"

  echo "--- activating home layer ---"
  if generation="$(nix build --no-link --print-out-paths ".#darwinConfigurations.macbook-m4-max.config.home-manager.users.$(id -un).home.activationPackage")" \
     && "$generation/activate"; then
    echo "home layer activated"
  else
    echo "home activation failed — the commit stands; run 'make home-switch' by hand"
  fi

  # The system layer needs sudo; say when it has drifted.
  if [ "$system" != "$(readlink -f /run/current-system)" ]; then
    echo "system layer changed — run 'make switch' when convenient"
  fi
''
