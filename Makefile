# Nix-darwin configuration management
# Based on Mitchell Hashimoto's approach

NIXNAME = macbook-m4-max
NIXPKGS_ALLOW_UNFREE = 1

.PHONY: help switch test build clean

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

# Show help
help:
	@echo "Available targets:"
	@echo "  switch  - Build and activate the system configuration (default)"
	@echo "  test    - Build and test configuration without activation"  
	@echo "  build   - Build configuration only"
	@echo "  update  - Update flake inputs"
	@echo "  clean   - Remove build artifacts"
	@echo "  help    - Show this help message"

# Make 'switch' the default target
.DEFAULT_GOAL := switch