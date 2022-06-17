{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    rec {
      # Only run CI on Linux
      herculesCI.ciSystems = [ "x86_64-linux" "aarch64-linux" ];

      # Expose template
      templates = {
        starter = {
          path = ./templates/starter;
          description = "A starter template for Nixago";
        };
      };

      defaultTemplate = templates.starter;

    } // (flake-utils.lib.eachDefaultSystem
      (system:
        let
          version = "2.1.0"; # x-release-please-version

          engines = import ./engines { inherit pkgs lib; };
          lib = (import ./lib { inherit pkgs lib engines; });
          plugins = import ./plugins { inherit pkgs lib engines; };

          # Setup pkgs
          pkgs = import nixpkgs {
            inherit system;
          };

          # Import test runner
          runTests = import ./tests/common.nix { inherit pkgs engines; };

          # Helper function for aggregating development tools
          mkTools = tools: (builtins.listToAttrs
            (
              builtins.map
                (tool:
                  pkgs.lib.nameValuePair (pkgs.lib.getName tool) { pkg = tool; exe = pkgs.lib.getExe tool; })
                tools
            ) // { all = tools; });

          # Define development tools
          tools = mkTools [
            pkgs.conform
            pkgs.cue
            pkgs.just
            pkgs.lefthook
            pkgs.mdbook
            pkgs.mdbook-mermaid
            pkgs.nixpkgs-fmt
            pkgs.nodePackages.prettier
            pkgs.typos
          ];

          # Define development tool configuration (with Nixago!)
          configs = import ./.config.nix { inherit plugins tools; };
        in
        rec {
          # Expose external API
          inherit engines lib plugins;

          # Add local tests
          checks = import ./tests { inherit pkgs lib engines runTests; };

          # Configure local development shell
          devShells = {
            default = pkgs.mkShell {
              shellHook = (lib.makeAll configs).shellHook;
              packages = tools.all;
            };
          };
        }
      ));
}
