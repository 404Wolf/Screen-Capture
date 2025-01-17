{
  description = "Collection of screen capturing utilities for Wayland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      # Common runtime dependencies for the scripts
      commonDeps = with pkgs; [
        wl-clipboard
        libnotify
      ];

      # Helper function to create script packages
      mkScript = {
        name,
        runtimeInputs ? [],
      }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = commonDeps ++ runtimeInputs;
          text = builtins.readFile ./scripts/${name}.sh;
        };

      # Define all scripts
      scripts = {
        dump-clipboard = mkScript {
          name = "dump-clipboard";
        };

        partial-screenshot = mkScript {
          name = "partial-screenshot";
          runtimeInputs = with pkgs; [
            slurp
            grim
          ];
        };

        capture-gif = mkScript {
          name = "capture-gif";
          runtimeInputs = with pkgs; [
            ffmpeg
            gifski
            slurp
            wf-recorder
          ];
        };
      };
    in {
      packages =
        scripts
        // {
          default = pkgs.symlinkJoin {
            name = "screenshot-utils";
            paths = builtins.attrValues scripts;
          };
        };

      devShells.default = pkgs.mkShell {
        packages =
          commonDeps
          ++ (with pkgs; [
            ffmpeg
            gifski
            slurp
            grim
            wf-recorder
          ]);
      };
    });
}
