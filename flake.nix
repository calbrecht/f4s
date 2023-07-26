{
  description = "Local nixpkgs overlays flake";

  nixConfig = {
    flake-registry = https://github.com/calbrecht/f4s-registry/raw/main/flake-registry.json;
  };

  inputs = {
    emacs.url = flake:f4s-emacs;
    firefox-nightly.url = flake:f4s-firefox-nightly;
    fixups.url = flake:f4s-fixups;
    flake-parts.url = flake:flake-parts;
    global-cursor-theme.url = flake:f4s-global-cursor-theme;
    nixpkgs.url = flake:nixpkgs;
    nodejs.url = flake:f4s-nodejs;
    rust.url = flake:f4s-rust;
    systems.url = github:nix-systems/x86_64-linux;
    wayland.url = github:nix-community/nixpkgs-wayland;
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs.lib) attrVals getAttrs mapAttrs recursiveUpdate;
    overlaysFrom = [
      "fixups"
      "rust"
      "wayland"
      "nodejs"
      "emacs"
      "global-cursor-theme"
      "firefox-nightly"
    ];
  in inputs.flake-parts.lib.mkFlake { inherit inputs; } (top: {
    systems = (import inputs.systems);
    flake.overlays = mapAttrs (n: v:
      v.overlays.${n} or v.overlays.default or v.overlay
    ) (getAttrs overlaysFrom inputs);
    perSystem = { config, system, pkgs, lib, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python2.7-urllib3-1.26.2"
            "python2.7-pyjwt-1.7.1"
          ];
        };
        overlays = attrVals overlaysFrom top.config.flake.overlays;
      };
      legacyPackages = recursiveUpdate pkgs {
        vscode = pkgs.vscode-with-extensions.override {
          vscodeExtensions = with pkgs.vscode-extensions; [ ms-vsliveshare.vsliveshare ];
        };
      };
    };
  });
}
