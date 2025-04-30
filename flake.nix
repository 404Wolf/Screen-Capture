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
      ];

      # Define all scripts
      scripts = {
        capture-image = pkgs.writeShellApplication {
          name = "capture-image";
          runtimeInputs =
            commonDeps
            ++ (with pkgs; [
              slurp
              grim
              python3
            ]);
          text = ''
            exec ${pkgs.python3}/bin/python3 ${./scripts/capture-image.py}
          '';
        };

        capture-gif = pkgs.writeShellApplication {
          name = "capture-gif";
          runtimeInputs =
            commonDeps
            ++ (with pkgs; [
              ffmpeg
              gifski
              gifsicle
              slurp
              wf-recorder
              python3
            ]);
          text = ''
            exec ${pkgs.python3}/bin/python3 ${./scripts/capture-gif.py}
          '';
        };

        capture-video = pkgs.writeShellApplication {
          name = "capture-video";
          runtimeInputs =
            commonDeps
            ++ (with pkgs; [
              slurp
              wf-recorder
              python3
            ]);
          text = ''
            exec ${pkgs.python3}/bin/python3 ${./scripts/capture-video.py}
          '';
        };
      };
    in {
      packages =
        scripts
        // {
          default = pkgs.symlinkJoin {
            name = "capture-utils";
            paths = builtins.attrValues scripts;
          };
        };

      devShells.default = pkgs.mkShell {
        packages =
          commonDeps
          ++ (with pkgs; [
            ffmpeg
            gifski
            gifsicle
            slurp
            grim
            wf-recorder
            python3
            pyright
          ]);
      };
    });
}
