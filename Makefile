# Nix-darwin configuration management
# Based on Mitchell Hashimoto's approach

NIXNAME = macbook-m4-max
NIXSYSTEM = .\#darwinConfigurations.${NIXNAME}.system
HOME_ACTIVATION = .\#darwinConfigurations.${NIXNAME}.config.home-manager.users.${USER}.home.activationPackage
# --impure and NIXPKGS_ALLOW_UNFREE were redundant with the declarative
# `nixpkgs.config.allowUnfree = true` (machines/macbook-m4-max.nix +
# lib/mksystem.nix) — removed 2026-07-20 (audit F5) after verifying a pure
# `nix build .#darwinConfigurations.macbook-m4-max.system --dry-run`
# evaluates cleanly with neither flag nor env var set.
NIXBUILD = nix build "${NIXSYSTEM}"
HOMEBUILD = nix build --no-link "${HOME_ACTIVATION}"

.PHONY: help home-switch home-build switch system-switch test build clean update update-tools brew-upgrade update-commit update-commit-push dry-run update-nixpkgs

# Activate only the existing Home Manager subconfiguration. This evaluates the
# exact module embedded in nix-darwin, so there is no second profile or source
# of truth, and routine user-level changes remain remotely operable without
# administrator authentication.
home-switch:
	@generation="$$(nix build --no-link --print-out-paths "${HOME_ACTIVATION}")"; \
	"$$generation/activate"

# Build only the user activation package (no activation, no result symlink).
home-build:
	${HOMEBUILD}

# Full-system activation remains an explicit supervised boundary. Keep the old
# target as a compatibility alias for muscle memory and external instructions.
switch: system-switch

system-switch:
	sudo darwin-rebuild switch --flake ".#${NIXNAME}"

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

# The other clock: reconcile MANIFEST-OWNED tools (currently just uv) against
# their manifest (users/tengjizhang/home/uv-tools-manifest.nix). Network-
# dependent, explicit, never run from `switch`/activation — that's the whole
# point of the two-clock split (see README §The two clocks). VENDOR-OWNED
# tools (Vite+) are not touched here; they update themselves.
# Built via `nix build` rather than assuming uv-tools-reconcile is on PATH:
# that works before the first switch and can't be shadowed by a stale PATH
# entry — don't "simplify" this to a bare command invocation.
update-tools:
	@bin="$$(nix build --no-link --print-out-paths '.#darwinConfigurations.${NIXNAME}.pkgs.uv-tools-reconcile')/bin/uv-tools-reconcile"; \
	"$$bin"
	@if command -v executor-update >/dev/null 2>&1; then executor-update; fi  # home-ops executor module's clock

# Update flake inputs and auto-commit
update-commit: update
	@if git diff --quiet --exit-code flake.lock; then \
		echo "No changes to commit"; \
	else \
		echo "Committing flake.lock update..."; \
		git add flake.lock; \
		git commit -m "Update flake.lock: dependency version bumps"; \
	fi

# Update, commit, and push to remote
update-commit-push: update-commit
	@if [ -n "$$(git log origin/main..HEAD 2>/dev/null)" ]; then \
		echo "Pushing to remote..."; \
		git push; \
	else \
		echo "No new commits to push"; \
	fi

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
	@echo "  update-tools        - Reconcile MANIFEST-OWNED tools (uv) to their manifest"
	@echo "  brew-upgrade        - Upgrade Homebrew formulae/casks (explicit, out of switch path)"
	@echo "  update-commit       - Update flake inputs and auto-commit changes"
	@echo "  update-commit-push  - Update, commit, and push to remote"
	@echo "  clean               - Remove build artifacts"
	@echo "  help                - Show this help message"

# Routine configuration changes are user-scoped; make the remotely operable
# path the default. Use system-switch when a change genuinely affects macOS,
# nix-daemon, Homebrew, or another root-owned surface.
.DEFAULT_GOAL := home-switch

# Explicit Homebrew upgrade — deliberately OUT of the switch path (2026-07-20
# ruling: switch materializes declarations; upgrades are a separate, explicit,
# network-dependent step).
brew-upgrade:
	brew update && brew upgrade
