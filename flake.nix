{
  description = "Collection of screen capturing scripts";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages = rec {
          default = pkgs.stdenv.mkDerivation {
            name = "screenshot-utils";
            dontUnpack = true;
            installPhase = ''
              dest=$out/bin
              mkdir -p $dest
              cp ${dump-clipboard}/bin/*.sh $dest
              cp ${partial-screenshot}/bin/*.sh $dest
              cp ${capture-gif}/bin/*.sh $dest
            '';
          };
          dump-clipboard = pkgs.writeShellScriptBin "dump-clipboard.sh" ''
            wl_paste=${pkgs.wl-clipboard}/bin/wl-paste;
            notify=${pkgs.libnotify}/bin/notify-send;
            ${builtins.readFile ./scripts/dump-clipboard.sh}
          '';
          # Set SAVE
          partial-screenshot = pkgs.writeShellScriptBin "partial-screenshot.sh" ''
            slurp=${pkgs.slurp}/bin/slurp;
            grim=${pkgs.grim}/bin/grim;
            wl_copy=${pkgs.wl-clipboard}/bin/wl-copy;
            notify=${pkgs.libnotify}/bin/notify-send;
            ${builtins.readFile ./scripts/partial-screenshot.sh}
          '';
          # set FPS QUALITY SAVE
          capture-gif = pkgs.writeShellScriptBin "capture-gif.sh" ''
            ffmpeg=${pkgs.ffmpeg}/bin/ffmpeg;
            gifski=${pkgs.gifski}/bin/gifski;
            wl_copy=${pkgs.wl-clipboard}/bin/wl-copy;
            slurp=${pkgs.slurp}/bin/slurp;
            wf_recorder=${pkgs.wf-recorder}/bin/wf-recorder;
            notify=${pkgs.libnotify}/bin/notify-send;
            ${builtins.readFile ./scripts/capture-gif.sh}
          '';
        };
      }
    );
}
