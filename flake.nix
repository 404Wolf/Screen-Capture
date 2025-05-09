{
  description = "Unified screen capturing utility for Wayland";

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
      deps = with pkgs; [
        wl-clipboard
        slurp
        ffmpeg
        gifski
        gifsicle
        slurp
        wf-recorder
        grim
        wf-recorder
      ];
    in {
      packages = rec {
        default = screenCapture;
        screenCapture = pkgs.writeShellApplication {
          name = "screen-capture";
          text = "${builtins.readFile ./main.sh}";
          bashOptions = []; # set in the script
          runtimeInputs = deps;
        };
      };

      devShells.default = pkgs.mkShell {
        packages = deps;
      };
    });
}
