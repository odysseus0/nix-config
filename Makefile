# Nix-darwin configuration management
# Based on Mitchell Hashimoto's approach

NIXNAME = macbook-m4-max
NIXPKGS_ALLOW_UNFREE = 1

.PHONY: help switch test build clean update update-commit update-commit-push

# Default target - full system switch
switch:
	sudo NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --flake ".#${NIXNAME}"

# Test the configuration without switching
test:
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure ".#darwinConfigurations.${NIXNAME}.system"
	sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild test --impure --flake ".#${NIXNAME}"

# Build only (no activation)
build:
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure ".#darwinConfigurations.${NIXNAME}.system"

# Clean up build artifacts
clean:
	rm -f result

# Update flake inputs
update:
	nix flake update

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
	@echo "  update              - Update flake inputs"
	@echo "  update-commit       - Update flake inputs and auto-commit changes"
	@echo "  update-commit-push  - Update, commit, and push to remote"
	@echo "  clean               - Remove build artifacts"
	@echo "  help                - Show this help message"

# Make 'switch' the default target
.DEFAULT_GOAL := switch