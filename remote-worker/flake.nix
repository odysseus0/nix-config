{
  description = "Self-contained x86_64-linux remote-worker toolchain";

  nixConfig = {
    extra-substituters = "https://nix-community.cachix.org https://cache.numtide.com";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # beads (bd). No nixpkgs.follows — same cache-hit reason as the parent flake.
    llm-agents.url = "github:numtide/llm-agents.nix/8fa7a843ec7e8017ba9313f7b57dba8fd803b98d";
  };

  outputs = { self, nixpkgs, llm-agents }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        name = "remote-worker";
        packages = with pkgs; [
          git
          gh
          bun
          nodejs
          dolt
          cloudflared
          syncthing
          tmux
          rsync
          rclone
          jq
          ripgrep
        ] ++ [
          llm-agents.packages.${system}.beads
        ];
      };
    };
}
