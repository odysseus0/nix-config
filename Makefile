# Build and activate this Mac's flake output.

# The flake output for THIS machine, chosen by LocalHostName so a bare `make`
# on Sietch can never activate the workstation profile there. Override with
# `make NIXNAME=<output> ...` (e.g. to build Sietch's output on the MacBook).
NIXNAME ?= $(if $(filter Sietch,$(shell /usr/sbin/scutil --get LocalHostName 2>/dev/null)),sietch,macbook-m4-max)
NIXSYSTEM = .\#darwinConfigurations.${NIXNAME}.system
HOME_ACTIVATION = .\#darwinConfigurations.${NIXNAME}.config.home-manager.users.${USER}.home.activationPackage
# Sietch has no GitHub token for the private home-ops input; it reads its own
# clone (~/home-ops, pulled with a read-only deploy key) instead.
OVERRIDE = $(if $(filter sietch,${NIXNAME}),--override-input home-ops git+file://${HOME}/home-ops,)
NIXBUILD = nix build "${NIXSYSTEM}" ${OVERRIDE}
HOMEBUILD = nix build --no-link "${HOME_ACTIVATION}" ${OVERRIDE}

.PHONY: help home-switch home-build switch system-switch test build clean update brew-upgrade dry-run update-nixpkgs

# Activate only the existing Home Manager subconfiguration. This evaluates the
# exact module embedded in nix-darwin, so there is no second profile or source
# of truth, and routine user-level changes remain remotely operable without
# administrator authentication.
home-switch:
	@generation="$$(nix build --no-link --print-out-paths "${HOME_ACTIVATION}" ${OVERRIDE})"; \
	"$$generation/activate"

# Build only the user activation package (no activation, no result symlink).
home-build:
	${HOMEBUILD}

# Full-system activation remains an explicit supervised boundary. Keep the old
# target as a compatibility alias for muscle memory and external instructions.
switch: system-switch

system-switch:
	sudo darwin-rebuild switch --flake ".#${NIXNAME}" ${OVERRIDE}

# Test the configuration without switching
test:
	${NIXBUILD}
	sudo ./result/sw/bin/darwin-rebuild test --flake ".#${NIXNAME}"

# Build only (no activation)
build:
	${NIXBUILD}

# Show what needs to be built/downloaded without building
dry-run:
	${NIXBUILD} --dry-run 2>&1 | grep -E "will be (built|fetched)" || echo "Everything up to date"

# Clean up build artifacts
clean:
	rm -f result

# Update all flake inputs (use sparingly — prefer selective updates)
update:
	nix flake update

# Update only nixpkgs-unstable (most common, least disruptive)
update-nixpkgs:
	nix flake update nixpkgs

# Show help
help:
	@echo "Available targets:"
	@echo "  home-switch         - Activate user configuration without sudo (default)"
	@echo "  home-build          - Build user configuration without activation"
	@echo "  system-switch       - Build and activate the full system (requires sudo)"
	@echo "  switch              - Compatibility alias for system-switch"
	@echo "  test                - Build and test configuration without activation"
	@echo "  build               - Build configuration only"
	@echo "  dry-run             - Show what needs to be built/downloaded"
	@echo "  update              - Update ALL flake inputs (use sparingly)"
	@echo "  update-nixpkgs      - Update only nixpkgs-unstable"
	@echo "  brew-upgrade        - Upgrade Homebrew formulae/casks (explicit, out of switch path)"
	@echo "  clean               - Remove build artifacts"
	@echo "  help                - Show this help message"

# Routine configuration changes are user-scoped; make the remotely operable
# path the default. Use system-switch when a change genuinely affects macOS,
# nix-daemon, Homebrew, or another root-owned surface.
.DEFAULT_GOAL := home-switch

# Homebrew upgrades stay out of the switch path: a switch materializes the
# declared set, and upgrading is a separate, network-dependent step.
brew-upgrade:
	brew update && brew upgrade
