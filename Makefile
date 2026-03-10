# Nix-darwin configuration management
# Based on Mitchell Hashimoto's approach

NIXNAME = macbook-m4-max
NIXPKGS_ALLOW_UNFREE = 1
NIXBUILD = NIXPKGS_ALLOW_UNFREE=1 nix build --impure ".#darwinConfigurations.${NIXNAME}.system"

.PHONY: help switch test build clean update update-commit update-commit-push dry-run

# Default target - full system switch
switch:
	sudo NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --flake ".#${NIXNAME}"

# Test the configuration without switching
test:
	${NIXBUILD}
	sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild test --impure --flake ".#${NIXNAME}"

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

# Update only llm-agents (AI tools from numtide)
update-llm:
	nix flake update llm-agents

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
	@echo "  switch              - Build and activate the system configuration (default)"
	@echo "  test                - Build and test configuration without activation"
	@echo "  build               - Build configuration only"
	@echo "  dry-run             - Show what needs to be built/downloaded"
	@echo "  update              - Update ALL flake inputs (use sparingly)"
	@echo "  update-nixpkgs      - Update only nixpkgs-unstable"
	@echo "  update-llm          - Update only llm-agents (AI tools)"
	@echo "  update-commit       - Update flake inputs and auto-commit changes"
	@echo "  update-commit-push  - Update, commit, and push to remote"
	@echo "  clean               - Remove build artifacts"
	@echo "  help                - Show this help message"

# Make 'switch' the default target
.DEFAULT_GOAL := switch
