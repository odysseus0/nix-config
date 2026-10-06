# Build and activate this Mac's flake output. `make help` lists the targets.

# The output for this machine, chosen by LocalHostName so a bare `make` on
# Sietch can never activate the workstation there. Override with
# `make NIXNAME=<output> ...`, e.g. to build Sietch's output on the MacBook.
NIXNAME ?= $(if $(filter Sietch,$(shell /usr/sbin/scutil --get LocalHostName 2>/dev/null)),sietch,macbook-m4-max)
NIXSYSTEM = .\#darwinConfigurations.${NIXNAME}.system
HOME_ACTIVATION = .\#darwinConfigurations.${NIXNAME}.config.home-manager.users.${USER}.home.activationPackage
# Sietch has no GitHub token for the private home-ops input; it reads its own
# clone (~/home-ops, pulled with a read-only deploy key) instead.
OVERRIDE = $(if $(filter sietch,${NIXNAME}),--override-input home-ops git+file://${HOME}/home-ops,)

.DEFAULT_GOAL := home-switch
.PHONY: home-switch home-build switch build dry-run update update-nixpkgs brew-upgrade transcription-setup help

# The home layer is the home-manager configuration embedded in the darwin
# output, so activating it alone needs no second source of truth, and no sudo.
home-switch: ## Activate the home layer only (no sudo); the default
	@generation="$$(nix build --no-link --print-out-paths "${HOME_ACTIVATION}" ${OVERRIDE})"; \
	"$$generation/activate"

home-build: ## Build the home layer without activating it
	nix build --no-link "${HOME_ACTIVATION}" ${OVERRIDE}

switch: ## Build and activate the whole system (sudo)
	sudo darwin-rebuild switch --flake ".#${NIXNAME}" ${OVERRIDE}

build: ## Build the whole system without activating it
	nix build "${NIXSYSTEM}" ${OVERRIDE}

dry-run: ## Show what a build would fetch or build
	nix build "${NIXSYSTEM}" ${OVERRIDE} --dry-run 2>&1 | grep -E "will be (built|fetched)" || echo "Everything up to date"

update: ## Update every flake input
	nix flake update

update-nixpkgs: ## Update nixpkgs only
	nix flake update nixpkgs

# A switch only installs what is declared; upgrading is this separate,
# networked step.
brew-upgrade: ## Upgrade Homebrew apps
	brew update && brew upgrade

# Native Swift compilation and model downloads stay out of activation;
# see tools/transcription.
transcription-setup: ## Build the pinned native transcription command (MacBook)
	@bin="$$(nix build --no-link --print-out-paths '.#darwinConfigurations.${NIXNAME}.pkgs.local-transcription' ${OVERRIDE})/bin/transcription-setup"; \
	"$$bin"

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  %-15s %s\n", $$1, $$2 }'
